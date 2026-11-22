alter table public.stock_adjustments add column if not exists idempotency_key text unique;

create or replace function private.rpc_require_self_attendance()
returns void
language plpgsql
stable
set search_path = public, private, pg_temp
as $$
begin
  if private.rpc_is_service_role() then
    if private.rpc_actor_staff_id() is null then
      raise exception 'active staff profile required for attendance' using errcode = '42501';
    end if;
    return;
  end if;
  if not (private.rpc_has_role_permission('attendance.self') or private.has_permission('attendance.self')) then
    raise exception 'missing required permission: attendance.self' using errcode = '42501';
  end if;
  if private.rpc_actor_staff_id() is null then
    raise exception 'active staff profile required for attendance' using errcode = '42501';
  end if;
end;
$$;

create or replace function public.receive_stock_purchase(
  p_stock_purchase_id uuid,
  p_received_at timestamptz default now()
)
returns uuid
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_purchase public.stock_purchases%rowtype;
  v_item record;
  v_department_id uuid;
  v_movement_id uuid;
begin
  perform private.rpc_require_permission('inventory.purchase');

  select * into v_purchase from public.stock_purchases where id = p_stock_purchase_id for update;
  if not found then
    raise exception 'stock purchase not found' using errcode = '22023';
  end if;
  if v_purchase.status <> 'draft' then
    raise exception 'only draft stock purchases can be received' using errcode = '23514';
  end if;

  for v_item in
    select spi.id as item_id, spi.inventory_item_id, spi.quantity, spi.unit_cost,
           ic.department_id
    from public.stock_purchase_items spi
    join public.inventory_items ii on ii.id = spi.inventory_item_id
    left join public.inventory_categories ic on ic.id = ii.category_id
    where spi.stock_purchase_id = p_stock_purchase_id
  loop
    v_movement_id := private.post_stock_movement(
      v_purchase.hotel_id,
      v_item.inventory_item_id,
      v_item.quantity,
      'purchase',
      'stock_purchase',
      p_stock_purchase_id,
      v_item.item_id,
      v_item.unit_cost,
      null,
      v_item.department_id,
      coalesce(v_purchase.invoice_number, 'stock purchase receipt'),
      false,
      null,
      'stock-purchase:' || p_stock_purchase_id::text || ':' || v_item.item_id::text
    );
  end loop;

  update public.stock_purchases
  set status = 'received',
      received_at = coalesce(p_received_at, now()),
      recorded_by = private.rpc_actor_profile_id(),
      updated_at = now(),
      updated_by = private.rpc_actor_profile_id()
  where id = p_stock_purchase_id;

  perform private.log_staff_activity(
    private.rpc_actor_staff_id(), 'stock_purchase_received', 'stock_purchase', p_stock_purchase_id,
    jsonb_build_object('invoice_number', v_purchase.invoice_number, 'total', v_purchase.total)
  );
  return p_stock_purchase_id;
end;
$$;

