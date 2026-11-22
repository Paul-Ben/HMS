create or replace function private.is_active_profile()
returns boolean
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and is_active
  );
$$;

create or replace function private.current_staff_id()
returns uuid
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select sp.id
  from public.staff_profiles sp
  join public.profiles p on p.id = sp.profile_id and p.is_active
  where sp.profile_id = auth.uid()
    and sp.employment_status = 'active'::public.employment_status
  limit 1;
$$;

create or replace function private.current_guest_id()
returns uuid
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select g.id
  from public.guests g
  join public.profiles p on p.id = g.auth_user_id and p.is_active
  where g.auth_user_id = auth.uid()
    and g.is_active
    and g.merged_into_id is null
  limit 1;
$$;

create or replace function private.has_role(role_key text)
returns boolean
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select exists (
    select 1
    from public.user_roles ur
    join public.roles r on r.id = ur.role_id
    join public.profiles p on p.id = ur.user_id and p.is_active
    where ur.user_id = auth.uid() and r.key = role_key
  );
$$;

create or replace function private.has_any_role(role_keys text[])
returns boolean
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select exists (
    select 1
    from public.user_roles ur
    join public.roles r on r.id = ur.role_id
    join public.profiles p on p.id = ur.user_id and p.is_active
    where ur.user_id = auth.uid() and r.key = any(role_keys)
  );
$$;

create or replace function private.has_permission(permission_key text)
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
    where ur.user_id = auth.uid() and p.key = permission_key
  );
$$;

