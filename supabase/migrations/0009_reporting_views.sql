create view public.v_room_status with (security_invoker = true) as
select
  r.id as room_id,
  r.hotel_id,
  r.number,
  r.name as room_name,
  rc.name as category_name,
  f.name as floor_name,
  r.operational_status,
  r.housekeeping_status,
  r.is_active,
  case
    when exists (
      select 1
      from public.reservation_room_assignments rra
      join public.reservations res on res.id = rra.reservation_id
      where rra.room_id = r.id
        and res.status = 'checked_in'
        and rra.check_in <= timezone('Africa/Lagos', now())::date
        and rra.check_out > timezone('Africa/Lagos', now())::date
    ) then true else false
  end as is_occupied,
  case
    when r.is_active
      and r.operational_status = 'available'
      and r.housekeeping_status = 'clean'
      and not exists (
        select 1
        from public.reservation_room_assignments rra
        join public.reservations res on res.id = rra.reservation_id
        where rra.room_id = r.id
          and res.status in ('confirmed', 'checked_in')
          and rra.check_in <= timezone('Africa/Lagos', now())::date
          and rra.check_out > timezone('Africa/Lagos', now())::date
      ) then true else false
  end as is_sellable
from public.rooms r
join public.room_categories rc on rc.id = r.category_id
left join public.floors f on f.id = r.floor_id;

create view public.v_folio_summary with (security_invoker = true) as
with bill_totals as (
  select
    bi.folio_id,
    sum(case when not bi.is_void then bi.total else 0 end) as charges,
    sum(case when not bi.is_void then bi.tax_amount else 0 end) as taxes,
    sum(case when not bi.is_void then bi.discount else 0 end) as discounts
  from public.bill_items bi
  group by bi.folio_id
),
department_charges as (
  select
    bi.folio_id,
    coalesce(d.name, 'Unassigned') as department,
    sum(case when not bi.is_void then bi.total else 0 end) as amount
  from public.bill_items bi
  join public.bills b on b.id = bi.bill_id
  left join public.departments d on d.id = b.department_id
  group by 1, 2
),
department_totals as (
  select
    folio_id,
    jsonb_object_agg(department, amount) as charges_by_department
  from department_charges
  group by folio_id
),
adjustment_totals as (
  select
    fa.folio_id,
    sum(case
      when fa.type = 'charge' then fa.amount
      else -fa.amount
    end) as adjustments
  from public.financial_adjustments fa
  where fa.status = 'posted'
  group by fa.folio_id
),
payment_totals as (
  select
    p.folio_id,
    sum(case when p.status = 'successful' then p.amount else 0 end) as payments
  from public.payments p
  group by p.folio_id
),
refund_totals as (
  select
    rf.folio_id,
    sum(case when rf.status = 'completed' then rf.amount else 0 end) as refunds
  from public.refunds rf
  group by rf.folio_id
)
select
  f.id as folio_id,
  f.folio_number,
  f.hotel_id,
  f.reservation_id,
  f.guest_id,
  f.type,
  f.status,
  f.currency,
  f.opened_at,
  f.closed_at,
  coalesce(dt.charges_by_department, '{}'::jsonb) as charges_by_department,
  coalesce(bt.charges, 0) as charges,
  coalesce(bt.taxes, 0) as taxes,
  coalesce(bt.discounts, 0) as discounts,
  coalesce(adj.adjustments, 0) as adjustments,
  coalesce(pt.payments, 0) as payments,
  coalesce(rt.refunds, 0) as refunds,
  coalesce(bt.charges, 0) + coalesce(adj.adjustments, 0) - coalesce(pt.payments, 0) + coalesce(rt.refunds, 0) as balance
from public.folios f
left join bill_totals bt on bt.folio_id = f.id
left join department_totals dt on dt.folio_id = f.id
left join adjustment_totals adj on adj.folio_id = f.id
left join payment_totals pt on pt.folio_id = f.id
left join refund_totals rt on rt.folio_id = f.id;

create view public.v_reservation_financials with (security_invoker = true) as
with payment_totals as (
  select
    p.reservation_id,
    sum(case when p.status = 'successful' then p.amount else 0 end) as verified_payments
  from public.payments p
  where p.reservation_id is not null
  group by p.reservation_id
),
refund_totals as (
  select
    p.reservation_id,
    sum(case when rf.status = 'completed' then rf.amount else 0 end) as refunds
  from public.refunds rf
  join public.payments p on p.id = rf.payment_id
  where p.reservation_id is not null
  group by p.reservation_id
)
select
  r.id as reservation_id,
  r.hotel_id,
  r.reference,
  r.guest_id,
  r.status,
  r.currency,
  r.accommodation_total,
  coalesce(pt.verified_payments, 0) as verified_payments,
  coalesce(rt.refunds, 0) as refunds,
  r.accommodation_total - coalesce(pt.verified_payments, 0) + coalesce(rt.refunds, 0) as balance,
  case
    when coalesce(rt.refunds, 0) > 0 then 'refunded'
    when coalesce(pt.verified_payments, 0) >= r.accommodation_total and r.accommodation_total > 0 then 'paid'
    when coalesce(pt.verified_payments, 0) > 0 then 'partially_paid'
    else 'unpaid'
  end as computed_payment_status
