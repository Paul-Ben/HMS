create or replace function private.rpc_is_service_role()
returns boolean
language sql
stable
set search_path = public, private, pg_temp
as $$
  select coalesce(
    nullif(current_setting('request.jwt.claim.role', true), ''),
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role'
  ) = 'service_role';
$$;

create or replace function private.rpc_actor_profile_id()
returns uuid
language sql
stable
set search_path = public, private, pg_temp
as $$
  select auth.uid();
$$;

create or replace function private.rpc_require_any_permission(p_keys text[])
returns void
language plpgsql
stable
set search_path = public, private, pg_temp
as $$
declare
  v_key text;
begin
  if private.rpc_is_service_role() then
    return;
  end if;

  foreach v_key in array p_keys loop
    if private.has_permission(v_key) then
      return;
    end if;
  end loop;

  raise exception 'missing required permission: %', array_to_string(p_keys, ', ') using errcode = '42501';
end;
$$;

create or replace function private.rpc_require_permission(p_key text)
returns void
language plpgsql
stable
set search_path = public, private, pg_temp
as $$
begin
  perform private.rpc_require_any_permission(array[p_key]);
end;
$$;

create or replace function private.rpc_hotel_id(p_hotel_id uuid)
returns uuid
language sql
stable
set search_path = public, private, pg_temp
as $$
  select coalesce(p_hotel_id, private.current_hotel_id());
$$;

create or replace function private.rpc_account_id(p_hotel_id uuid, p_code text)
returns uuid
language sql
stable
set search_path = public, private, pg_temp
as $$
  select id from public.financial_accounts where hotel_id = p_hotel_id and code = p_code and is_active;
$$;