create or replace function private.has_department_scope(target_department_id uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_staff_department_id uuid;
begin
  if target_department_id is null then
    return false;
  end if;

  select sp.department_id into v_staff_department_id
  from public.staff_profiles sp
  where sp.profile_id = auth.uid()
  limit 1;

  if v_staff_department_id is not null and v_staff_department_id = target_department_id then
    return true;
  end if;

  return exists (
    select 1
    from public.user_roles ur
    join public.role_permissions rp on rp.role_id = ur.role_id
    join public.permissions p on p.id = rp.permission_id
    join public.profiles pr on pr.id = ur.user_id and pr.is_active
    where ur.user_id = auth.uid()
      and p.scope = 'all'
      and p.key in (
        'rooms.manage', 'reservation.update', 'guest.manage', 'folio.adjust',
        'inventory.manage', 'inventory.purchase', 'inventory.adjust',
        'shifts.manage', 'staff.manage', 'settings.manage', 'policy.manage',
        'menu.manage', 'laundry.services.manage', 'housekeeping.assign'
      )
  );
end;
$$;

create or replace function private.current_hotel_id()
returns uuid
language sql
stable
as $$
  select coalesce(
    nullif(current_setting('request.jwt.claims', true)::jsonb ->> 'hotel_id', '')::uuid,
    '11111111-1111-4111-8111-111111111111'::uuid
  );
$$;

create or replace function private.guest_owns_reservation(target_reservation_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select exists (
    select 1 from public.reservations
    where id = target_reservation_id and guest_id = private.current_guest_id()
  );
$$;

create or replace function private.guest_owns_folio(target_folio_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select exists (
    select 1 from public.folios f
    where f.id = target_folio_id
      and (
        f.guest_id = private.current_guest_id()
        or (f.reservation_id is not null and private.guest_owns_reservation(f.reservation_id))
      )
  );
$$;

create or replace function private.guest_owns_payment(target_payment_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select exists (
    select 1 from public.payments p
    where p.id = target_payment_id
      and (
        private.guest_owns_folio(p.folio_id)
        or (p.reservation_id is not null and private.guest_owns_reservation(p.reservation_id))
      )
  );
$$;

create or replace function private.guest_owns_receipt(target_receipt_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select exists (
    select 1 from public.receipts r
    where r.id = target_receipt_id and private.guest_owns_payment(r.payment_id)
  );
$$;

create or replace function private.record_reservation_status_history()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
begin
  if old.status is distinct from new.status then
    insert into public.reservation_status_history (reservation_id, from_status, to_status, actor_id)
    values (new.id, old.status, new.status, private.actor_id_from_jwt());
  end if;
  return new;
end;
$$;

create or replace function private.record_service_order_status_history()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
begin
  if old.status is distinct from new.status then
    insert into public.service_order_status_history (service_order_id, from_status, to_status, reason, actor_id)
    values (new.id, old.status, new.status, new.cancel_reason, private.actor_id_from_jwt());
  end if;
  return new;
end;
$$;

create or replace function private.record_laundry_order_status_history()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
begin
  if old.status is distinct from new.status then
    insert into public.laundry_order_status_history (laundry_order_id, from_status, to_status, reason, actor_id)
    values (new.id, old.status, new.status, new.cancel_reason, private.actor_id_from_jwt());
  end if;
  return new;
end;
$$;

grant usage on schema public to anon, authenticated;
grant select on all tables in schema public to anon;
grant select, insert, update, delete on all tables in schema public to authenticated;

create policy self_select_profile on public.profiles for select to authenticated using (id = auth.uid());
create policy staff_select_directory_profiles on public.profiles for select to authenticated using (private.has_permission('staff.read'));
create policy hr_select_profiles on public.profiles for select to authenticated using (private.has_permission('staff.read_hr'));
create policy owner_select_profiles on public.profiles for select to authenticated using (private.has_role('owner'));

create policy staff_select_departments on public.departments for select to authenticated using (private.current_staff_id() is not null or private.has_role('owner'));
create policy manager_insert_departments on public.departments for insert to authenticated with check (private.has_permission('staff.manage'));
create policy manager_update_departments on public.departments for update to authenticated using (private.has_permission('staff.manage')) with check (private.has_permission('staff.manage'));
create policy manager_delete_departments on public.departments for delete to authenticated using (private.has_permission('staff.manage'));

create policy staff_select_roles on public.roles for select to authenticated using (private.has_permission('staff.read') or private.has_role('owner'));
create policy manager_insert_roles on public.roles for insert to authenticated with check (private.has_permission('roles.manage'));
create policy manager_update_roles on public.roles for update to authenticated using (private.has_permission('roles.manage')) with check (private.has_permission('roles.manage'));
create policy manager_delete_roles on public.roles for delete to authenticated using (private.has_permission('roles.manage'));

create policy staff_select_permissions on public.permissions for select to authenticated using (private.has_permission('staff.read') or private.has_role('owner'));
create policy manager_insert_permissions on public.permissions for insert to authenticated with check (private.has_permission('roles.manage'));
create policy manager_update_permissions on public.permissions for update to authenticated using (private.has_permission('roles.manage')) with check (private.has_permission('roles.manage'));
create policy manager_delete_permissions on public.permissions for delete to authenticated using (private.has_permission('roles.manage'));

create policy staff_select_role_permissions on public.role_permissions for select to authenticated using (private.has_permission('staff.read') or private.has_role('owner'));
create policy manager_insert_role_permissions on public.role_permissions for insert to authenticated with check (private.has_permission('roles.manage'));
create policy manager_delete_role_permissions on public.role_permissions for delete to authenticated using (private.has_permission('roles.manage'));

create policy guest_select_own_user_roles on public.user_roles for select to authenticated using (user_id = auth.uid());
create policy owner_select_user_roles on public.user_roles for select to authenticated using (private.has_role('owner'));

create policy staff_select_hotels on public.hotels for select to authenticated using (id = private.current_hotel_id() and (private.current_staff_id() is not null or private.has_role('owner')));
create policy manager_update_hotels on public.hotels for update to authenticated using (id = private.current_hotel_id() and private.has_permission('settings.manage')) with check (id = private.current_hotel_id() and private.has_permission('settings.manage'));

create policy staff_select_hotel_settings on public.hotel_settings for select to authenticated using (hotel_id = private.current_hotel_id());
create policy manager_update_hotel_settings on public.hotel_settings for update to authenticated using (hotel_id = private.current_hotel_id() and private.has_permission('settings.manage')) with check (hotel_id = private.current_hotel_id() and private.has_permission('settings.manage'));

create policy public_select_booking_settings on public.booking_settings for select to anon, authenticated using (hotel_id = private.current_hotel_id());
create policy manager_update_booking_settings on public.booking_settings for update to authenticated using (hotel_id = private.current_hotel_id() and private.has_permission('policy.manage')) with check (hotel_id = private.current_hotel_id() and private.has_permission('policy.manage'));

create policy self_select_staff_profile on public.staff_profiles for select to authenticated using (profile_id = auth.uid());
create policy staff_select_department_roster on public.staff_profiles for select to authenticated using (private.has_permission('staff.read') and private.has_department_scope(department_id));
create policy hr_select_staff_profiles on public.staff_profiles for select to authenticated using (private.has_permission('staff.read_hr'));
create policy owner_select_staff_profiles on public.staff_profiles for select to authenticated using (private.has_role('owner'));
create policy manager_insert_staff_profiles on public.staff_profiles for insert to authenticated with check (private.has_permission('staff.manage'));
create policy manager_update_staff_profiles on public.staff_profiles for update to authenticated using (private.has_permission('staff.manage')) with check (private.has_permission('staff.manage'));
create policy manager_delete_staff_profiles on public.staff_profiles for delete to authenticated using (private.has_permission('staff.manage'));

create policy manager_select_audit_logs on public.audit_logs for select to authenticated using (private.has_permission('audit.read'));
create policy accountant_select_finance_audit_logs on public.audit_logs for select to authenticated using (private.has_permission('audit.read_finance') and hotel_id = private.current_hotel_id());
create policy owner_select_audit_logs on public.audit_logs for select to authenticated using (private.has_role('owner'));

create policy public_select_system_settings on public.system_settings for select to anon, authenticated using (is_public);
create policy manager_select_system_settings on public.system_settings for select to authenticated using (private.has_permission('settings.manage') or private.has_role('owner'));

create policy public_select_floors on public.floors for select to anon, authenticated using (is_active and hotel_id = private.current_hotel_id());
create policy owner_select_floors on public.floors for select to authenticated using (private.has_role('owner'));
create policy manager_insert_floors on public.floors for insert to authenticated with check (private.has_permission('rooms.manage'));
create policy manager_update_floors on public.floors for update to authenticated using (private.has_permission('rooms.manage')) with check (private.has_permission('rooms.manage'));
create policy manager_delete_floors on public.floors for delete to authenticated using (private.has_permission('rooms.manage'));

create policy public_select_room_categories on public.room_categories for select to anon, authenticated using (is_active and hotel_id = private.current_hotel_id());
create policy owner_select_room_categories on public.room_categories for select to authenticated using (private.has_role('owner'));
create policy manager_insert_room_categories on public.room_categories for insert to authenticated with check (private.has_permission('rooms.manage'));
create policy manager_update_room_categories on public.room_categories for update to authenticated using (private.has_permission('rooms.manage')) with check (private.has_permission('rooms.manage'));
create policy manager_delete_room_categories on public.room_categories for delete to authenticated using (private.has_permission('rooms.manage'));

create policy public_select_amenities on public.amenities for select to anon, authenticated using (is_active and hotel_id = private.current_hotel_id());
create policy owner_select_amenities on public.amenities for select to authenticated using (private.has_role('owner'));
create policy manager_insert_amenities on public.amenities for insert to authenticated with check (private.has_permission('rooms.manage'));
create policy manager_update_amenities on public.amenities for update to authenticated using (private.has_permission('rooms.manage')) with check (private.has_permission('rooms.manage'));
create policy manager_delete_amenities on public.amenities for delete to authenticated using (private.has_permission('rooms.manage'));

create policy public_select_room_category_amenities on public.room_category_amenities for select to anon, authenticated using (
  exists (select 1 from public.room_categories rc where rc.id = room_category_id and rc.is_active)
  and exists (select 1 from public.amenities a where a.id = amenity_id and a.is_active)
);
create policy owner_select_room_category_amenities on public.room_category_amenities for select to authenticated using (private.has_role('owner'));
create policy manager_insert_room_category_amenities on public.room_category_amenities for insert to authenticated with check (private.has_permission('rooms.manage'));
create policy manager_delete_room_category_amenities on public.room_category_amenities for delete to authenticated using (private.has_permission('rooms.manage'));

create policy staff_select_rooms on public.rooms for select to authenticated using (private.has_permission('rooms.read') and hotel_id = private.current_hotel_id());
create policy housekeeping_select_assigned_rooms on public.rooms for select to authenticated using (exists (select 1 from public.housekeeping_tasks ht where ht.room_id = rooms.id and ht.assigned_to = private.current_staff_id()));
create policy owner_select_rooms on public.rooms for select to authenticated using (private.has_role('owner'));
create policy receptionist_update_room_status on public.rooms for update to authenticated using (private.has_permission('room_status.manage')) with check (private.has_permission('room_status.manage'));
create policy manager_update_rooms on public.rooms for update to authenticated using (private.has_permission('rooms.manage')) with check (private.has_permission('rooms.manage'));

create policy public_select_room_amenities on public.room_amenities for select to anon, authenticated using (exists (select 1 from public.rooms r where r.id = room_id and r.is_active));
create policy owner_select_room_amenities on public.room_amenities for select to authenticated using (private.has_role('owner'));
create policy manager_insert_room_amenities on public.room_amenities for insert to authenticated with check (private.has_permission('rooms.manage'));
create policy manager_delete_room_amenities on public.room_amenities for delete to authenticated using (private.has_permission('rooms.manage'));

create policy public_select_room_images on public.room_images for select to anon, authenticated using (
  exists (select 1 from public.rooms r where r.id = room_id and r.is_active)
  or exists (select 1 from public.room_categories rc where rc.id = room_category_id and rc.is_active)
);
create policy owner_select_room_images on public.room_images for select to authenticated using (private.has_role('owner'));
create policy manager_insert_room_images on public.room_images for insert to authenticated with check (private.has_permission('content.manage'));
create policy manager_update_room_images on public.room_images for update to authenticated using (private.has_permission('content.manage')) with check (private.has_permission('content.manage'));
create policy manager_delete_room_images on public.room_images for delete to authenticated using (private.has_permission('content.manage'));

create policy staff_select_own_maintenance on public.room_maintenance for select to authenticated using (reported_by = private.current_staff_id());
create policy receptionist_select_maintenance on public.room_maintenance for select to authenticated using (private.has_permission('rooms.read'));
create policy accountant_select_maintenance_cost on public.room_maintenance for select to authenticated using (private.has_permission('ledger.read'));
create policy owner_select_room_maintenance on public.room_maintenance for select to authenticated using (private.has_role('owner'));
create policy manager_update_room_maintenance on public.room_maintenance for update to authenticated using (private.has_permission('rooms.manage')) with check (private.has_permission('rooms.manage'));

create policy housekeeping_select_own_tasks on public.housekeeping_tasks for select to authenticated using (assigned_to = private.current_staff_id());
create policy supervisor_select_housekeeping_tasks on public.housekeeping_tasks for select to authenticated using (private.has_permission('housekeeping.assign'));
create policy receptionist_select_housekeeping_tasks on public.housekeeping_tasks for select to authenticated using (private.has_permission('rooms.read'));
create policy owner_select_housekeeping_tasks on public.housekeeping_tasks for select to authenticated using (private.has_role('owner'));
create policy manager_insert_housekeeping_tasks on public.housekeeping_tasks for insert to authenticated with check (private.has_permission('housekeeping.assign'));
create policy manager_update_housekeeping_tasks on public.housekeeping_tasks for update to authenticated using (private.has_permission('housekeeping.assign')) with check (private.has_permission('housekeeping.assign'));
create policy manager_delete_housekeeping_tasks on public.housekeeping_tasks for delete to authenticated using (private.has_permission('housekeeping.assign'));

create policy guest_select_own_guest on public.guests for select to authenticated using (auth_user_id = auth.uid() and is_active and merged_into_id is null);
create policy staff_select_guests on public.guests for select to authenticated using (private.has_permission('guest.read') and hotel_id = private.current_hotel_id());
create policy owner_select_guests on public.guests for select to authenticated using (private.has_role('owner'));
create policy manager_insert_guests on public.guests for insert to authenticated with check (private.has_permission('guest.manage'));
create policy manager_update_guests on public.guests for update to authenticated using (private.has_permission('guest.manage')) with check (private.has_permission('guest.manage'));
create policy manager_delete_guests on public.guests for delete to authenticated using (private.has_permission('guest.manage'));

create policy public_select_cancellation_policies on public.cancellation_policies for select to anon, authenticated using (is_active and hotel_id = private.current_hotel_id());
create policy owner_select_cancellation_policies on public.cancellation_policies for select to authenticated using (private.has_role('owner'));
create policy manager_insert_cancellation_policies on public.cancellation_policies for insert to authenticated with check (private.has_permission('policy.manage'));
create policy manager_update_cancellation_policies on public.cancellation_policies for update to authenticated using (private.has_permission('policy.manage')) with check (private.has_permission('policy.manage'));
create policy manager_delete_cancellation_policies on public.cancellation_policies for delete to authenticated using (private.has_permission('policy.manage'));

create policy public_select_rate_plans on public.rate_plans for select to anon, authenticated using (is_active and hotel_id = private.current_hotel_id());
create policy owner_select_rate_plans on public.rate_plans for select to authenticated using (private.has_role('owner'));
create policy manager_insert_rate_plans on public.rate_plans for insert to authenticated with check (private.has_permission('rates.manage'));
create policy manager_update_rate_plans on public.rate_plans for update to authenticated using (private.has_permission('rates.manage')) with check (private.has_permission('rates.manage'));
create policy manager_delete_rate_plans on public.rate_plans for delete to authenticated using (private.has_permission('rates.manage'));

create policy guest_select_own_reservations on public.reservations for select to authenticated using (guest_id = private.current_guest_id());
create policy staff_select_reservations on public.reservations for select to authenticated using (private.has_permission('guest.read') or private.has_permission('reservation.update'));
create policy accountant_select_reservations_financial on public.reservations for select to authenticated using (private.has_permission('ledger.read'));
create policy owner_select_reservations on public.reservations for select to authenticated using (private.has_role('owner'));

create policy guest_select_own_reservation_guests on public.reservation_guests for select to authenticated using (guest_id = private.current_guest_id());
create policy staff_select_reservation_guests on public.reservation_guests for select to authenticated using (private.has_permission('guest.read'));
create policy accountant_select_reservation_guests on public.reservation_guests for select to authenticated using (private.has_permission('ledger.read'));
create policy owner_select_reservation_guests on public.reservation_guests for select to authenticated using (private.has_role('owner'));
create policy manager_insert_reservation_guests on public.reservation_guests for insert to authenticated with check (private.has_permission('reservation.update'));
create policy manager_delete_reservation_guests on public.reservation_guests for delete to authenticated using (private.has_permission('reservation.update'));

create policy guest_select_own_room_assignments on public.reservation_room_assignments for select to authenticated using (private.guest_owns_reservation(reservation_id));
create policy staff_select_room_assignments on public.reservation_room_assignments for select to authenticated using (private.has_permission('reservation.update') or private.has_permission('rooms.read'));
create policy accountant_select_room_assignments on public.reservation_room_assignments for select to authenticated using (private.has_permission('ledger.read'));
create policy owner_select_room_assignments on public.reservation_room_assignments for select to authenticated using (private.has_role('owner'));

create policy guest_select_own_holds on public.room_allocation_holds for select to authenticated using (private.guest_owns_reservation(reservation_id));
create policy staff_select_holds on public.room_allocation_holds for select to authenticated using (private.has_permission('reservation.update'));
create policy owner_select_holds on public.room_allocation_holds for select to authenticated using (private.has_role('owner'));

create policy guest_select_own_reservation_status_history on public.reservation_status_history for select to authenticated using (private.guest_owns_reservation(reservation_id));
create policy staff_select_reservation_status_history on public.reservation_status_history for select to authenticated using (private.has_permission('guest.read'));
create policy accountant_select_reservation_status_history on public.reservation_status_history for select to authenticated using (private.has_permission('ledger.read'));
create policy owner_select_reservation_status_history on public.reservation_status_history for select to authenticated using (private.has_role('owner'));

create policy finance_select_financial_accounts on public.financial_accounts for select to authenticated using (private.has_permission('ledger.read'));
create policy owner_select_financial_accounts on public.financial_accounts for select to authenticated using (private.has_role('owner'));

create policy guest_select_own_folios on public.folios for select to authenticated using (private.guest_owns_folio(id));
create policy staff_select_folios on public.folios for select to authenticated using (private.has_permission('folio.read') and hotel_id = private.current_hotel_id());
create policy accountant_select_folios on public.folios for select to authenticated using (private.has_permission('ledger.read'));
create policy owner_select_folios on public.folios for select to authenticated using (private.has_role('owner'));

create policy guest_select_own_bills on public.bills for select to authenticated using (private.guest_owns_folio(folio_id));
create policy staff_select_bills on public.bills for select to authenticated using (private.has_permission('folio.read') and private.has_department_scope(department_id));
create policy accountant_select_bills on public.bills for select to authenticated using (private.has_permission('ledger.read'));
create policy owner_select_bills on public.bills for select to authenticated using (private.has_role('owner'));
create policy manager_insert_bills on public.bills for insert to authenticated with check (private.has_permission('folio.charge') and private.has_department_scope(department_id));

create policy guest_select_own_bill_items on public.bill_items for select to authenticated using (private.guest_owns_folio(folio_id));
create policy staff_select_bill_items on public.bill_items for select to authenticated using (private.has_permission('folio.read'));
create policy accountant_select_bill_items on public.bill_items for select to authenticated using (private.has_permission('ledger.read'));
create policy owner_select_bill_items on public.bill_items for select to authenticated using (private.has_role('owner'));
create policy manager_insert_bill_items on public.bill_items for insert to authenticated with check (private.has_permission('folio.charge'));

create policy guest_select_own_payments on public.payments for select to authenticated using (private.guest_owns_payment(id));
create policy staff_select_payments on public.payments for select to authenticated using (private.has_permission('payment.cash') or private.has_permission('payment.pos') or private.has_permission('payment.transfer.submit'));
create policy accountant_select_payments on public.payments for select to authenticated using (private.has_permission('ledger.read'));
create policy owner_select_payments on public.payments for select to authenticated using (private.has_role('owner'));

create policy receptionist_select_payment_verifications on public.payment_verifications for select to authenticated using (private.has_permission('payment.transfer.submit'));
create policy manager_insert_payment_verifications on public.payment_verifications for insert to authenticated with check (
  private.has_permission('payment.transfer.verify')
  and checker_id = private.current_staff_id()
  and checker_id <> (select recorded_by from public.payments where id = payment_id)
);
create policy accountant_insert_payment_verifications on public.payment_verifications for insert to authenticated with check (
  private.has_permission('payment.transfer.verify')
  and checker_id = private.current_staff_id()
  and checker_id <> (select recorded_by from public.payments where id = payment_id)
);
create policy owner_select_payment_verifications on public.payment_verifications for select to authenticated using (private.has_role('owner'));

create policy guest_select_own_refunds on public.refunds for select to authenticated using (private.guest_owns_payment(payment_id));
create policy receptionist_select_refunds on public.refunds for select to authenticated using (private.has_permission('refund.request'));
create policy manager_update_refunds on public.refunds for update to authenticated using (private.has_permission('refund.approve')) with check (private.has_permission('refund.approve'));
create policy accountant_update_refunds on public.refunds for update to authenticated using (private.has_permission('refund.approve')) with check (private.has_permission('refund.approve'));
create policy owner_select_refunds on public.refunds for select to authenticated using (private.has_role('owner'));

create policy guest_select_own_receipts on public.receipts for select to authenticated using (private.guest_owns_receipt(id));
create policy staff_select_receipts on public.receipts for select to authenticated using (private.has_permission('receipt.read'));
create policy accountant_select_receipts on public.receipts for select to authenticated using (private.has_permission('ledger.read'));
create policy owner_select_receipts on public.receipts for select to authenticated using (private.has_role('owner'));

create policy receptionist_select_own_payment_exceptions on public.payment_exceptions for select to authenticated using (created_by = auth.uid());
create policy manager_update_payment_exceptions on public.payment_exceptions for update to authenticated using (private.has_permission('payment.transfer.verify')) with check (private.has_permission('payment.transfer.verify'));
create policy accountant_update_payment_exceptions on public.payment_exceptions for update to authenticated using (private.has_permission('payment.transfer.verify')) with check (private.has_permission('payment.transfer.verify'));
create policy owner_select_payment_exceptions on public.payment_exceptions for select to authenticated using (private.has_role('owner'));

create policy finance_select_financial_transactions on public.financial_transactions for select to authenticated using (private.has_permission('ledger.read'));
create policy owner_select_financial_transactions on public.financial_transactions for select to authenticated using (private.has_role('owner'));

create policy finance_select_financial_transaction_lines on public.financial_transaction_lines for select to authenticated using (
  exists (select 1 from public.financial_transactions t where t.id = financial_transaction_id and private.has_permission('ledger.read'))
);
create policy owner_select_financial_transaction_lines on public.financial_transaction_lines for select to authenticated using (
  exists (select 1 from public.financial_transactions t where t.id = financial_transaction_id and private.has_role('owner'))
);

create policy staff_select_financial_adjustments on public.financial_adjustments for select to authenticated using (private.has_permission('folio.read'));
create policy manager_update_financial_adjustments on public.financial_adjustments for update to authenticated using (private.has_permission('folio.adjust')) with check (private.has_permission('folio.adjust'));
create policy accountant_update_financial_adjustments on public.financial_adjustments for update to authenticated using (private.has_permission('folio.adjust')) with check (private.has_permission('folio.adjust'));
create policy owner_select_financial_adjustments on public.financial_adjustments for select to authenticated using (private.has_role('owner'));

create policy finance_select_suppliers on public.suppliers for select to authenticated using (private.has_permission('inventory.purchase'));
create policy owner_select_suppliers on public.suppliers for select to authenticated using (private.has_role('owner'));
create policy manager_insert_suppliers on public.suppliers for insert to authenticated with check (private.has_permission('inventory.purchase'));
create policy manager_update_suppliers on public.suppliers for update to authenticated using (private.has_permission('inventory.purchase')) with check (private.has_permission('inventory.purchase'));
create policy manager_delete_suppliers on public.suppliers for delete to authenticated using (private.has_permission('inventory.purchase'));

create policy dept_select_inventory_categories on public.inventory_categories for select to authenticated using (private.has_permission('inventory.read') and private.has_department_scope(department_id));
create policy finance_select_inventory_categories on public.inventory_categories for select to authenticated using (private.has_permission('inventory.read_cost'));
create policy owner_select_inventory_categories on public.inventory_categories for select to authenticated using (private.has_role('owner'));
create policy manager_insert_inventory_categories on public.inventory_categories for insert to authenticated with check (private.has_permission('inventory.manage'));
create policy manager_update_inventory_categories on public.inventory_categories for update to authenticated using (private.has_permission('inventory.manage')) with check (private.has_permission('inventory.manage'));
create policy manager_delete_inventory_categories on public.inventory_categories for delete to authenticated using (private.has_permission('inventory.manage'));

create policy staff_select_inventory_locations on public.inventory_locations for select to authenticated using (private.has_permission('inventory.read'));
create policy finance_select_inventory_locations on public.inventory_locations for select to authenticated using (private.has_permission('inventory.read_cost'));
create policy owner_select_inventory_locations on public.inventory_locations for select to authenticated using (private.has_role('owner'));
create policy manager_insert_inventory_locations on public.inventory_locations for insert to authenticated with check (private.has_permission('inventory.manage'));
create policy manager_update_inventory_locations on public.inventory_locations for update to authenticated using (private.has_permission('inventory.manage')) with check (private.has_permission('inventory.manage'));
create policy manager_delete_inventory_locations on public.inventory_locations for delete to authenticated using (private.has_permission('inventory.manage'));

create policy dept_select_inventory_items on public.inventory_items for select to authenticated using (
  private.has_permission('inventory.read') and exists (select 1 from public.inventory_categories ic where ic.id = category_id and private.has_department_scope(ic.department_id))
);
create policy finance_select_inventory_items on public.inventory_items for select to authenticated using (private.has_permission('inventory.read_cost'));
create policy owner_select_inventory_items on public.inventory_items for select to authenticated using (private.has_role('owner'));
create policy manager_insert_inventory_items on public.inventory_items for insert to authenticated with check (private.has_permission('inventory.manage'));
create policy manager_update_inventory_items on public.inventory_items for update to authenticated using (private.has_permission('inventory.manage')) with check (private.has_permission('inventory.manage'));
create policy manager_delete_inventory_items on public.inventory_items for delete to authenticated using (private.has_permission('inventory.manage'));

create policy public_select_food_categories on public.food_categories for select to anon, authenticated using (is_active and hotel_id = private.current_hotel_id());
create policy staff_select_food_categories on public.food_categories for select to authenticated using (private.has_permission('menu.read'));
create policy owner_select_food_categories on public.food_categories for select to authenticated using (private.has_role('owner'));
create policy manager_insert_food_categories on public.food_categories for insert to authenticated with check (private.has_permission('menu.manage'));
create policy manager_update_food_categories on public.food_categories for update to authenticated using (private.has_permission('menu.manage')) with check (private.has_permission('menu.manage'));
create policy manager_delete_food_categories on public.food_categories for delete to authenticated using (private.has_permission('menu.manage'));

create policy public_select_food_products on public.food_products for select to anon, authenticated using (is_active and is_available and hotel_id = private.current_hotel_id());
create policy staff_select_food_products on public.food_products for select to authenticated using (private.has_permission('menu.read'));
create policy owner_select_food_products on public.food_products for select to authenticated using (private.has_role('owner'));
create policy manager_insert_food_products on public.food_products for insert to authenticated with check (private.has_permission('menu.manage'));
create policy manager_update_food_products on public.food_products for update to authenticated using (private.has_permission('menu.manage')) with check (private.has_permission('menu.manage'));
create policy manager_delete_food_products on public.food_products for delete to authenticated using (private.has_permission('menu.manage'));

create policy kitchen_select_food_recipes on public.food_recipes for select to authenticated using (private.has_permission('recipe.usage'));
create policy owner_select_food_recipes on public.food_recipes for select to authenticated using (private.has_role('owner'));
create policy manager_insert_food_recipes on public.food_recipes for insert to authenticated with check (private.has_permission('inventory.recipes.manage'));
create policy manager_update_food_recipes on public.food_recipes for update to authenticated using (private.has_permission('inventory.recipes.manage')) with check (private.has_permission('inventory.recipes.manage'));
create policy manager_delete_food_recipes on public.food_recipes for delete to authenticated using (private.has_permission('inventory.recipes.manage'));

create policy kitchen_select_recipe_ingredients on public.recipe_ingredients for select to authenticated using (private.has_permission('recipe.usage'));
create policy owner_select_recipe_ingredients on public.recipe_ingredients for select to authenticated using (private.has_role('owner'));
create policy manager_insert_recipe_ingredients on public.recipe_ingredients for insert to authenticated with check (private.has_permission('inventory.recipes.manage'));
create policy manager_delete_recipe_ingredients on public.recipe_ingredients for delete to authenticated using (private.has_permission('inventory.recipes.manage'));

create policy public_select_bar_categories on public.bar_categories for select to anon, authenticated using (is_active and hotel_id = private.current_hotel_id());
create policy staff_select_bar_categories on public.bar_categories for select to authenticated using (private.has_permission('menu.read'));
create policy owner_select_bar_categories on public.bar_categories for select to authenticated using (private.has_role('owner'));
create policy manager_insert_bar_categories on public.bar_categories for insert to authenticated with check (private.has_permission('menu.manage'));
create policy manager_update_bar_categories on public.bar_categories for update to authenticated using (private.has_permission('menu.manage')) with check (private.has_permission('menu.manage'));
create policy manager_delete_bar_categories on public.bar_categories for delete to authenticated using (private.has_permission('menu.manage'));

create policy public_select_bar_products on public.bar_products for select to anon, authenticated using (is_active and is_available and hotel_id = private.current_hotel_id());
create policy staff_select_bar_products on public.bar_products for select to authenticated using (private.has_permission('menu.read'));
create policy owner_select_bar_products on public.bar_products for select to authenticated using (private.has_role('owner'));
create policy manager_insert_bar_products on public.bar_products for insert to authenticated with check (private.has_permission('menu.manage'));
create policy manager_update_bar_products on public.bar_products for update to authenticated using (private.has_permission('menu.manage')) with check (private.has_permission('menu.manage'));
create policy manager_delete_bar_products on public.bar_products for delete to authenticated using (private.has_permission('menu.manage'));

create policy staff_select_dining_tables on public.dining_tables for select to authenticated using (private.has_permission('order.read'));
create policy owner_select_dining_tables on public.dining_tables for select to authenticated using (private.has_role('owner'));
create policy manager_insert_dining_tables on public.dining_tables for insert to authenticated with check (private.has_permission('menu.manage'));
create policy manager_update_dining_tables on public.dining_tables for update to authenticated using (private.has_permission('menu.manage')) with check (private.has_permission('menu.manage'));
create policy manager_delete_dining_tables on public.dining_tables for delete to authenticated using (private.has_permission('menu.manage'));

create policy guest_select_own_service_orders on public.service_orders for select to authenticated using (guest_id = private.current_guest_id());
create policy dept_select_service_orders on public.service_orders for select to authenticated using (
  private.has_permission('order.read') and (
    assigned_to = private.current_staff_id()
    or private.has_department_scope((select id from public.departments where key = case when department = 'restaurant' then 'restaurant' when department = 'bar' then 'bar' end))
  )
);
create policy accountant_select_service_orders on public.service_orders for select to authenticated using (private.has_permission('ledger.read'));
create policy owner_select_service_orders on public.service_orders for select to authenticated using (private.has_role('owner'));
create policy manager_insert_service_orders on public.service_orders for insert to authenticated with check (private.has_permission('order.create'));

create policy guest_select_own_service_order_items on public.service_order_items for select to authenticated using (exists (select 1 from public.service_orders so where so.id = service_order_id and so.guest_id = private.current_guest_id()));
create policy dept_select_service_order_items on public.service_order_items for select to authenticated using (exists (select 1 from public.service_orders so where so.id = service_order_id and private.has_permission('order.read')));
create policy accountant_select_service_order_items on public.service_order_items for select to authenticated using (exists (select 1 from public.service_orders so where so.id = service_order_id and private.has_permission('ledger.read')));
create policy owner_select_service_order_items on public.service_order_items for select to authenticated using (exists (select 1 from public.service_orders so where so.id = service_order_id and private.has_role('owner')));
create policy manager_insert_service_order_items on public.service_order_items for insert to authenticated with check (private.has_permission('order.create'));

create policy guest_select_own_service_order_history on public.service_order_status_history for select to authenticated using (exists (select 1 from public.service_orders so where so.id = service_order_id and so.guest_id = private.current_guest_id()));
create policy dept_select_service_order_history on public.service_order_status_history for select to authenticated using (exists (select 1 from public.service_orders so where so.id = service_order_id and private.has_permission('order.read')));
create policy accountant_select_service_order_history on public.service_order_status_history for select to authenticated using (exists (select 1 from public.service_orders so where so.id = service_order_id and private.has_permission('ledger.read')));
create policy owner_select_service_order_history on public.service_order_status_history for select to authenticated using (exists (select 1 from public.service_orders so where so.id = service_order_id and private.has_role('owner')));

create policy public_select_laundry_services on public.laundry_services for select to anon, authenticated using (is_active and hotel_id = private.current_hotel_id());
create policy dept_select_laundry_services on public.laundry_services for select to authenticated using (private.has_permission('laundry.read'));
create policy owner_select_laundry_services on public.laundry_services for select to authenticated using (private.has_role('owner'));
create policy manager_insert_laundry_services on public.laundry_services for insert to authenticated with check (private.has_permission('laundry.services.manage'));
create policy manager_update_laundry_services on public.laundry_services for update to authenticated using (private.has_permission('laundry.services.manage')) with check (private.has_permission('laundry.services.manage'));
create policy manager_delete_laundry_services on public.laundry_services for delete to authenticated using (private.has_permission('laundry.services.manage'));

create policy guest_select_own_laundry_orders on public.laundry_orders for select to authenticated using (guest_id = private.current_guest_id());
create policy dept_select_laundry_orders on public.laundry_orders for select to authenticated using (private.has_permission('laundry.read') and assigned_to = private.current_staff_id());
create policy receptionist_select_laundry_orders on public.laundry_orders for select to authenticated using (private.has_permission('laundry.read'));
create policy accountant_select_laundry_orders on public.laundry_orders for select to authenticated using (private.has_permission('ledger.read'));
create policy owner_select_laundry_orders on public.laundry_orders for select to authenticated using (private.has_role('owner'));
create policy manager_insert_laundry_orders on public.laundry_orders for insert to authenticated with check (private.has_permission('laundry.create'));

create policy guest_select_own_laundry_order_items on public.laundry_order_items for select to authenticated using (exists (select 1 from public.laundry_orders lo where lo.id = laundry_order_id and lo.guest_id = private.current_guest_id()));
create policy dept_select_laundry_order_items on public.laundry_order_items for select to authenticated using (exists (select 1 from public.laundry_orders lo where lo.id = laundry_order_id and private.has_permission('laundry.read')));
create policy accountant_select_laundry_order_items on public.laundry_order_items for select to authenticated using (exists (select 1 from public.laundry_orders lo where lo.id = laundry_order_id and private.has_permission('ledger.read')));
create policy owner_select_laundry_order_items on public.laundry_order_items for select to authenticated using (exists (select 1 from public.laundry_orders lo where lo.id = laundry_order_id and private.has_role('owner')));

create policy guest_select_own_laundry_order_history on public.laundry_order_status_history for select to authenticated using (exists (select 1 from public.laundry_orders lo where lo.id = laundry_order_id and lo.guest_id = private.current_guest_id()));
create policy dept_select_laundry_order_history on public.laundry_order_status_history for select to authenticated using (exists (select 1 from public.laundry_orders lo where lo.id = laundry_order_id and private.has_permission('laundry.read')));
create policy accountant_select_laundry_order_history on public.laundry_order_status_history for select to authenticated using (exists (select 1 from public.laundry_orders lo where lo.id = laundry_order_id and private.has_permission('ledger.read')));
create policy owner_select_laundry_order_history on public.laundry_order_status_history for select to authenticated using (exists (select 1 from public.laundry_orders lo where lo.id = laundry_order_id and private.has_role('owner')));

create policy dept_select_inventory_movements on public.inventory_movements for select to authenticated using (private.has_permission('inventory.read') and private.has_department_scope(department_id));
create policy finance_select_inventory_movements on public.inventory_movements for select to authenticated using (private.has_permission('inventory.read_cost'));
create policy owner_select_inventory_movements on public.inventory_movements for select to authenticated using (private.has_role('owner'));

create policy finance_select_stock_purchases on public.stock_purchases for select to authenticated using (private.has_permission('inventory.purchase'));
create policy owner_select_stock_purchases on public.stock_purchases for select to authenticated using (private.has_role('owner'));
create policy manager_insert_stock_purchases on public.stock_purchases for insert to authenticated with check (private.has_permission('inventory.purchase'));
create policy manager_update_stock_purchases on public.stock_purchases for update to authenticated using (private.has_permission('inventory.purchase')) with check (private.has_permission('inventory.purchase'));
create policy manager_delete_stock_purchases on public.stock_purchases for delete to authenticated using (private.has_permission('inventory.purchase'));

create policy finance_select_stock_purchase_items on public.stock_purchase_items for select to authenticated using (exists (select 1 from public.stock_purchases sp where sp.id = stock_purchase_id and private.has_permission('inventory.purchase')));
create policy owner_select_stock_purchase_items on public.stock_purchase_items for select to authenticated using (exists (select 1 from public.stock_purchases sp where sp.id = stock_purchase_id and private.has_role('owner')));
create policy manager_insert_stock_purchase_items on public.stock_purchase_items for insert to authenticated with check (private.has_permission('inventory.purchase'));
create policy manager_delete_stock_purchase_items on public.stock_purchase_items for delete to authenticated using (private.has_permission('inventory.purchase'));

create policy dept_select_stock_adjustments on public.stock_adjustments for select to authenticated using (
  private.has_permission('inventory.read') and exists (select 1 from public.inventory_items i join public.inventory_categories ic on ic.id = i.category_id where i.id = item_id and private.has_department_scope(ic.department_id))
);
create policy finance_select_stock_adjustments on public.stock_adjustments for select to authenticated using (private.has_permission('inventory.adjust'));
create policy manager_update_stock_adjustments on public.stock_adjustments for update to authenticated using (private.has_permission('inventory.adjust')) with check (private.has_permission('inventory.adjust'));
create policy owner_select_stock_adjustments on public.stock_adjustments for select to authenticated using (private.has_role('owner'));

create policy dept_select_stock_alerts on public.stock_alerts for select to authenticated using (
  private.has_permission('inventory.read') and exists (select 1 from public.inventory_items i join public.inventory_categories ic on ic.id = i.category_id where i.id = item_id and private.has_department_scope(ic.department_id))
);
create policy finance_select_stock_alerts on public.stock_alerts for select to authenticated using (private.has_permission('inventory.read_cost'));
create policy manager_update_stock_alerts on public.stock_alerts for update to authenticated using (private.has_permission('inventory.manage')) with check (private.has_permission('inventory.manage'));
create policy owner_select_stock_alerts on public.stock_alerts for select to authenticated using (private.has_role('owner'));

create policy self_select_shifts on public.shifts for select to authenticated using (private.has_department_scope(department_id));
create policy owner_select_shifts on public.shifts for select to authenticated using (private.has_role('owner'));
create policy manager_insert_shifts on public.shifts for insert to authenticated with check (private.has_permission('shifts.manage'));
create policy manager_update_shifts on public.shifts for update to authenticated using (private.has_permission('shifts.manage')) with check (private.has_permission('shifts.manage'));
create policy manager_delete_shifts on public.shifts for delete to authenticated using (private.has_permission('shifts.manage'));

create policy self_select_staff_shift_assignments on public.staff_shift_assignments for select to authenticated using (staff_id = private.current_staff_id());
create policy dept_select_staff_shift_assignments on public.staff_shift_assignments for select to authenticated using (private.has_permission('shifts.read') and exists (select 1 from public.shifts s where s.id = shift_id and private.has_department_scope(s.department_id)));
create policy owner_select_staff_shift_assignments on public.staff_shift_assignments for select to authenticated using (private.has_role('owner'));
create policy manager_insert_staff_shift_assignments on public.staff_shift_assignments for insert to authenticated with check (private.has_permission('shifts.manage'));
create policy manager_update_staff_shift_assignments on public.staff_shift_assignments for update to authenticated using (private.has_permission('shifts.manage')) with check (private.has_permission('shifts.manage'));
create policy manager_delete_staff_shift_assignments on public.staff_shift_assignments for delete to authenticated using (private.has_permission('shifts.manage'));

create policy self_select_attendance_records on public.attendance_records for select to authenticated using (staff_id = private.current_staff_id());
create policy frontdesk_select_attendance_records on public.attendance_records for select to authenticated using (private.has_permission('attendance.read_department'));
create policy owner_select_attendance_records on public.attendance_records for select to authenticated using (private.has_role('owner'));
create policy manager_update_attendance_records on public.attendance_records for update to authenticated using (private.has_permission('attendance.adjust')) with check (private.has_permission('attendance.adjust'));

create policy staff_select_own_handovers on public.shift_handovers for select to authenticated using (outgoing_staff_id = private.current_staff_id() or incoming_staff_id = private.current_staff_id());
create policy dept_select_shift_handovers on public.shift_handovers for select to authenticated using (private.has_permission('handover.read') and private.has_department_scope(department_id));
create policy finance_select_shift_handovers on public.shift_handovers for select to authenticated using (private.has_permission('audit.read_finance'));
create policy owner_select_shift_handovers on public.shift_handovers for select to authenticated using (private.has_role('owner'));
create policy manager_insert_shift_handovers on public.shift_handovers for insert to authenticated with check (private.has_permission('handover.create'));
create policy manager_update_shift_handovers on public.shift_handovers for update to authenticated using (private.has_permission('handover.create')) with check (private.has_permission('handover.create'));

create policy self_select_staff_activity_logs on public.staff_activity_logs for select to authenticated using (staff_id = private.current_staff_id());
create policy manager_select_staff_activity_logs on public.staff_activity_logs for select to authenticated using (private.has_permission('audit.read'));
create policy finance_select_staff_activity_logs on public.staff_activity_logs for select to authenticated using (private.has_permission('audit.read_finance'));
create policy owner_select_staff_activity_logs on public.staff_activity_logs for select to authenticated using (private.has_role('owner'));