create or replace function public.request_stock_adjustment(
  p_item_id uuid,
  p_quantity numeric,
  p_reason text,
  p_idempotency_key text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_item public.inventory_items%rowtype;
  v_adjustment_id uuid;
  v_key text;
begin
  perform private.rpc_require_any_permission(array['inventory.read', 'inventory.adjust']);
  if p_quantity is null or p_quantity = 0 then
    raise exception 'adjustment quantity cannot be zero' using errcode = '22023';
  end if;
  if btrim(coalesce(p_reason, '')) = '' then
    raise exception 'adjustment reason is required' using errcode = '22023';
  end if;

  select * into v_item from public.inventory_items where id = p_item_id for update;
  if not found then
    raise exception 'inventory item not found' using errcode = '22023';
  end if;

  v_key := private.ops_idempotency_key(p_idempotency_key);
  select id into v_adjustment_id
  from public.stock_adjustments
  where idempotency_key = v_key;
  if found then
    return v_adjustment_id;
  end if;

  insert into public.stock_adjustments (
    hotel_id, item_id, quantity, reason, requested_by, status, idempotency_key,
    created_by, updated_by
  )
  values (
    v_item.hotel_id, p_item_id, p_quantity, p_reason,
    private.rpc_actor_profile_id(), 'pending', v_key,
    private.rpc_actor_profile_id(), private.rpc_actor_profile_id()
  )
  on conflict (idempotency_key) do nothing
  returning id into v_adjustment_id;

  if v_adjustment_id is null then
    select id into v_adjustment_id from public.stock_adjustments where idempotency_key = v_key;
  end if;
  return v_adjustment_id;
end;
$$;

create or replace function public.approve_stock_adjustment(
  p_adjustment_id uuid,
  p_approve boolean,
  p_override_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_adjustment public.stock_adjustments%rowtype;
  v_item public.inventory_items%rowtype;
  v_department_id uuid;
  v_movement_id uuid;
begin
  perform private.rpc_require_permission('inventory.adjust');

  select * into v_adjustment from public.stock_adjustments where id = p_adjustment_id for update;
  if not found then
    raise exception 'stock adjustment not found' using errcode = '22023';
  end if;
  if v_adjustment.status <> 'pending' then
    raise exception 'only pending stock adjustments can be reviewed' using errcode = '23514';
  end if;

  if not p_approve then
    update public.stock_adjustments
    set status = 'rejected',
        approved_by = private.rpc_actor_profile_id(),
        approved_at = now(),
        updated_at = now(),
        updated_by = private.rpc_actor_profile_id()
    where id = p_adjustment_id;
    return p_adjustment_id;
  end if;

  select * into v_item from public.inventory_items where id = v_adjustment.item_id for update;
  if not found then
    raise exception 'inventory item not found' using errcode = '22023';
  end if;
  select ic.department_id into v_department_id
  from public.inventory_categories ic
  where ic.id = v_item.category_id;

  v_movement_id := private.post_stock_movement(
    v_adjustment.hotel_id,
    v_adjustment.item_id,
    v_adjustment.quantity,
    'adjustment',
    'stock_adjustment',
    p_adjustment_id,
    null,
    null,
    null,
    v_department_id,
    v_adjustment.reason,
    private.rpc_is_service_role() or private.has_permission('inventory.manage'),
    coalesce(nullif(btrim(p_override_reason), ''), 'system stock override'),
    'stock-adjustment:' || p_adjustment_id::text
  );

  update public.stock_adjustments
  set status = 'posted',
      approved_by = private.rpc_actor_profile_id(),
      approved_at = now(),
      movement_id = v_movement_id,
      updated_at = now(),
      updated_by = private.rpc_actor_profile_id()
  where id = p_adjustment_id;

  perform private.log_staff_activity(
    private.rpc_actor_staff_id(), 'stock_adjustment_posted', 'stock_adjustment', p_adjustment_id,
    jsonb_build_object('item_id', v_adjustment.item_id, 'quantity', v_adjustment.quantity)
  );
  return p_adjustment_id;
end;
$$;

create or replace function public.record_stock_usage(
  p_item_id uuid,
  p_quantity numeric,
  p_department_id uuid default null,
  p_source_type text default 'manual_usage',
  p_source_id uuid default null,
  p_reason text default null,
  p_movement_type public.inventory_movement_type default 'usage',
  p_override_reason text default null,
  p_idempotency_key text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_item public.inventory_items%rowtype;
  v_department_id uuid;
  v_key text;
begin
  perform private.rpc_require_any_permission(array['inventory.usage', 'bar_stock.usage', 'recipe.usage']);
  if p_quantity is null or p_quantity <= 0 then
    raise exception 'usage quantity must be positive' using errcode = '22023';
  end if;
  if p_movement_type not in ('usage', 'wastage', 'expiry', 'adjustment') then
    raise exception 'invalid stock usage movement type' using errcode = '22023';
  end if;

  select * into v_item from public.inventory_items where id = p_item_id for update;
  if not found then
    raise exception 'inventory item not found' using errcode = '22023';
  end if;
  v_department_id := coalesce(
    p_department_id,
    (select department_id from public.inventory_categories where id = v_item.category_id)
  );
  v_key := coalesce(
    nullif(btrim(p_idempotency_key), ''),
    p_source_type || ':' || coalesce(p_source_id::text, gen_random_uuid()::text) || ':' || p_item_id::text || ':' || p_movement_type::text
  );

  return private.post_stock_movement(
    v_item.hotel_id,
    p_item_id,
    -p_quantity,
    p_movement_type,
    p_source_type,
    p_source_id,
    null,
    null,
    null,
    v_department_id,
    p_reason,
    private.rpc_is_service_role() or private.has_permission('inventory.manage'),
    coalesce(nullif(btrim(p_override_reason), ''), 'system stock override'),
    v_key
  );
end;
$$;

create or replace function public.transfer_stock(
  p_item_id uuid,
  p_from_location_id uuid,
  p_to_location_id uuid,
  p_quantity numeric,
  p_reason text default null,
  p_idempotency_key text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_item public.inventory_items%rowtype;
  v_department_id uuid;
  v_key text;
  v_out_movement_id uuid;
begin
  perform private.rpc_require_permission('inventory.transfer');
  if p_quantity is null or p_quantity <= 0 then
    raise exception 'transfer quantity must be positive' using errcode = '22023';
  end if;
  if p_from_location_id = p_to_location_id then
    raise exception 'source and destination locations must differ' using errcode = '22023';
  end if;

  select * into v_item from public.inventory_items where id = p_item_id for update;
  if not found then
    raise exception 'inventory item not found' using errcode = '22023';
  end if;
  if not exists (
    select 1 from public.inventory_locations
    where id in (p_from_location_id, p_to_location_id)
      and hotel_id = v_item.hotel_id and is_active
  ) or (
    select count(*) from public.inventory_locations
    where id in (p_from_location_id, p_to_location_id)
      and hotel_id = v_item.hotel_id and is_active
  ) <> 2 then
    raise exception 'valid source and destination locations are required' using errcode = '22023';
  end if;
  select department_id into v_department_id
  from public.inventory_categories where id = v_item.category_id;

  v_key := private.ops_idempotency_key(p_idempotency_key);

  v_out_movement_id := private.post_stock_movement(
    v_item.hotel_id, p_item_id, -p_quantity, 'transfer_out',
    'stock_transfer', p_item_id, null, null, p_from_location_id,
    v_department_id, p_reason, false, null, v_key || ':out'
  );
  perform private.post_stock_movement(
    v_item.hotel_id, p_item_id, p_quantity, 'transfer_in',
    'stock_transfer', p_item_id, null, null, p_to_location_id,
    v_department_id, p_reason, false, null, v_key || ':in'
  );
  return v_out_movement_id;
end;
$$;

create or replace function public.acknowledge_stock_alert(p_alert_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_alert public.stock_alerts%rowtype;
begin
  perform private.rpc_require_permission('inventory.manage');
  select * into v_alert from public.stock_alerts where id = p_alert_id for update;
  if not found then
    raise exception 'stock alert not found' using errcode = '22023';
  end if;
  if v_alert.status <> 'open' then
    raise exception 'only open stock alerts can be acknowledged' using errcode = '23514';
  end if;
  update public.stock_alerts
  set status = 'acknowledged',
      acknowledged_at = now(),
      updated_at = now(),
      updated_by = private.rpc_actor_profile_id()
  where id = p_alert_id;
  return p_alert_id;
end;
$$;

create or replace function public.clock_in(p_work_date date default null)
returns uuid
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_staff_id uuid;
  v_today date;
  v_work_date date;
  v_now_time time;
  v_assignment record;
  v_late_minutes integer;
  v_attendance_id uuid;
begin
  perform private.rpc_require_self_attendance();
  v_staff_id := private.rpc_actor_staff_id();
  v_today := timezone(coalesce((select timezone from public.hotels where id = private.current_hotel_id()), 'Africa/Lagos'), now())::date;
  v_work_date := coalesce(p_work_date, v_today);
  v_now_time := timezone(coalesce((select timezone from public.hotels where id = private.current_hotel_id()), 'Africa/Lagos'), now())::time;

  if exists (
    select 1 from public.attendance_records
    where staff_id = v_staff_id and clock_out_at is null
  ) then
    raise exception 'staff already has an open attendance record' using errcode = '23514';
  end if;

  select a.*, s.start_time, s.end_time, s.grace_minutes
  into v_assignment
  from public.staff_shift_assignments a
  join public.shifts s on s.id = a.shift_id
  where a.staff_id = v_staff_id
    and a.work_date = v_work_date
    and a.status = 'scheduled'
    and s.is_active
  order by case when s.start_time <= v_now_time then 0 else 1 end,
           abs(extract(epoch from (s.start_time - v_now_time)))
  limit 1
  for update of a;
  if not found then
    raise exception 'no scheduled shift assignment found for %', v_work_date using errcode = '22023';
  end if;

  select id into v_attendance_id
  from public.attendance_records
  where assignment_id = v_assignment.id;
  if found then
    raise exception 'attendance record already exists for this assignment' using errcode = '23514';
  end if;

  v_late_minutes := greatest(
    0,
    floor(extract(epoch from (v_now_time - v_assignment.start_time)) / 60)::integer - v_assignment.grace_minutes
  );

  insert into public.attendance_records (
    hotel_id, staff_id, assignment_id, work_date, clock_in_at, late_minutes,
    status, created_by, updated_by
  )
  values (
    private.current_hotel_id(), v_staff_id, v_assignment.id, v_work_date,
    now(), v_late_minutes, 'present', private.rpc_actor_profile_id(),
    private.rpc_actor_profile_id()
  )
  returning id into v_attendance_id;

  perform private.log_staff_activity(
    v_staff_id, 'clock_in', 'attendance_record', v_attendance_id,
    jsonb_build_object('work_date', v_work_date, 'late_minutes', v_late_minutes)
  );
  return v_attendance_id;
end;
$$;

create or replace function public.clock_out(p_attendance_id uuid default null)
returns uuid
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_staff_id uuid;
  v_attendance public.attendance_records%rowtype;
  v_shift record;
  v_worked_minutes integer;
  v_early_minutes integer;
  v_scheduled_minutes integer;
begin
  perform private.rpc_require_self_attendance();
  v_staff_id := private.rpc_actor_staff_id();

  if p_attendance_id is null then
    select * into v_attendance
    from public.attendance_records
    where staff_id = v_staff_id and clock_out_at is null
    limit 1
    for update;
  else
    select * into v_attendance
    from public.attendance_records
    where id = p_attendance_id and staff_id = v_staff_id
    for update;
  end if;
  if not found then
    raise exception 'open attendance record not found' using errcode = '22023';
  end if;
  if v_attendance.clock_out_at is not null then
    raise exception 'attendance record is already closed' using errcode = '23514';
  end if;
  if v_attendance.clock_in_at is null then
    raise exception 'attendance record has no clock-in time' using errcode = '23514';
  end if;

  select s.start_time, s.end_time, s.grace_minutes into v_shift
  from public.staff_shift_assignments a
  join public.shifts s on s.id = a.shift_id
  where a.id = v_attendance.assignment_id;

  v_worked_minutes := greatest(0, floor(extract(epoch from (now() - v_attendance.clock_in_at)) / 60)::integer);
  v_scheduled_minutes := floor(
    extract(epoch from (
      case when v_shift.end_time >= v_shift.start_time
        then v_shift.end_time - v_shift.start_time
        else v_shift.end_time + interval '24 hours' - v_shift.start_time
      end
    )) / 60
  )::integer;
  v_early_minutes := greatest(0, v_scheduled_minutes - v_worked_minutes - coalesce(v_shift.grace_minutes, 0));

  update public.attendance_records
  set clock_out_at = now(),
      worked_minutes = v_worked_minutes,
      early_minutes = v_early_minutes,
      status = 'present',
      updated_at = now(),
      updated_by = private.rpc_actor_profile_id()
  where id = v_attendance.id;

  perform private.log_staff_activity(
    v_staff_id, 'clock_out', 'attendance_record', v_attendance.id,
    jsonb_build_object(
      'worked_minutes', v_worked_minutes,
      'early_minutes', v_early_minutes,
      'late_minutes', v_attendance.late_minutes
    )
  );
  return v_attendance.id;
end;
$$;

create or replace function public.mark_attendance_exception(
  p_assignment_id uuid,
  p_status public.attendance_status,
  p_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_assignment public.staff_shift_assignments%rowtype;
  v_attendance_id uuid;
begin
  perform private.rpc_require_any_permission(array['attendance.read_department', 'attendance.adjust']);
  select * into v_assignment from public.staff_shift_assignments where id = p_assignment_id for update;
  if not found then
    raise exception 'shift assignment not found' using errcode = '22023';
  end if;
  if p_status not in ('absent', 'no_show', 'adjusted') then
    raise exception 'invalid attendance exception status' using errcode = '22023';
  end if;
  if p_status = 'adjusted' and btrim(coalesce(p_notes, '')) = '' then
    raise exception 'adjustment reason is required' using errcode = '22023';
  end if;
  if exists (
    select 1 from public.attendance_records
    where assignment_id = p_assignment_id and clock_out_at is null
  ) then
    raise exception 'cannot mark exception while attendance is open' using errcode = '23514';
  end if;

  insert into public.attendance_records (
    hotel_id, staff_id, assignment_id, work_date, status, notes,
    adjusted_by, adjusted_at, adjustment_reason, created_by, updated_by
  )
  values (
    v_assignment.hotel_id, v_assignment.staff_id, p_assignment_id,
    v_assignment.work_date, p_status, p_notes,
    case when p_status = 'adjusted' then private.rpc_actor_profile_id() else null end,
    case when p_status = 'adjusted' then now() else null end,
    case when p_status = 'adjusted' then p_notes else null end,
    private.rpc_actor_profile_id(), private.rpc_actor_profile_id()
  )
  on conflict (assignment_id) do update
  set status = excluded.status,
      notes = excluded.notes,
      adjusted_by = excluded.adjusted_by,
      adjusted_at = excluded.adjusted_at,
      adjustment_reason = excluded.adjustment_reason,
      updated_at = now(),
      updated_by = private.rpc_actor_profile_id()
  returning id into v_attendance_id;

  perform private.log_staff_activity(
    private.rpc_actor_staff_id() , 'attendance_exception_marked', 'attendance_record', v_attendance_id,
    jsonb_build_object('assignment_id', p_assignment_id, 'status', p_status)
  );
  return v_attendance_id;
end;
$$;

create or replace function public.adjust_attendance(
  p_attendance_id uuid,
  p_clock_in_at timestamptz,
  p_clock_out_at timestamptz,
  p_reason text
)
returns uuid
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_attendance public.attendance_records%rowtype;
  v_shift record;
  v_late_minutes integer;
  v_early_minutes integer;
  v_worked_minutes integer;
  v_scheduled_minutes integer;
  v_now_time time;
begin
  perform private.rpc_require_permission('attendance.adjust');
  if btrim(coalesce(p_reason, '')) = '' then
    raise exception 'attendance adjustment reason is required' using errcode = '22023';
  end if;
  if p_clock_in_at is null or p_clock_out_at is null or p_clock_out_at < p_clock_in_at then
    raise exception 'valid clock-in and clock-out times are required' using errcode = '22023';
  end if;

  select * into v_attendance from public.attendance_records where id = p_attendance_id for update;
  if not found then
    raise exception 'attendance record not found' using errcode = '22023';
  end if;

  select s.start_time, s.end_time, s.grace_minutes into v_shift
  from public.staff_shift_assignments a
  join public.shifts s on s.id = a.shift_id
  where a.id = v_attendance.assignment_id;

  v_now_time := timezone(coalesce((select timezone from public.hotels where id = v_attendance.hotel_id), 'Africa/Lagos'), p_clock_in_at)::time;
  v_late_minutes := greatest(
    0,
    floor(extract(epoch from (v_now_time - v_shift.start_time)) / 60)::integer - coalesce(v_shift.grace_minutes, 0)
  );
  v_worked_minutes := greatest(0, floor(extract(epoch from (p_clock_out_at - p_clock_in_at)) / 60)::integer);
  v_scheduled_minutes := floor(
    extract(epoch from (
      case when v_shift.end_time >= v_shift.start_time
        then v_shift.end_time - v_shift.start_time
        else v_shift.end_time + interval '24 hours' - v_shift.start_time
      end
    )) / 60
  )::integer;
  v_early_minutes := greatest(0, v_scheduled_minutes - v_worked_minutes - coalesce(v_shift.grace_minutes, 0));

  update public.attendance_records
  set clock_in_at = p_clock_in_at,
      clock_out_at = p_clock_out_at,
      late_minutes = v_late_minutes,
      early_minutes = v_early_minutes,
      worked_minutes = v_worked_minutes,
      status = 'adjusted',
      adjusted_by = private.rpc_actor_profile_id(),
      adjusted_at = now(),
      adjustment_reason = p_reason,
      updated_at = now(),
      updated_by = private.rpc_actor_profile_id()
  where id = p_attendance_id;

  perform private.log_staff_activity(
    private.rpc_actor_staff_id(), 'attendance_adjusted', 'attendance_record', p_attendance_id,
    jsonb_build_object('reason', p_reason, 'worked_minutes', v_worked_minutes)
  );
  return p_attendance_id;
end;
$$;

create or replace function public.create_shift_handover(
  p_department_id uuid,
  p_shift_date date,
  p_incoming_staff_id uuid,
  p_shift_id uuid default null,
  p_checklist jsonb default '{}'::jsonb,
  p_notes text default null,
  p_expected_cash numeric default 0
)
returns uuid
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_outgoing_staff_id uuid;
  v_handover_id uuid;
  v_checklist jsonb;
begin
  perform private.rpc_require_permission('handover.create');
  v_outgoing_staff_id := private.rpc_actor_staff_id();
  if v_outgoing_staff_id is null then
    raise exception 'active staff profile required for handover' using errcode = '42501';
  end if;
  if p_incoming_staff_id is null or p_incoming_staff_id = v_outgoing_staff_id then
    raise exception 'valid incoming staff is required' using errcode = '22023';
  end if;
  if not exists (
    select 1 from public.staff_profiles
    where id = p_incoming_staff_id and employment_status = 'active'::public.employment_status
  ) then
    raise exception 'incoming staff is not active' using errcode = '23514';
  end if;
  if p_department_id is null or not exists (select 1 from public.departments where id = p_department_id and is_active) then
    raise exception 'valid department is required' using errcode = '22023';
  end if;
  if p_expected_cash is null or p_expected_cash < 0 then
    raise exception 'expected cash cannot be negative' using errcode = '22023';
  end if;

  v_checklist := coalesce(p_checklist, '{}'::jsonb) || jsonb_build_object(
    'current_guests', (
      select count(*) from public.reservations
      where hotel_id = private.current_hotel_id() and status = 'checked_in'
    ),
    'arrivals', (
      select count(*) from public.reservations
      where hotel_id = private.current_hotel_id() and check_in = p_shift_date and status not in ('cancelled', 'expired')
    ),
    'departures', (
      select count(*) from public.reservations
      where hotel_id = private.current_hotel_id() and check_out = p_shift_date and status not in ('cancelled', 'expired')
    ),
    'outstanding_balance', (
      select coalesce(sum(public.folio_balance(id)), 0)
      from public.folios
      where hotel_id = private.current_hotel_id() and status in ('open', 'closed_with_balance')
    ),
    'pending_transfers', (
      select count(*) from public.payments
      where hotel_id = private.current_hotel_id() and status = 'pending_verification'
    ),
    'open_service_orders', (
      select count(*) from public.service_orders
      where hotel_id = private.current_hotel_id() and status not in ('closed', 'cancelled')
    ),
    'open_laundry_orders', (
      select count(*) from public.laundry_orders
      where hotel_id = private.current_hotel_id() and status not in ('delivered', 'cancelled')
    )
  );

  insert into public.shift_handovers (
    hotel_id, department_id, shift_date, shift_id, outgoing_staff_id,
    incoming_staff_id, status, checklist, notes, expected_cash,
    created_by, updated_by
  )
  values (
    private.current_hotel_id(), p_department_id, p_shift_date, p_shift_id,
    v_outgoing_staff_id, p_incoming_staff_id, 'draft', v_checklist, p_notes,
    p_expected_cash, private.rpc_actor_profile_id(), private.rpc_actor_profile_id()
  )
  returning id into v_handover_id;

  perform private.log_staff_activity(
    v_outgoing_staff_id, 'handover_created', 'shift_handover', v_handover_id,
    jsonb_build_object('shift_date', p_shift_date, 'department_id', p_department_id)
  );
  return v_handover_id;
end;
$$;

create or replace function public.submit_shift_handover(
  p_handover_id uuid,
  p_counted_cash numeric,
  p_notes text default null,
  p_variance_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_handover public.shift_handovers%rowtype;
  v_outgoing_staff_id uuid;
begin
  perform private.rpc_require_permission('handover.create');
  v_outgoing_staff_id := private.rpc_actor_staff_id();
  select * into v_handover from public.shift_handovers where id = p_handover_id for update;
  if not found then
    raise exception 'shift handover not found' using errcode = '22023';
  end if;
  if v_outgoing_staff_id is null or v_handover.outgoing_staff_id <> v_outgoing_staff_id then
    raise exception 'only outgoing staff can submit this handover' using errcode = '42501';
  end if;
  if v_handover.status <> 'draft' then
    raise exception 'only draft handovers can be submitted' using errcode = '23514';
  end if;
  if p_counted_cash is null or p_counted_cash < 0 then
    raise exception 'counted cash cannot be negative' using errcode = '22023';
  end if;

  update public.shift_handovers
  set status = 'submitted',
      counted_cash = p_counted_cash,
      variance_reason = p_variance_reason,
      notes = coalesce(p_notes, notes),
      submitted_at = now(),
      updated_at = now(),
      updated_by = private.rpc_actor_profile_id()
  where id = p_handover_id;

  perform private.log_staff_activity(
    v_outgoing_staff_id, 'handover_submitted', 'shift_handover', p_handover_id,
    jsonb_build_object('counted_cash', p_counted_cash, 'variance', p_counted_cash - v_handover.expected_cash)
  );
  return p_handover_id;
end;
$$;

create or replace function public.acknowledge_shift_handover(
  p_handover_id uuid,
  p_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_handover public.shift_handovers%rowtype;
  v_incoming_staff_id uuid;
begin
  perform private.rpc_require_permission('handover.acknowledge');
  v_incoming_staff_id := private.rpc_actor_staff_id();
  select * into v_handover from public.shift_handovers where id = p_handover_id for update;
  if not found then
    raise exception 'shift handover not found' using errcode = '22023';
  end if;
  if v_incoming_staff_id is null or v_handover.incoming_staff_id <> v_incoming_staff_id then
    raise exception 'only incoming staff can acknowledge this handover' using errcode = '42501';
  end if;
  if v_handover.status <> 'submitted' then
    raise exception 'only submitted handovers can be acknowledged' using errcode = '23514';
  end if;

  update public.shift_handovers
  set status = 'acknowledged',
      acknowledged_at = now(),
      acknowledged_by = v_incoming_staff_id,
      notes = coalesce(p_notes, notes),
      updated_at = now(),
      updated_by = private.rpc_actor_profile_id()
  where id = p_handover_id;

  perform private.log_staff_activity(
    v_incoming_staff_id, 'handover_acknowledged', 'shift_handover', p_handover_id,
    jsonb_build_object('shift_date', v_handover.shift_date)
  );
  return p_handover_id;
end;
$$;

drop policy if exists incoming_acknowledge_shift_handovers on public.shift_handovers;
create policy incoming_acknowledge_shift_handovers on public.shift_handovers for update to authenticated using (
  private.has_permission('handover.acknowledge')
  and incoming_staff_id = private.current_staff_id()
  and status = 'submitted'
) with check (
  private.has_permission('handover.acknowledge')
  and incoming_staff_id = private.current_staff_id()
  and acknowledged_by = private.current_staff_id()
  and status = 'acknowledged'
);

revoke all on function public.receive_stock_purchase(uuid, timestamptz) from public, anon;
grant execute on function public.receive_stock_purchase(uuid, timestamptz) to authenticated, service_role;

revoke all on function public.request_stock_adjustment(uuid, numeric, text, text) from public, anon;
grant execute on function public.request_stock_adjustment(uuid, numeric, text, text) to authenticated, service_role;

revoke all on function public.approve_stock_adjustment(uuid, boolean, text) from public, anon;
grant execute on function public.approve_stock_adjustment(uuid, boolean, text) to authenticated, service_role;

revoke all on function public.record_stock_usage(uuid, numeric, uuid, text, uuid, text, public.inventory_movement_type, text, text) from public, anon;
grant execute on function public.record_stock_usage(uuid, numeric, uuid, text, uuid, text, public.inventory_movement_type, text, text) to authenticated, service_role;

revoke all on function public.transfer_stock(uuid, uuid, uuid, numeric, text, text) from public, anon;
grant execute on function public.transfer_stock(uuid, uuid, uuid, numeric, text, text) to authenticated, service_role;

revoke all on function public.acknowledge_stock_alert(uuid) from public, anon;
grant execute on function public.acknowledge_stock_alert(uuid) to authenticated, service_role;

revoke all on function public.clock_in(date) from public, anon;
grant execute on function public.clock_in(date) to authenticated, service_role;

revoke all on function public.clock_out(uuid) from public, anon;
grant execute on function public.clock_out(uuid) to authenticated, service_role;

revoke all on function public.mark_attendance_exception(uuid, public.attendance_status, text) from public, anon;
grant execute on function public.mark_attendance_exception(uuid, public.attendance_status, text) to authenticated, service_role;

revoke all on function public.adjust_attendance(uuid, timestamptz, timestamptz, text) from public, anon;
grant execute on function public.adjust_attendance(uuid, timestamptz, timestamptz, text) to authenticated, service_role;

revoke all on function public.create_shift_handover(uuid, date, uuid, uuid, jsonb, text, numeric) from public, anon;
grant execute on function public.create_shift_handover(uuid, date, uuid, uuid, jsonb, text, numeric) to authenticated, service_role;

revoke all on function public.submit_shift_handover(uuid, numeric, text, text) from public, anon;
grant execute on function public.submit_shift_handover(uuid, numeric, text, text) to authenticated, service_role;

revoke all on function public.acknowledge_shift_handover(uuid, text) from public, anon;
grant execute on function public.acknowledge_shift_handover(uuid, text) to authenticated, service_role;
