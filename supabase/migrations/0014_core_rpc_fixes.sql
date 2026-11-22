create or replace function private.rpc_has_role_permission(p_permission_key text)
returns boolean
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select exists (
    select 1
    from public.user_roles ur
    join public.role_permissions rp on rp.role_id = ur.role_id
    join public.permissions p on p.id = rp.permission_id
    join public.profiles pr on pr.id = ur.user_id and pr.is_active
    where ur.user_id = auth.uid() and p.key = p_permission_key
  );
$$;

create or replace function public.get_available_rooms(
  p_check_in date,
  p_check_out date,
  p_room_category_id uuid default null,
  p_adults integer default 1
)
returns table (
  room_id uuid,
  room_number text,
  category_id uuid,
  category_name text,
  nightly_rate numeric(14,2),
  max_occupancy integer
)
language sql
stable
security definer
set search_path = public, private, extensions, pg_temp
as $$
  select r.id, r.number, rc.id, rc.name,
         coalesce(r.rate_override, rc.base_rate)::numeric(14,2),
         r.max_occupancy
  from public.rooms r
  join public.room_categories rc on rc.id = r.category_id
  where r.is_active
    and r.operational_status = 'available'
    and r.housekeeping_status = 'clean'
    and (p_room_category_id is null or rc.id = p_room_category_id)
    and p_adults <= r.max_occupancy
    and not exists (
      select 1
      from public.room_allocation_holds h
      where h.room_id = r.id
        and daterange(h.check_in, h.check_out, '[)') && daterange(p_check_in, p_check_out, '[)')
    )
    and not exists (
      select 1
      from public.room_maintenance m
      where m.room_id = r.id
        and m.status not in ('resolved', 'cancelled')
        and (m.started_at is null or m.started_at < p_check_out::timestamp)
        and (m.resolved_at is null or m.resolved_at > p_check_in::timestamp)
    )
  order by rc.sort_order, r.sort_order, r.number;
$$;

create or replace function public.create_reservation(
  p_hotel_id uuid,
  p_room_id uuid,
  p_check_in date,
  p_check_out date,
  p_guest_id uuid default null,
  p_guest_full_name text default null,
  p_guest_email text default null,
  p_guest_phone text default null,
  p_adults integer default 1,
  p_children integer default 0,
  p_source text default 'web',
  p_idempotency_key text default null
)
returns table (
  reservation_id uuid,
  folio_id uuid,
  reference text,
  required_deposit numeric(14,2)
)
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_hotel_id uuid := private.rpc_hotel_id(p_hotel_id);
  v_guest_id uuid := p_guest_id;
  v_room record;
  v_reservation_id uuid;
  v_folio_id uuid;
  v_bill_id uuid;
  v_reference text;
  v_folio_number text;
  v_room_subtotal numeric(14,2);
  v_tax numeric(14,2);
  v_total numeric(14,2);
  v_deposit numeric(14,2);
  v_nights integer;
  v_source public.reservation_source;
  v_lines jsonb;