from public.reservations r
left join payment_totals pt on pt.reservation_id = r.id
left join refund_totals rt on rt.reservation_id = r.id;

create view public.v_daily_occupancy with (security_invoker = true) as
with bounds as (
  select
    min(check_in) as start_date,
    max(check_out - interval '1 day')::date as end_date
  from public.reservations
  where status not in ('cancelled', 'expired')
),
dates as (
  select gs::date as stay_date
  from bounds b
  cross join lateral generate_series(b.start_date::timestamp, b.end_date::timestamp, interval '1 day') gs
  where b.start_date is not null and b.end_date is not null
),
hotel_dates as (
  select h.id as hotel_id, d.stay_date
  from public.hotels h
  cross join dates d
),
sold as (
  select
    r.hotel_id,
    d.stay_date,
    count(distinct (rra.reservation_id, rra.room_id)) as sold_room_nights
  from dates d
  join public.reservations r
    on r.check_in <= d.stay_date
    and r.check_out > d.stay_date
    and r.status not in ('cancelled', 'expired')
  join public.reservation_room_assignments rra on rra.reservation_id = r.id
  group by 1, 2
),
sellable as (
  select
    rm.hotel_id,
    d.stay_date,
    count(*) as sellable_room_nights
  from dates d
  join public.rooms rm
    on rm.is_active
    and rm.operational_status = 'available'
    and not exists (
      select 1
      from public.room_maintenance m
      where m.room_id = rm.id
        and m.started_at is not null
        and m.started_at::date <= d.stay_date
        and (m.resolved_at is null or m.resolved_at::date > d.stay_date)
    )
  group by 1, 2
)
select
  hd.hotel_id,
  hd.stay_date,
  coalesce(s.sold_room_nights, 0) as sold_room_nights,
  coalesce(se.sellable_room_nights, 0) as sellable_room_nights,
  case
    when coalesce(se.sellable_room_nights, 0) = 0 then null
    else coalesce(s.sold_room_nights, 0)::numeric / se.sellable_room_nights
  end as occupancy_rate
from hotel_dates hd
left join sold s on s.hotel_id = hd.hotel_id and s.stay_date = hd.stay_date
left join sellable se on se.hotel_id = hd.hotel_id and se.stay_date = hd.stay_date;

create view public.v_daily_revenue with (security_invoker = true) as
select
  t.hotel_id,
  t.posted_at::date as revenue_date,
  l.department_id,
  a.name as account_name,
  case when a.name ilike '%tax%' then 'tax' else 'revenue' end as category,
  sum(coalesce(l.debit, 0) - coalesce(l.credit, 0)) as amount
from public.financial_transaction_lines l
join public.financial_transactions t on t.id = l.financial_transaction_id
join public.financial_accounts a on a.id = l.account_id
where t.status = 'posted'
  and a.type in ('revenue', 'expense')
group by 1, 2, 3, 4, 5;

create view public.v_daily_collections with (security_invoker = true) as
select
  p.hotel_id,
  p.paid_at::date as collection_date,
  p.provider,
  p.verified_by,
  count(*) as payment_count,
  sum(p.amount) as total_collected
from public.payments p
where p.status = 'successful' and p.paid_at is not null
group by 1, 2, 3, 4;

create view public.v_outstanding_balances with (security_invoker = true) as
select
  fs.*,
  case
    when now() - f.opened_at <= interval '30 days' then '0-30'
    when now() - f.opened_at <= interval '60 days' then '31-60'
    when now() - f.opened_at <= interval '90 days' then '61-90'
    else '90+'
  end as ageing_bucket
from public.v_folio_summary fs
join public.folios f on f.id = fs.folio_id
where fs.balance > 0
  and f.status in ('open', 'closed_with_balance');

create view public.v_low_stock with (security_invoker = true) as
select
  i.id as inventory_item_id,
  i.hotel_id,
  i.sku,
  i.name,
  i.category_id,
  ic.name as category_name,
  ic.department_id,
  i.current_stock,
  i.reorder_level,
  i.base_unit,
  greatest(i.reorder_level * 2 - i.current_stock, 0) as suggested_reorder_quantity
from public.inventory_items i
join public.inventory_categories ic on ic.id = i.category_id
where i.is_active and i.current_stock <= i.reorder_level;

create view public.v_inventory_valuation with (security_invoker = true) as
select
  i.hotel_id,
  i.category_id,
  ic.name as category_name,
  ic.department_id,
  i.currency,
  sum(i.current_stock * i.unit_cost) as valuation
from public.inventory_items i
join public.inventory_categories ic on ic.id = i.category_id
where i.is_active
group by 1, 2, 3, 4, 5;