create or replace function private.post_ledger(
  p_hotel_id uuid,
  p_type public.financial_transaction_type,
  p_source_type text,
  p_source_id uuid,
  p_memo text,
  p_idempotency_key text,
  p_lines jsonb,
  p_department_id uuid default null,
  p_guest_id uuid default null,
  p_folio_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_transaction_id uuid;
  v_line jsonb;
  v_account_id uuid;
begin
  insert into public.financial_transactions (
    hotel_id, type, source_type, source_id, idempotency_key,
    occurred_at, posted_at, posted_by, status, memo
  )
  values (
    p_hotel_id, p_type, p_source_type, p_source_id, p_idempotency_key,
    now(), now(), private.rpc_actor_profile_id(), 'posted', p_memo
  )
  on conflict (idempotency_key) do nothing
  returning id into v_transaction_id;

  if v_transaction_id is null then
    select id into v_transaction_id
    from public.financial_transactions
    where idempotency_key = p_idempotency_key;
    return v_transaction_id;
  end if;

  for v_line in select value from jsonb_array_elements(p_lines) loop
    v_account_id := private.rpc_account_id(p_hotel_id, v_line ->> 'code');
    if v_account_id is null then
      raise exception 'unknown financial account code: %', v_line ->> 'code' using errcode = '22023';
    end if;

    insert into public.financial_transaction_lines (
      financial_transaction_id, account_id, debit, credit,
      department_id, guest_id, folio_id, memo
    )
    values (
      v_transaction_id,
      v_account_id,
      nullif(v_line ->> 'debit', '')::numeric,
      nullif(v_line ->> 'credit', '')::numeric,
      p_department_id,
      p_guest_id,
      p_folio_id,
      coalesce(v_line ->> 'memo', p_memo)
    );
  end loop;

  return v_transaction_id;
end;
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
  v_settings record;
  v_reservation_id uuid;
  v_folio_id uuid;
  v_reference text;
  v_folio_number text;
  v_room_subtotal numeric(14,2);
  v_tax numeric(14,2);
  v_total numeric(14,2);
  v_deposit numeric(14,2);
  v_nights integer;
  v_source public.reservation_source;
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

  reservation_id := v_reservation_id;
  folio_id := v_folio_id;
  reference := v_reference;
  required_deposit := v_deposit;
  return next;
end;
$$;

create or replace function public.modify_reservation(
  p_reservation_id uuid,
  p_room_id uuid default null,
  p_check_in date default null,
  p_check_out date default null,
  p_adults integer default null,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_reservation record;
  v_room record;
  v_room_id uuid;
  v_check_in date;
  v_check_out date;
  v_adults integer;
  v_room_subtotal numeric(14,2);
  v_tax numeric(14,2);
  v_total numeric(14,2);
  v_deposit numeric(14,2);
  v_nights integer;
begin
  if not private.rpc_is_service_role() then
    if not private.has_permission('reservation.update')
       and not private.guest_owns_reservation(p_reservation_id) then
      raise exception 'not allowed to modify reservation' using errcode = '42501';
    end if;
  end if;

  select * into v_reservation from public.reservations where id = p_reservation_id for update;
  if not found then
    raise exception 'reservation not found' using errcode = '22023';
  end if;
  if v_reservation.status not in ('pending', 'confirmed') then
    raise exception 'reservation status % cannot be modified', v_reservation.status using errcode = '23514';
  end if;

  v_check_in := coalesce(p_check_in, v_reservation.check_in);
  v_check_out := coalesce(p_check_out, v_reservation.check_out);
  v_adults := coalesce(p_adults, v_reservation.adults);
  if v_check_out <= v_check_in then
    raise exception 'check_out must be after check_in' using errcode = '22023';
  end if;
  if v_adults < 1 then
    raise exception 'adults must be at least 1' using errcode = '22023';
  end if;

  if p_room_id is null then
    select rra.room_id into v_room_id
    from public.reservation_room_assignments rra
    where rra.reservation_id = p_reservation_id and rra.is_primary
    limit 1;
  else
    v_room_id := p_room_id;
  end if;

  select r.id, r.hotel_id,
         coalesce(r.rate_override, rc.base_rate)::numeric(14,2) as nightly_rate,
         hs.tax_rate, bs.deposit_percentage
  into v_room
  from public.rooms r
  join public.room_categories rc on rc.id = r.category_id
  join public.hotel_settings hs on hs.hotel_id = r.hotel_id
  join public.booking_settings bs on bs.hotel_id = r.hotel_id
  where r.id = v_room_id and r.hotel_id = v_reservation.hotel_id
    and r.is_active and r.operational_status = 'available' and v_adults <= r.max_occupancy;
  if not found then
    raise exception 'room is not available' using errcode = '23514';
  end if;

  delete from public.room_allocation_holds where reservation_id = p_reservation_id;

  begin
    insert into public.room_allocation_holds (reservation_id, room_id, check_in, check_out)
    values (p_reservation_id, v_room_id, v_check_in, v_check_out);
  exception
    when exclusion_violation then
      raise exception 'room no longer available' using errcode = '23P01';
  end;

  v_nights := v_check_out - v_check_in;
  v_room_subtotal := round(v_room.nightly_rate * v_nights, 2);
  v_tax := round(v_room_subtotal * v_room.tax_rate / 100, 2);
  v_total := v_room_subtotal + v_tax;
  v_deposit := round(v_total * v_room.deposit_percentage / 100, 2);

  update public.reservations
  set check_in = v_check_in,
      check_out = v_check_out,
      adults = v_adults,
      room_subtotal = v_room_subtotal,
      tax = v_tax,
      accommodation_total = v_total,
      required_deposit = v_deposit,
      internal_notes = case when p_reason is null then internal_notes else concat_ws(' | ', internal_notes, p_reason) end
  where id = p_reservation_id;

  update public.reservation_room_assignments
  set room_id = v_room_id,
      nightly_rate = v_room.nightly_rate,
      check_in = v_check_in,
      check_out = v_check_out,
      occupancy = v_adults
  where reservation_id = p_reservation_id and is_primary;
end;
$$;

create or replace function public.cancel_reservation(
  p_reservation_id uuid,
  p_reason text,
  p_charge_fee boolean default true
)
returns void
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_reservation record;
  v_policy record;
  v_fee numeric(14,2) := 0;
  v_rate numeric(14,2);
begin
  if not private.rpc_is_service_role() then
    if not private.has_permission('reservation.cancel')
       and not private.guest_owns_reservation(p_reservation_id) then
      raise exception 'not allowed to cancel reservation' using errcode = '42501';
    end if;
  end if;
  if p_reason is null or btrim(p_reason) = '' then
    raise exception 'cancellation reason is required' using errcode = '22023';
  end if;

  select r.*, rra.nightly_rate
  into v_reservation
  from public.reservations r
  left join public.reservation_room_assignments rra on rra.reservation_id = r.id and rra.is_primary
  where r.id = p_reservation_id
  for update;
  if not found then
    raise exception 'reservation not found' using errcode = '22023';
  end if;
  if v_reservation.status not in ('pending', 'confirmed') then
    raise exception 'reservation status % cannot be cancelled', v_reservation.status using errcode = '23514';
  end if;

  select cp.* into v_policy
  from public.cancellation_policies cp
  where cp.id = v_reservation.cancellation_policy_id;
  v_rate := coalesce(v_reservation.nightly_rate, 0);

  if p_charge_fee and v_policy.id is not null
     and now() >= (v_reservation.check_in::timestamp - (v_policy.free_cancellation_hours || ' hours')::interval) then
    if v_policy.charge_type = 'fixed' then
      v_fee := coalesce(v_policy.charge_value, 0);
    elsif v_policy.charge_type = 'percentage' then
      v_fee := round(v_reservation.accommodation_total * coalesce(v_policy.charge_value, 0) / 100, 2);
    elsif v_policy.charge_type = 'first_night' then
      v_fee := v_rate;
    end if;
  end if;

  update public.reservations
  set status = 'cancelled',
      cancelled_at = now(),
      cancelled_by = private.rpc_actor_profile_id(),
      cancellation_reason = p_reason,
      cancellation_fee = v_fee
  where id = p_reservation_id;

  delete from public.room_allocation_holds where reservation_id = p_reservation_id;
  update public.payments
  set status = 'failed'
  where reservation_id = p_reservation_id and status = 'pending';
end;
$$;

create or replace function public.expire_holds(p_limit integer default 100)
returns integer
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_reservation record;
  v_count integer := 0;
begin
  if not private.rpc_is_service_role() then
    perform private.rpc_require_permission('reservation.expire');
  end if;

  for v_reservation in
    select id
    from public.reservations
    where status = 'pending'
      and hold_expires_at is not null
      and hold_expires_at <= now()
    order by hold_expires_at
    limit greatest(1, least(coalesce(p_limit, 100), 1000))
    for update skip locked
  loop
    update public.reservations
    set status = 'expired',
        cancellation_reason = 'hold expired'
    where id = v_reservation.id;

    delete from public.room_allocation_holds where reservation_id = v_reservation.id;
    update public.payments
    set status = 'failed'
    where reservation_id = v_reservation.id and status = 'pending';
    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$$;

create or replace function public.check_in_reservation(
  p_reservation_id uuid,
  p_room_id uuid default null
)
returns void
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_reservation record;
  v_room_id uuid;
begin
  perform private.rpc_require_permission('reservation.checkin');

  select * into v_reservation from public.reservations where id = p_reservation_id for update;
  if not found then
    raise exception 'reservation not found' using errcode = '22023';
  end if;
  if v_reservation.status <> 'confirmed' then
    raise exception 'reservation status % cannot check in', v_reservation.status using errcode = '23514';
  end if;

  if p_room_id is not null then
    v_room_id := p_room_id;
  else
    select rra.room_id into v_room_id
    from public.reservation_room_assignments rra
    where rra.reservation_id = p_reservation_id and rra.is_primary
    limit 1;
  end if;

  if not exists (
    select 1 from public.rooms r
    where r.id = v_room_id
      and r.hotel_id = v_reservation.hotel_id
      and r.operational_status = 'available'
      and r.housekeeping_status = 'clean'
  ) then
    raise exception 'room is not ready for check-in' using errcode = '23514';
  end if;

  update public.reservations set status = 'checked_in' where id = p_reservation_id;
  update public.rooms
  set operational_status = 'occupied'
  where id = v_room_id;

  update public.reservation_room_assignments
  set is_primary = (room_id = v_room_id)
  where reservation_id = p_reservation_id;
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
  set status = case when v_balance > 0 then 'closed_with_balance' else 'closed_paid' end,
      closed_at = now()
  where id = v_folio.id;

  update public.reservations set status = 'checked_out' where id = p_reservation_id;

  if v_room_id is not null then
    update public.rooms
    set operational_status = 'available',
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

create or replace function public.folio_balance(p_folio_id uuid)
returns numeric(14,2)
language sql
stable
security definer
set search_path = public, private, extensions, pg_temp
as $$
  select coalesce((
    select coalesce(sum(case when not bi.is_void then bi.total else 0 end), 0)
    from public.bill_items bi
    where bi.folio_id = p_folio_id
  ), 0)
  + coalesce((
    select coalesce(sum(case when fa.type = 'charge' then fa.amount else -fa.amount end), 0)
    from public.financial_adjustments fa
    where fa.folio_id = p_folio_id and fa.status = 'posted'
  ), 0)
  - coalesce((
    select coalesce(sum(p.amount), 0)
    from public.payments p
    where p.folio_id = p_folio_id and p.status = 'successful'
  ), 0)
  + coalesce((
    select coalesce(sum(rf.amount), 0)
    from public.refunds rf
    where rf.folio_id = p_folio_id and rf.status = 'completed'
  ), 0);
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
  v_payment_id uuid;
begin
  perform private.rpc_require_any_permission(array['folio.charge', 'order.create']);

  if p_quantity is null or p_quantity <= 0 then
    raise exception 'quantity must be positive' using errcode = '22023';
  end if;
  if p_unit_price is null or p_unit_price < 0 then
    raise exception 'unit price cannot be negative' using errcode = '22023';
  end if;

  select f.* into v_folio from public.folios f where f.id = p_folio_id for update;
  if not found then
    raise exception 'folio not found' using errcode = '22023';
  end if;
  if v_folio.status in ('closed_paid', 'void', 'written_off') then
    raise exception 'folio % does not accept charges', p_folio_id using errcode = '23514';
  end if;

  if p_idempotency_key is not null then
    select bi.id into v_item_id
    from public.bill_items bi
    where bi.source_type = p_source_type
      and bi.source_id = p_source_id
      and bi.description = p_description
    limit 1;
    if found then
      return v_item_id;
    end if;
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

  perform private.post_ledger(
    v_folio.hotel_id,
    'charge',
    coalesce(p_source_type, 'bill_item'),
    v_item_id,
    coalesce(p_description, 'folio charge'),
    coalesce(p_idempotency_key, 'bill-item:' || v_item_id::text),
    jsonb_build_array(
      jsonb_build_object('code', '1100', 'debit', v_total::text),
      jsonb_build_object('code', v_revenue_code, 'credit', (v_subtotal - coalesce(p_discount, 0))::text),
      jsonb_build_object('code', '2100', 'credit', v_tax::text)
    ),
    p_department_id,
    v_folio.guest_id,
    p_folio_id
  );

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

  v_key := coalesce(p_idempotency_key, 'manual:' || p_provider || ':' || coalesce(p_provider_reference, p_folio_id::text) || ':' || p_amount::text);
  select id into v_payment_id from public.payments where idempotency_key = v_key;
  if found then
    return v_payment_id;
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

  update public.folios
  set status = case when public.folio_balance(v_folio.id) <= 0 then 'closed_paid' else 'closed_with_balance' end,
      closed_at = case when public.folio_balance(v_folio.id) <= 0 then now() else closed_at end
  where id = v_folio.id;

  if v_folio.reservation_id is not null then
    update public.reservations
    set payment_status = case when public.folio_balance(v_folio.id) <= 0 then 'paid' else 'partially_paid' end
    where id = v_folio.reservation_id;
  end if;

  return v_payment_id;
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
begin
  perform private.rpc_require_permission('payment.transfer.submit');
  if p_amount is null or p_amount <= 0 then
    raise exception 'payment amount must be positive' using errcode = '22023';
  end if;
  if p_bank_reference is null or btrim(p_bank_reference) = '' then
    raise exception 'bank reference is required' using errcode = '22023';
  end if;

  select f.* into v_folio from public.folios f where f.id = p_folio_id;
  if not found then
    raise exception 'folio not found' using errcode = '22023';
  end if;

  v_key := coalesce(p_idempotency_key, 'bank:' || p_bank_reference);
  select id into v_payment_id from public.payments where idempotency_key = v_key;
  if found then
    return v_payment_id;
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
  v_checker_profile_id uuid;
  v_folio record;
  v_receipt_number text;
begin
  perform private.rpc_require_permission('payment.transfer.verify');
  if v_checker_staff_id is null then
    raise exception 'active staff profile required' using errcode = '42501';
  end if;
  if p_action = 'reject' and (p_notes is null or btrim(p_notes) = '') then
    raise exception 'rejection notes are required' using errcode = '22023';
  end if;

  select p.*, sp.profile_id as recorded_by_profile_id
  into v_payment
  from public.payments p
  left join public.staff_profiles sp on sp.id = p.recorded_by
  where p.id = p_payment_id and p.provider = 'bank_transfer'
  for update;
  if not found then
    raise exception 'bank transfer payment not found' using errcode = '22023';
  end if;
  if v_payment.status <> 'pending_verification' then
    raise exception 'payment status % cannot be verified', v_payment.status using errcode = '23514';
  end if;

  select sp.profile_id into v_checker_profile_id
  from public.staff_profiles sp
  where sp.id = v_checker_staff_id;
  if v_checker_profile_id = v_payment.recorded_by_profile_id then
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
  v_receipt_number := public.allocate_reference('receipt', 'RCP');

  update public.payments
  set status = 'successful',
      paid_at = now(),
      verified_by = private.rpc_actor_profile_id(),
      verified_at = now(),
      receipt_number = v_receipt_number
  where id = p_payment_id;

  insert into public.receipts (payment_id, receipt_number, issued_to_snapshot, issued_by)
  values (p_payment_id, v_receipt_number, jsonb_build_object('folio_id', v_folio.id), private.rpc_actor_profile_id());

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

  update public.folios
  set status = case when public.folio_balance(v_folio.id) <= 0 then 'closed_paid' else 'closed_with_balance' end,
      closed_at = case when public.folio_balance(v_folio.id) <= 0 then now() else closed_at end
  where id = v_folio.id;

  if v_folio.reservation_id is not null then
    update public.reservations
    set payment_status = case when public.folio_balance(v_folio.id) <= 0 then 'paid' else 'partially_paid' end
    where id = v_folio.reservation_id;
  end if;
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
  v_event_id uuid;
  v_existing_payment_id uuid;
  v_receipt_number text;
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
    raise exception 'unknown payment reference' using errcode = '22023';
  end if;

  if v_payment.amount <> p_amount then
    update public.payment_gateway_events
    set processing_status = 'failed', error = 'amount mismatch'
    where id = v_event_id;
    insert into public.payment_exceptions (hotel_id, payment_id, gateway_event_id, type, notes)
    values (v_payment.hotel_id, v_payment.id, v_event_id, 'amount_mismatch', 'gateway amount differs from payment');
    raise exception 'payment amount mismatch' using errcode = '22023';
  end if;

  if upper(v_payment.currency) <> upper(p_currency) then
    update public.payment_gateway_events
    set processing_status = 'failed', error = 'currency mismatch'
    where id = v_event_id;
    insert into public.payment_exceptions (hotel_id, payment_id, gateway_event_id, type, notes)
    values (v_payment.hotel_id, v_payment.id, v_event_id, 'currency_mismatch', 'gateway currency differs from payment');
    raise exception 'payment currency mismatch' using errcode = '22023';
  end if;

  if v_payment.status = 'successful' then
    update public.payment_gateway_events
    set processing_status = 'duplicate', payment_id = v_payment.id
    where id = v_event_id;
    return v_payment.id;
  end if;

  select f.* into v_folio from public.folios f where f.id = v_payment.folio_id;
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

  update public.folios
  set status = case when public.folio_balance(v_folio.id) <= 0 then 'closed_paid' else 'closed_with_balance' end,
      closed_at = case when public.folio_balance(v_folio.id) <= 0 then now() else closed_at end
  where id = v_folio.id;

  if v_folio.reservation_id is not null then
    update public.reservations
    set payment_status = case when public.folio_balance(v_folio.id) <= 0 then 'paid' else 'partially_paid' end
    where id = v_folio.reservation_id;
  end if;

  return v_payment.id;
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
  perform private.rpc_require_any_permission(array['refund.request', 'refund.approve']);
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
  v_status public.reservation_payment_status;
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
    when coalesce((select sum(amount) from public.refunds where payment_id = v_payment.id and status = 'completed'), 0) >= v_payment.amount then 'refunded'
    else 'partially_refunded'
  end into v_status;

  update public.payments set status = v_status where id = v_payment.id;
end;
$$;

revoke all on function public.folio_balance(uuid) from public, anon;
revoke all on function public.get_available_rooms(date, date, uuid, integer) from public;
revoke all on function public.create_reservation(uuid, uuid, date, date, uuid, text, text, text, integer, integer, text, text) from public, anon;
revoke all on function public.modify_reservation(uuid, uuid, date, date, integer, text) from public, anon;
revoke all on function public.cancel_reservation(uuid, text, boolean) from public, anon;
revoke all on function public.check_in_reservation(uuid, uuid) from public, anon;
revoke all on function public.check_out_reservation(uuid, boolean, uuid, text) from public, anon;
revoke all on function public.post_bill_item(uuid, uuid, text, numeric, numeric, numeric, numeric, text, uuid, text) from public, anon;
revoke all on function public.record_manual_payment(uuid, numeric, public.payment_provider, text, text, text) from public, anon;
revoke all on function public.submit_bank_transfer(uuid, numeric, text, text, text) from public, anon;
revoke all on function public.verify_bank_transfer(uuid, public.payment_verification_action, text, text) from public, anon;
revoke all on function public.confirm_paystack_payment(text, numeric, text, text) from public, anon;
revoke all on function public.request_refund(uuid, numeric, text) from public, anon;
revoke all on function public.approve_refund(uuid) from public, anon;

grant execute on function public.get_available_rooms(date, date, uuid, integer) to anon, authenticated, service_role;
grant execute on function public.folio_balance(uuid) to authenticated, service_role;
grant execute on function public.create_reservation(uuid, uuid, date, date, uuid, text, text, text, integer, integer, text, text) to authenticated, service_role;
grant execute on function public.modify_reservation(uuid, uuid, date, date, integer, text) to authenticated, service_role;
grant execute on function public.cancel_reservation(uuid, text, boolean) to authenticated, service_role;
grant execute on function public.check_in_reservation(uuid, uuid) to authenticated, service_role;
grant execute on function public.check_out_reservation(uuid, boolean, uuid, text) to authenticated, service_role;
grant execute on function public.post_bill_item(uuid, uuid, text, numeric, numeric, numeric, numeric, text, uuid, text) to authenticated, service_role;
grant execute on function public.record_manual_payment(uuid, numeric, public.payment_provider, text, text, text) to authenticated, service_role;
grant execute on function public.submit_bank_transfer(uuid, numeric, text, text, text) to authenticated, service_role;
grant execute on function public.verify_bank_transfer(uuid, public.payment_verification_action, text, text) to authenticated, service_role;
grant execute on function public.confirm_paystack_payment(text, numeric, text, text) to service_role;
grant execute on function public.request_refund(uuid, numeric, text) to authenticated, service_role;
grant execute on function public.approve_refund(uuid) to authenticated, service_role;