begin
  if p_check_out <= p_check_in then
    raise exception 'check_out must be after check_in' using errcode = '22023';
  end if;
  if p_adults is null or p_adults < 1 then
    raise exception 'adults must be at least 1' using errcode = '22023';
  end if;
  v_nights := p_check_out - p_check_in;
  v_source := p_source::public.reservation_source;

  if p_idempotency_key is not null then
    select r.id, f.id, r.reference, r.required_deposit
    into reservation_id, folio_id, reference, required_deposit
    from public.reservations r
    left join public.folios f on f.reservation_id = r.id and f.type = 'guest'
    where r.idempotency_key = p_idempotency_key
    limit 1;
    if found then
      return next;
      return;
    end if;
  end if;

  select r.id, r.hotel_id, r.category_id, r.max_occupancy,
         coalesce(r.rate_override, rc.base_rate)::numeric(14,2) as nightly_rate,
         bs.deposit_percentage, bs.hold_minutes,
         hs.tax_rate, hs.service_charge_rate,
         cp.id as cancellation_policy_id
  into v_room
  from public.rooms r
  join public.room_categories rc on rc.id = r.category_id
  join public.booking_settings bs on bs.hotel_id = r.hotel_id
  join public.hotel_settings hs on hs.hotel_id = r.hotel_id
  left join public.cancellation_policies cp on cp.hotel_id = r.hotel_id and cp.is_default and cp.is_active
  where r.id = p_room_id
    and r.hotel_id = v_hotel_id
    and r.is_active
    and r.operational_status = 'available'
    and r.housekeeping_status = 'clean'
    and p_adults <= r.max_occupancy;

  if not found then
    raise exception 'room is not available' using errcode = '23514';
  end if;

  if exists (
    select 1
    from public.room_maintenance m
    where m.room_id = p_room_id
      and m.status not in ('resolved', 'cancelled')
      and (m.started_at is null or m.started_at < p_check_out::timestamp)
      and (m.resolved_at is null or m.resolved_at > p_check_in::timestamp)
  ) then
    raise exception 'room is under maintenance for the requested dates' using errcode = '23514';
  end if;

  if v_guest_id is null then
    if p_guest_email is not null then
      select g.id into v_guest_id
      from public.guests g
      where g.hotel_id = v_hotel_id
        and lower(g.email::text) = lower(p_guest_email)
      order by g.created_at
      limit 1;
    end if;
    if v_guest_id is null and p_guest_phone is not null then
      select g.id into v_guest_id
      from public.guests g
      where g.hotel_id = v_hotel_id
        and g.phone_normalized = regexp_replace(p_guest_phone, '\D', '', 'g')
      order by g.created_at
      limit 1;
    end if;
    if v_guest_id is null then
      if p_guest_full_name is null or btrim(p_guest_full_name) = '' then
        raise exception 'guest identity is required' using errcode = '22023';
      end if;
      insert into public.guests (
        hotel_id, full_name, email, email_normalized, phone, phone_normalized, auth_user_id
      )
      values (
        v_hotel_id, btrim(p_guest_full_name), nullif(p_guest_email, ''), lower(nullif(p_guest_email, '')),
        nullif(p_guest_phone, ''), regexp_replace(coalesce(p_guest_phone, ''), '\D', '', 'g'),
        case when private.rpc_is_service_role() then null else auth.uid() end
      )
      returning id into v_guest_id;
    end if;
  else
    if not exists (select 1 from public.guests g where g.id = v_guest_id and g.hotel_id = v_hotel_id) then
      raise exception 'guest does not belong to hotel' using errcode = '22023';
    end if;
  end if;

  v_room_subtotal := round(v_room.nightly_rate * v_nights, 2);
  v_tax := round(v_room_subtotal * v_room.tax_rate / 100, 2);
  v_total := v_room_subtotal + v_tax;
  v_deposit := round(v_total * v_room.deposit_percentage / 100, 2);

  v_reference := public.allocate_reference('reservation', 'AUR');

  begin
    insert into public.reservations (
      hotel_id, reference, guest_id, cancellation_policy_id, check_in, check_out,
      adults, children, room_subtotal, tax, accommodation_total,
      deposit_percentage, required_deposit, status, payment_status, source,
      hold_expires_at, rate_snapshot, tax_snapshot, policy_snapshot,
      idempotency_key, created_by
    )
    values (
      v_hotel_id, v_reference, v_guest_id, v_room.cancellation_policy_id, p_check_in, p_check_out,
      p_adults, p_children, v_room_subtotal, v_tax, v_total,
      v_room.deposit_percentage, v_deposit, 'pending', 'unpaid', v_source,
      now() + (v_room.hold_minutes || ' minutes')::interval,
      jsonb_build_object('room_id', p_room_id, 'nightly_rate', v_room.nightly_rate, 'nights', v_nights),
      jsonb_build_object('tax_rate', v_room.tax_rate, 'service_charge_rate', v_room.service_charge_rate),
      jsonb_build_object('deposit_percentage', v_room.deposit_percentage, 'hold_minutes', v_room.hold_minutes),
      p_idempotency_key, private.rpc_actor_profile_id()
    )
    returning id into v_reservation_id;
  exception
    when unique_violation then
      if p_idempotency_key is not null then
        select r.id, f.id, r.reference, r.required_deposit
        into reservation_id, folio_id, reference, required_deposit
        from public.reservations r
        left join public.folios f on f.reservation_id = r.id and f.type = 'guest'
        where r.idempotency_key = p_idempotency_key
        limit 1;
        if found then
          return next;
          return;
        end if;
      end if;
      raise;
  end;

  insert into public.reservation_guests (reservation_id, guest_id, is_primary)
  values (v_reservation_id, v_guest_id, true);

  insert into public.reservation_room_assignments (
    reservation_id, room_id, nightly_rate, check_in, check_out, occupancy, is_primary
  )
  values (v_reservation_id, p_room_id, v_room.nightly_rate, p_check_in, p_check_out, p_adults, true);

  begin
    insert into public.room_allocation_holds (reservation_id, room_id, check_in, check_out)
    values (v_reservation_id, p_room_id, p_check_in, p_check_out);
  exception
    when exclusion_violation then
      raise exception 'room no longer available' using errcode = '23P01';
  end;

  v_folio_number := public.allocate_reference('folio', 'FOL');
  insert into public.folios (folio_number, hotel_id, reservation_id, guest_id, type, status, currency)
  values (v_folio_number, v_hotel_id, v_reservation_id, v_guest_id, 'guest', 'open', 'NGN')
  returning id into v_folio_id;

  insert into public.bills (
    folio_id, source_type, source_id, subtotal, tax, discount, total,
    status, posted_by, posted_at
  )
  values (
    v_folio_id, 'reservation', v_reservation_id, v_room_subtotal, v_tax, 0, v_total,
    'posted', private.rpc_actor_profile_id(), now()
  )
  returning id into v_bill_id;

  insert into public.bill_items (
    bill_id, folio_id, description, quantity, unit_price, tax_rate,
    tax_amount, discount, total, source_type, source_id, posted_by, posted_at
  )
  values (
    v_bill_id, v_folio_id, 'Accommodation - ' || v_reference, v_nights, v_room.nightly_rate,
    v_room.tax_rate, v_tax, 0, v_total, 'reservation', v_reservation_id,
    private.rpc_actor_profile_id(), now()
  );

  v_lines := jsonb_build_array(
    jsonb_build_object('code', '1100', 'debit', v_total::text),
    jsonb_build_object('code', '4000', 'credit', v_room_subtotal::text)
  );
  if v_tax > 0 then
    v_lines := v_lines || jsonb_build_array(jsonb_build_object('code', '2100', 'credit', v_tax::text));
  end if;

  perform private.post_ledger(
    v_hotel_id,
    'charge',
    'reservation',
    v_reservation_id,
    'Accommodation - ' || v_reference,
    'accommodation:' || v_reservation_id::text,
    v_lines,
    null,
    v_guest_id,
    v_folio_id
  );

  reservation_id := v_reservation_id;
  folio_id := v_folio_id;
  reference := v_reference;
  required_deposit := v_deposit;
  return next;