create view public.v_department_revenue with (security_invoker = true) as
select
  hotel_id,
  department_id,
  category,
  sum(amount) as amount
from public.v_daily_revenue
group by 1, 2, 3;

create view public.v_payment_method_summary with (security_invoker = true) as
select
  p.hotel_id,
  coalesce(p.paid_at::date, p.created_at::date) as payment_date,
  p.provider,
  p.status,
  p.currency,
  count(*) as payment_count,
  sum(p.amount) as total_amount
from public.payments p
group by 1, 2, 3, 4, 5;

create view public.v_staff_attendance_daily with (security_invoker = true) as
select
  ar.id as attendance_id,
  ar.hotel_id,
  ar.staff_id,
  sp.staff_number,
  p.full_name as staff_name,
  sp.department_id,
  ar.work_date,
  s.name as shift_name,
  s.start_time,
  s.end_time,
  ar.status,
  ar.clock_in_at,
  ar.clock_out_at,
  ar.late_minutes,
  ar.early_minutes,
  ar.worked_minutes
from public.attendance_records ar
join public.staff_shift_assignments ssa on ssa.id = ar.assignment_id
join public.shifts s on s.id = ssa.shift_id
join public.staff_profiles sp on sp.id = ar.staff_id
join public.profiles p on p.id = sp.profile_id;

create view public.v_staff_performance with (security_invoker = true) as
with activity as (
  select
    hotel_id, assigned_to as staff_id, closed_at::date as work_date,
    count(*) as completed_orders, 0::bigint as completed_tasks
  from public.service_orders
  where assigned_to is not null and status = 'closed'
  group by 1, 2, 3
  union all
  select
    hotel_id, assigned_to, delivered_at::date,
    count(*), 0
  from public.laundry_orders
  where assigned_to is not null and status = 'delivered'
  group by 1, 2, 3
  union all
  select
    hotel_id, assigned_to, completed_at::date,
    0, count(*)
  from public.housekeeping_tasks
  where assigned_to is not null and completed_at is not null
  group by 1, 2, 3
),
activity_totals as (
  select
    hotel_id,
    staff_id,
    work_date,
    sum(completed_orders) as completed_orders,
    sum(completed_tasks) as completed_tasks
  from activity
  group by 1, 2, 3
),
attendance_totals as (
  select
    hotel_id,
    staff_id,
    work_date,
    count(*) as scheduled_shifts,
    count(*) filter (where status = 'present') as present_shifts,
    sum(late_minutes) as late_minutes
  from public.attendance_records
  group by 1, 2, 3
)
select
  coalesce(a.hotel_id, t.hotel_id) as hotel_id,
  coalesce(a.staff_id, t.staff_id) as staff_id,
  coalesce(a.work_date, t.work_date) as work_date,
  coalesce(a.completed_orders, 0) as completed_orders,
  coalesce(a.completed_tasks, 0) as completed_tasks,
  coalesce(t.scheduled_shifts, 0) as scheduled_shifts,
  coalesce(t.present_shifts, 0) as present_shifts,
  coalesce(t.late_minutes, 0) as late_minutes,
  case
    when coalesce(t.scheduled_shifts, 0) = 0 then null
    else coalesce(t.present_shifts, 0)::numeric / t.scheduled_shifts
  end as attendance_rate,
  case
    when coalesce(t.present_shifts, 0) = 0 then null
    else greatest(1 - coalesce(t.late_minutes, 0)::numeric / (t.present_shifts * 480), 0)
  end as punctuality_rate
from activity_totals a
full join attendance_totals t
  on t.hotel_id = a.hotel_id
  and t.staff_id = a.staff_id
  and t.work_date = a.work_date;

create view public.v_pending_verifications with (security_invoker = true) as
select
  p.id as payment_id,
  p.hotel_id,
  p.reference,
  p.folio_id,
  p.reservation_id,
  p.provider,
  p.amount,
  p.currency,
  p.status,
  p.created_at,
  p.recorded_by,
  recorder.full_name as submitted_by_name,
  now() - p.created_at as age
from public.payments p
left join public.profiles recorder on recorder.id = p.recorded_by
where p.status = 'pending_verification';

revoke all on public.v_room_status from anon, authenticated;
revoke all on public.v_folio_summary from anon, authenticated;
revoke all on public.v_reservation_financials from anon, authenticated;
revoke all on public.v_daily_occupancy from anon, authenticated;
revoke all on public.v_daily_revenue from anon, authenticated;
revoke all on public.v_daily_collections from anon, authenticated;
revoke all on public.v_outstanding_balances from anon, authenticated;
revoke all on public.v_low_stock from anon, authenticated;
revoke all on public.v_inventory_valuation from anon, authenticated;
revoke all on public.v_department_revenue from anon, authenticated;
revoke all on public.v_payment_method_summary from anon, authenticated;
revoke all on public.v_staff_attendance_daily from anon, authenticated;
revoke all on public.v_staff_performance from anon, authenticated;
revoke all on public.v_pending_verifications from anon, authenticated;