end;
$$;

create or replace function public.confirm_reservation(
  p_reservation_id uuid,
  p_pay_later_approved boolean default false
)
returns void
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_reservation record;
begin
  if not private.rpc_is_service_role() then
    if not private.has_permission('reservation.update')
       and not private.guest_owns_reservation(p_reservation_id) then
      raise exception 'not allowed to confirm reservation' using errcode = '42501';
    end if;
  end if;

  select * into v_reservation from public.reservations where id = p_reservation_id for update;
  if not found then
    raise exception 'reservation not found' using errcode = '22023';
  end if;
  if v_reservation.status <> 'pending' then
    raise exception 'reservation status % cannot be confirmed', v_reservation.status using errcode = '23514';
  end if;
  if v_reservation.required_deposit > 0
     and v_reservation.payment_status not in ('paid', 'partially_paid')
     and not p_pay_later_approved then
    raise exception 'required deposit has not been received' using errcode = '23514';
  end if;

  update public.reservations set status = 'confirmed' where id = p_reservation_id;
  insert into public.reservation_status_history (reservation_id, from_status, to_status, reason, actor_id)
  values (
    p_reservation_id,
    'pending'::public.reservation_status,
    'confirmed'::public.reservation_status,
    case when p_pay_later_approved then 'pay later approved' else 'deposit received' end,
    private.rpc_actor_profile_id()
  );
end;
$$;

create or replace function public.check_out_reservation(
  p_reservation_id uuid,
  p_allow_balance boolean default false,
  p_approved_by uuid default null,
  p_balance_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_reservation record;
  v_folio record;
  v_room_id uuid;
  v_balance numeric(14,2);
begin
  perform private.rpc_require_permission('reservation.checkout');

  select * into v_reservation from public.reservations where id = p_reservation_id for update;
  if not found then
    raise exception 'reservation not found' using errcode = '22023';
  end if;
  if v_reservation.status = 'checked_out' then
    return;
  end if;
  if v_reservation.status <> 'checked_in' then
    raise exception 'reservation status % cannot check out', v_reservation.status using errcode = '23514';
  end if;

  select f.*, public.folio_balance(f.id) as balance
  into v_folio
  from public.folios f
  where f.reservation_id = p_reservation_id and f.type = 'guest'
  order by f.created_at desc
  limit 1;
  if not found then
    raise exception 'guest folio not found' using errcode = '22023';
  end if;
  v_balance := v_folio.balance;

  if v_balance > 0 and not p_allow_balance then
    raise exception 'folio balance % must be settled before checkout', v_balance using errcode = '23514';
  end if;
  if p_allow_balance and (p_approved_by is null or p_balance_reason is null or btrim(p_balance_reason) = '') then
    raise exception 'approved outstanding balance requires approver and reason' using errcode = '22023';
  end if;

  select rra.room_id into v_room_id
  from public.reservation_room_assignments rra
  where rra.reservation_id = p_reservation_id and rra.is_primary
  limit 1;

  update public.folios
  set status = case when v_balance > 0 then 'closed_with_balance'::public.folio_status else 'closed_paid'::public.folio_status end,
      closed_at = now()
  where id = v_folio.id;

  update public.reservations set status = 'checked_out' where id = p_reservation_id;

  if v_room_id is not null then
    update public.rooms
    set operational_status = 'blocked',
        housekeeping_status = 'dirty'
    where id = v_room_id;

    insert into public.housekeeping_tasks (
      hotel_id, room_id, reservation_id, task_type, status, priority, due_at
    )
    select v_reservation.hotel_id, v_room_id, p_reservation_id, 'departure', 'pending', 'high', now() + interval '2 hours'
    where not exists (
      select 1
      from public.housekeeping_tasks ht
      where ht.room_id = v_room_id
        and ht.reservation_id = p_reservation_id
        and ht.task_type = 'departure'
        and ht.status <> 'completed'
    );
  end if;

  delete from public.room_allocation_holds where reservation_id = p_reservation_id;
end;
$$;

create or replace function public.post_bill_item(
  p_folio_id uuid,
  p_department_id uuid,
  p_description text,
  p_quantity numeric,
  p_unit_price numeric,
  p_tax_rate numeric default 0,
  p_discount numeric default 0,
  p_source_type text default null,
  p_source_id uuid default null,
  p_idempotency_key text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_folio record;
  v_department_key text;
  v_revenue_code text;
  v_subtotal numeric(14,2);
  v_tax numeric(14,2);
  v_total numeric(14,2);
  v_bill_id uuid;
  v_item_id uuid;
  v_ledger_key text;
  v_lines jsonb;
begin
  perform private.rpc_require_any_permission(array['folio.charge', 'order.create']);

  if p_quantity is null or p_quantity <= 0 then
    raise exception 'quantity must be positive' using errcode = '22023';
  end if;
  if p_unit_price is null or p_unit_price < 0 then
    raise exception 'unit price cannot be negative' using errcode = '22023';
  end if;
  if p_idempotency_key is not null
     and p_idempotency_key !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
    raise exception 'bill item idempotency key must be a uuid' using errcode = '22023';
  end if;

  v_ledger_key := coalesce(p_idempotency_key, 'bill-item:' || gen_random_uuid()::text);
  select ft.source_id into v_item_id
  from public.financial_transactions ft
  where ft.idempotency_key = v_ledger_key;
  if found then
    return v_item_id;
  end if;

  select f.* into v_folio from public.folios f where f.id = p_folio_id for update;
  if not found then
    raise exception 'folio not found' using errcode = '22023';
  end if;
  if v_folio.status not in ('open', 'closed_with_balance') then
    raise exception 'folio % does not accept charges', p_folio_id using errcode = '23514';
  end if;

  select d.key into v_department_key from public.departments d where d.id = p_department_id;
  v_revenue_code := case v_department_key
    when 'restaurant' then '4010'
    when 'kitchen' then '4010'
    when 'bar' then '4020'
    when 'laundry' then '4030'
    else '4000'
  end;

  v_subtotal := round(p_quantity * p_unit_price, 2);
  v_tax := round(v_subtotal * coalesce(p_tax_rate, 0) / 100, 2);
  v_total := v_subtotal - coalesce(p_discount, 0) + v_tax;
  if v_total < 0 then
    raise exception 'bill item total cannot be negative' using errcode = '23514';
  end if;

  insert into public.bills (
    folio_id, department_id, source_type, source_id,
    subtotal, tax, discount, total, status, posted_by, posted_at
  )
  values (
    p_folio_id, p_department_id, p_source_type, p_source_id,
    v_subtotal, v_tax, coalesce(p_discount, 0), v_total, 'posted',
    private.rpc_actor_profile_id(), now()
  )
  returning id into v_bill_id;

  insert into public.bill_items (
    bill_id, folio_id, description, quantity, unit_price, tax_rate,
    tax_amount, discount, total, source_type, source_id,
    source_line_id, posted_by, posted_at
  )
  values (
    v_bill_id, p_folio_id, p_description, p_quantity, p_unit_price, coalesce(p_tax_rate, 0),
    v_tax, coalesce(p_discount, 0), v_total, p_source_type, p_source_id,
    p_idempotency_key::uuid, private.rpc_actor_profile_id(), now()
  )
  returning id into v_item_id;

  if v_total > 0 then
    v_lines := jsonb_build_array(
      jsonb_build_object('code', '1100', 'debit', v_total::text),
      jsonb_build_object('code', v_revenue_code, 'credit', greatest(v_subtotal - coalesce(p_discount, 0), 0)::text)
    );
    if v_tax > 0 then
      v_lines := v_lines || jsonb_build_array(jsonb_build_object('code', '2100', 'credit', v_tax::text));
    end if;

    perform private.post_ledger(
      v_folio.hotel_id,
      'charge',
      coalesce(p_source_type, 'bill_item'),
      v_item_id,
      coalesce(p_description, 'folio charge'),
      v_ledger_key,
      v_lines,
      p_department_id,
      v_folio.guest_id,
      p_folio_id
    );
  end if;

  return v_item_id;
end;
$$;

create or replace function public.record_manual_payment(
  p_folio_id uuid,
  p_amount numeric,
  p_provider public.payment_provider,
  p_provider_reference text default null,
  p_notes text default null,
  p_idempotency_key text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_folio record;
  v_payment_id uuid;
  v_reference text;
  v_receipt_number text;
  v_key text;
  v_cash_code text;
  v_balance numeric(14,2);
begin
  perform private.rpc_require_any_permission(array['payment.cash', 'payment.pos']);
  if p_provider not in ('cash', 'pos') then
    raise exception 'manual payment provider must be cash or pos' using errcode = '22023';
  end if;
  if p_amount is null or p_amount <= 0 then
    raise exception 'payment amount must be positive' using errcode = '22023';
  end if;

  select f.* into v_folio from public.folios f where f.id = p_folio_id for update;
  if not found then
    raise exception 'folio not found' using errcode = '22023';
  end if;
  if v_folio.status not in ('open', 'closed_with_balance') then
    raise exception 'folio % does not accept payments', p_folio_id using errcode = '23514';
  end if;

  v_key := coalesce(p_idempotency_key, 'manual:' || p_provider || ':' || coalesce(p_provider_reference, p_folio_id::text) || ':' || p_amount::text);
  select id into v_payment_id from public.payments where idempotency_key = v_key;
  if found then
    return v_payment_id;
  end if;

  v_balance := public.folio_balance(v_folio.id);
  if v_balance <= 0 then
    raise exception 'folio % has no outstanding balance', v_folio.id using errcode = '23514';
  end if;
  if p_amount > v_balance then
    raise exception 'payment amount % exceeds folio balance %', p_amount, v_balance using errcode = '23514';
  end if;

  v_reference := public.allocate_reference('payment', 'PAY');
  v_receipt_number := public.allocate_reference('receipt', 'RCP');
  v_cash_code := case p_provider when 'cash' then '1000' else '1030' end;

  insert into public.payments (
    reference, hotel_id, folio_id, reservation_id, provider, provider_reference,
    amount, currency, status, paid_at, recorded_by, receipt_number,
    idempotency_key, internal_notes
  )
  values (
    v_reference, v_folio.hotel_id, v_folio.id, v_folio.reservation_id, p_provider,
    p_provider_reference, p_amount, v_folio.currency, 'successful', now(),
    private.rpc_actor_profile_id(), v_receipt_number, v_key, p_notes
  )
  returning id into v_payment_id;

  insert into public.receipts (payment_id, receipt_number, issued_to_snapshot, issued_by)
  values (v_payment_id, v_receipt_number, jsonb_build_object('folio_id', v_folio.id), private.rpc_actor_profile_id());

  perform private.post_ledger(
    v_folio.hotel_id,
    'payment',
    'payment',
    v_payment_id,
    coalesce(p_notes, p_provider || ' payment'),
    'payment-ledger:' || v_key,
    jsonb_build_array(
      jsonb_build_object('code', v_cash_code, 'debit', p_amount::text),
      jsonb_build_object('code', '1100', 'credit', p_amount::text)
    ),
    null,
    v_folio.guest_id,
    v_folio.id
  );

  if v_folio.status = 'closed_with_balance' and public.folio_balance(v_folio.id) <= 0 then
    update public.folios
    set status = 'closed_paid',
        closed_at = now()
    where id = v_folio.id;
  end if;

  if v_folio.reservation_id is not null then
    update public.reservations
    set payment_status = case when public.folio_balance(v_folio.id) <= 0 then 'paid'::public.reservation_payment_status else 'partially_paid'::public.reservation_payment_status end
    where id = v_folio.reservation_id;
  end if;

  return v_payment_id;
end;
$$;

create or replace function public.verify_bank_transfer(
  p_payment_id uuid,
  p_action public.payment_verification_action,
  p_notes text default null,
  p_bank_reference text default null
)
returns void
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_payment record;
  v_checker_staff_id uuid := private.current_staff_id();
  v_checker_profile_id uuid := private.rpc_actor_profile_id();
  v_folio record;
  v_receipt_number text;
  v_balance numeric(14,2);
begin
  perform private.rpc_require_permission('payment.transfer.verify');
  if v_checker_staff_id is null then
    raise exception 'active staff profile required' using errcode = '42501';
  end if;
  if p_action = 'reject' and (p_notes is null or btrim(p_notes) = '') then
    raise exception 'rejection notes are required' using errcode = '22023';
  end if;

  select p.* into v_payment
  from public.payments p
  where p.id = p_payment_id and p.provider = 'bank_transfer'
  for update;
  if not found then
    raise exception 'bank transfer payment not found' using errcode = '22023';
  end if;
  if v_payment.status <> 'pending_verification' then
    raise exception 'payment status % cannot be verified', v_payment.status using errcode = '23514';
  end if;
  if v_payment.recorded_by = v_checker_profile_id then
    raise exception 'submitter cannot verify own bank transfer' using errcode = '42501';
  end if;

  insert into public.payment_verifications (payment_id, action, checker_id, notes, bank_reference)
  values (p_payment_id, p_action, v_checker_staff_id, p_notes, p_bank_reference);

  if p_action = 'reject' then
    update public.payments
    set status = 'rejected', internal_notes = concat_ws(' | ', internal_notes, p_notes)
    where id = p_payment_id;
    return;
  end if;

  select f.* into v_folio from public.folios f where f.id = v_payment.folio_id;
  if v_folio.status not in ('open', 'closed_with_balance') then
    raise exception 'folio % does not accept payments', v_folio.id using errcode = '23514';
  end if;
  v_balance := public.folio_balance(v_folio.id);
  if v_balance <= 0 then
    raise exception 'folio % has no outstanding balance', v_folio.id using errcode = '23514';
  end if;
  if v_payment.amount > v_balance then
    raise exception 'transfer amount % exceeds folio balance %', v_payment.amount, v_balance using errcode = '23514';
  end if;
  v_receipt_number := public.allocate_reference('receipt', 'RCP');

  update public.payments
  set status = 'successful',
      paid_at = now(),
      verified_by = v_checker_profile_id,
      verified_at = now(),
      receipt_number = v_receipt_number
  where id = p_payment_id;

  insert into public.receipts (payment_id, receipt_number, issued_to_snapshot, issued_by)
  values (p_payment_id, v_receipt_number, jsonb_build_object('folio_id', v_folio.id), v_checker_profile_id);

  perform private.post_ledger(
    v_folio.hotel_id,
    'payment',
    'payment',
    p_payment_id,
    'bank transfer verification',
    'payment-ledger:' || v_payment.idempotency_key,
    jsonb_build_array(
      jsonb_build_object('code', '1010', 'debit', v_payment.amount::text),
      jsonb_build_object('code', '1100', 'credit', v_payment.amount::text)
    ),
    null,
    v_folio.guest_id,
    v_folio.id
  );

  if v_folio.status = 'closed_with_balance' and public.folio_balance(v_folio.id) <= 0 then
    update public.folios
    set status = 'closed_paid',
        closed_at = now()
    where id = v_folio.id;
  end if;

  if v_folio.reservation_id is not null then
    update public.reservations
    set payment_status = case when public.folio_balance(v_folio.id) <= 0 then 'paid'::public.reservation_payment_status else 'partially_paid'::public.reservation_payment_status end
    where id = v_folio.reservation_id;
  end if;
end;
$$;

create or replace function public.submit_bank_transfer(
  p_folio_id uuid,
  p_amount numeric,
  p_bank_reference text,
  p_notes text default null,
  p_idempotency_key text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_folio record;
  v_payment_id uuid;
  v_reference text;
  v_key text;
  v_balance numeric(14,2);
begin
  perform private.rpc_require_permission('payment.transfer.submit');
  if p_amount is null or p_amount <= 0 then
    raise exception 'payment amount must be positive' using errcode = '22023';
  end if;
  if p_bank_reference is null or btrim(p_bank_reference) = '' then
    raise exception 'bank reference is required' using errcode = '22023';
  end if;

  select f.* into v_folio from public.folios f where f.id = p_folio_id for update;
  if not found then
    raise exception 'folio not found' using errcode = '22023';
  end if;
  if v_folio.status not in ('open', 'closed_with_balance') then
    raise exception 'folio % does not accept payments', p_folio_id using errcode = '23514';
  end if;

  v_key := coalesce(p_idempotency_key, 'bank:' || p_bank_reference);
  select id into v_payment_id from public.payments where idempotency_key = v_key;
  if found then
    return v_payment_id;
  end if;

  v_balance := public.folio_balance(v_folio.id);
  if v_balance <= 0 then
    raise exception 'folio % has no outstanding balance', v_folio.id using errcode = '23514';
  end if;
  if p_amount > v_balance then
    raise exception 'payment amount % exceeds folio balance %', p_amount, v_balance using errcode = '23514';
  end if;

  v_reference := public.allocate_reference('payment', 'PAY');
  insert into public.payments (
    reference, hotel_id, folio_id, reservation_id, provider, provider_reference,
    amount, currency, status, recorded_by, idempotency_key, internal_notes
  )
  values (
    v_reference, v_folio.hotel_id, v_folio.id, v_folio.reservation_id, 'bank_transfer',
    'BANK:' || p_bank_reference, p_amount, v_folio.currency, 'pending_verification',
    private.rpc_actor_profile_id(), v_key, p_notes
  )
  returning id into v_payment_id;

  return v_payment_id;
end;
$$;

create or replace function public.confirm_paystack_payment(
  p_provider_reference text,
  p_amount numeric,
  p_event_id text,
  p_currency text default 'NGN'
)
returns uuid
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_payment record;
  v_folio record;
  v_reservation record;
  v_event_id uuid;
  v_existing_payment_id uuid;
  v_receipt_number text;
  v_balance numeric(14,2);
begin
  if not private.rpc_is_service_role() then
    raise exception 'paystack confirmation is server-only' using errcode = '42501';
  end if;
  if p_amount is null or p_amount <= 0 then
    raise exception 'payment amount must be positive' using errcode = '22023';
  end if;

  insert into public.payment_gateway_events (
    provider, provider_event_id, event_type, payload, signature_valid, processing_status
  )
  values ('paystack', p_event_id, 'charge.success', jsonb_build_object('reference', p_provider_reference, 'amount', p_amount, 'currency', p_currency), true, 'received')
  on conflict (provider_event_id) do nothing
  returning id into v_event_id;

  if v_event_id is null then
    select payment_id into v_existing_payment_id
    from public.payment_gateway_events
    where provider_event_id = p_event_id;
    return v_existing_payment_id;
  end if;

  select p.* into v_payment
  from public.payments p
  where p.provider = 'paystack' and p.provider_reference = p_provider_reference
  for update;

  if not found then
    insert into public.payment_exceptions (hotel_id, gateway_event_id, type, notes)
    values (private.current_hotel_id(), v_event_id, 'unknown_payment', 'unknown provider reference: ' || p_provider_reference);
    update public.payment_gateway_events
    set processing_status = 'failed', error = 'unknown payment reference'
    where id = v_event_id;
    return null;
  end if;

  if v_payment.amount <> p_amount then
    update public.payment_gateway_events
    set processing_status = 'failed', error = 'amount mismatch', payment_id = v_payment.id
    where id = v_event_id;
    insert into public.payment_exceptions (hotel_id, payment_id, gateway_event_id, type, notes)
    values (v_payment.hotel_id, v_payment.id, v_event_id, 'amount_mismatch', 'gateway amount differs from payment');
    return null;
  end if;

  if upper(v_payment.currency) <> upper(p_currency) then
    update public.payment_gateway_events
    set processing_status = 'failed', error = 'currency mismatch', payment_id = v_payment.id
    where id = v_event_id;
    insert into public.payment_exceptions (hotel_id, payment_id, gateway_event_id, type, notes)
    values (v_payment.hotel_id, v_payment.id, v_event_id, 'currency_mismatch', 'gateway currency differs from payment');
    return null;
  end if;

  if v_payment.reservation_id is not null then
    select r.* into v_reservation from public.reservations r where r.id = v_payment.reservation_id;
    if v_reservation.status in ('expired', 'cancelled', 'no_show') then
      insert into public.payment_exceptions (hotel_id, payment_id, gateway_event_id, type, notes)
      values (v_payment.hotel_id, v_payment.id, v_event_id, 'late_success', 'success event for inactive reservation: ' || v_reservation.status);
      update public.payment_gateway_events
      set processing_status = 'failed', error = 'late success for inactive reservation', payment_id = v_payment.id
      where id = v_event_id;
      return null;
    end if;
  end if;

  if v_payment.status = 'successful' then
    update public.payment_gateway_events
    set processing_status = 'duplicate', payment_id = v_payment.id
    where id = v_event_id;
    return v_payment.id;
  end if;

  select f.* into v_folio from public.folios f where f.id = v_payment.folio_id;
  if v_folio.status not in ('open', 'closed_with_balance') then
    update public.payment_gateway_events
    set processing_status = 'failed', error = 'folio does not accept payments', payment_id = v_payment.id
    where id = v_event_id;
    return null;
  end if;
  v_balance := public.folio_balance(v_folio.id);
  if v_balance <= 0 or p_amount > v_balance then
    update public.payment_gateway_events
    set processing_status = 'failed', error = 'overpayment or no outstanding balance', payment_id = v_payment.id
    where id = v_event_id;
    insert into public.payment_exceptions (hotel_id, payment_id, gateway_event_id, type, notes)
    values (v_folio.hotel_id, v_payment.id, v_event_id, 'overpayment', 'gateway amount exceeds outstanding folio balance');
    return null;
  end if;
  v_receipt_number := public.allocate_reference('receipt', 'RCP');

  update public.payments
  set status = 'successful',
      paid_at = now(),
      receipt_number = v_receipt_number
  where id = v_payment.id;

  insert into public.receipts (payment_id, receipt_number, issued_to_snapshot, issued_by)
  values (v_payment.id, v_receipt_number, jsonb_build_object('folio_id', v_folio.id), null);

  perform private.post_ledger(
    v_folio.hotel_id,
    'payment',
    'payment',
    v_payment.id,
    'paystack charge.success',
    'payment-ledger:' || v_payment.idempotency_key,
    jsonb_build_array(
      jsonb_build_object('code', '1020', 'debit', p_amount::text),
      jsonb_build_object('code', '1100', 'credit', p_amount::text)
    ),
    null,
    v_folio.guest_id,
    v_folio.id
  );

  update public.payment_gateway_events
  set processing_status = 'posted', payment_id = v_payment.id
  where id = v_event_id;

  if v_folio.status = 'closed_with_balance' and public.folio_balance(v_folio.id) <= 0 then
    update public.folios
    set status = 'closed_paid',
        closed_at = now()
    where id = v_folio.id;
  end if;

  if v_folio.reservation_id is not null then
    update public.reservations
    set payment_status = case when public.folio_balance(v_folio.id) <= 0 then 'paid'::public.reservation_payment_status else 'partially_paid'::public.reservation_payment_status end
    where id = v_folio.reservation_id;
  end if;

  return v_payment.id;
end;
$$;

create or replace function public.approve_refund(p_refund_id uuid)
returns void
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_refund record;
  v_payment record;
  v_folio record;
  v_cash_code text;
  v_status public.payment_status;
begin
  perform private.rpc_require_permission('refund.approve');

  select r.* into v_refund from public.refunds r where r.id = p_refund_id for update;
  if not found then
    raise exception 'refund not found' using errcode = '22023';
  end if;
  if v_refund.status <> 'pending' then
    raise exception 'refund status % cannot be approved', v_refund.status using errcode = '23514';
  end if;
  if v_refund.requested_by is not null and v_refund.requested_by = private.rpc_actor_profile_id() then
    raise exception 'refund requester cannot be sole approver' using errcode = '42501';
  end if;

  select p.* into v_payment from public.payments p where p.id = v_refund.payment_id for update;
  select f.* into v_folio from public.folios f where f.id = v_refund.folio_id;

  update public.refunds
  set status = 'completed',
      approved_by = private.rpc_actor_profile_id(),
      processed_at = now()
  where id = p_refund_id;

  v_cash_code := case v_payment.provider
    when 'paystack' then '1020'
    when 'pos' then '1030'
    when 'bank_transfer' then '1010'
    else '1000'
  end;

  perform private.post_ledger(
    v_folio.hotel_id,
    'refund',
    'refund',
    p_refund_id,
    v_refund.reason,
    'refund-ledger:' || p_refund_id::text,
    jsonb_build_array(
      jsonb_build_object('code', '2200', 'debit', v_refund.amount::text),
      jsonb_build_object('code', v_cash_code, 'credit', v_refund.amount::text)
    ),
    null,
    v_folio.guest_id,
    v_folio.id
  );

  select case
    when coalesce((select sum(amount) from public.refunds where payment_id = v_payment.id and status = 'completed'), 0) >= v_payment.amount then 'refunded'::public.payment_status
    else 'partially_refunded'::public.payment_status
  end into v_status;

  update public.payments set status = v_status where id = v_payment.id;
end;
$$;

create or replace function public.request_refund(
  p_payment_id uuid,
  p_amount numeric,
  p_reason text
)
returns uuid
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_payment record;
  v_refund_id uuid;
  v_refunded numeric(14,2);
begin
  if not private.rpc_is_service_role() then
    if not private.has_permission('refund.approve')
       and not (
         private.rpc_has_role_permission('refund.request')
         and private.guest_owns_payment(p_payment_id)
       ) then
      raise exception 'not allowed to request refund' using errcode = '42501';
    end if;
  end if;
  if p_amount is null or p_amount <= 0 then
    raise exception 'refund amount must be positive' using errcode = '22023';
  end if;
  if p_reason is null or btrim(p_reason) = '' then
    raise exception 'refund reason is required' using errcode = '22023';
  end if;

  select * into v_payment from public.payments where id = p_payment_id and status in ('successful', 'partially_refunded') for update;
  if not found then
    raise exception 'successful payment not found' using errcode = '22023';
  end if;

  select coalesce(sum(amount), 0) into v_refunded
  from public.refunds
  where payment_id = p_payment_id and status in ('pending', 'approved', 'processing', 'completed');
  if v_refunded + p_amount > v_payment.amount then
    raise exception 'refund amount exceeds unrefunded payment balance' using errcode = '23514';
  end if;

  insert into public.refunds (payment_id, folio_id, amount, reason, status, requested_by)
  values (p_payment_id, v_payment.folio_id, p_amount, p_reason, 'pending', private.rpc_actor_profile_id())
  returning id into v_refund_id;

  return v_refund_id;
end;
$$;

drop policy if exists manager_insert_payment_verifications on public.payment_verifications;
drop policy if exists accountant_insert_payment_verifications on public.payment_verifications;

create policy manager_insert_payment_verifications on public.payment_verifications for insert to authenticated with check (
  private.has_permission('payment.transfer.verify')
  and checker_id = private.current_staff_id()
  and not exists (
    select 1
    from public.payments p
    join public.staff_profiles sp on sp.profile_id = p.recorded_by
    where p.id = payment_id and sp.id = checker_id
  )
);

create policy accountant_insert_payment_verifications on public.payment_verifications for insert to authenticated with check (
  private.has_permission('payment.transfer.verify')
  and checker_id = private.current_staff_id()
  and not exists (
    select 1
    from public.payments p
    join public.staff_profiles sp on sp.profile_id = p.recorded_by
    where p.id = payment_id and sp.id = checker_id
  )
);

revoke all on function public.confirm_reservation(uuid, boolean) from public, anon;
grant execute on function public.confirm_reservation(uuid, boolean) to authenticated, service_role;
