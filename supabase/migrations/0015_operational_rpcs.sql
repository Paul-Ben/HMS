create or replace function private.actor_id_from_jwt()
returns uuid
language sql
stable
set search_path = public, private, pg_temp
as $$
  select coalesce(
    auth.uid(),
    (
      select sp.profile_id
      from public.staff_profiles sp
      where sp.id = nullif(coalesce(current_setting('request.jwt.claims', true), '{}')::jsonb ->> 'staff_id', '')::uuid
    )
  );
$$;

create or replace function private.rpc_actor_staff_id()
returns uuid
language sql
stable
set search_path = public, private, pg_temp
as $$
  select coalesce(
    private.current_staff_id(),
    (
      select sp.id
      from public.staff_profiles sp
      where sp.profile_id = private.rpc_actor_profile_id()
        and sp.employment_status = 'active'::public.employment_status
      limit 1
    ),
    nullif(coalesce(current_setting('request.jwt.claims', true), '{}')::jsonb ->> 'staff_id', '')::uuid
  );
$$;

create or replace function private.ops_uuid_key(p_seed text)
returns uuid
language sql
immutable
set search_path = public, private, pg_temp
as $$
  select (
    substr(md5(p_seed), 1, 8) || '-' ||
    substr(md5(p_seed), 9, 4) || '-' ||
    '4' || substr(md5(p_seed), 14, 3) || '-' ||
    '8' || substr(md5(p_seed), 18, 3) || '-' ||
    substr(md5(p_seed), 21, 12)
  )::uuid;
$$;

create or replace function private.ops_idempotency_key(p_key text)
returns text
language sql
stable
set search_path = public, private, extensions, pg_temp
as $$
  select coalesce(nullif(btrim(p_key), ''), gen_random_uuid()::text);
$$;

create or replace function private.ops_department_id(p_hotel_id uuid, p_key text)
returns uuid
language sql
stable
set search_path = public, private, pg_temp
as $$
  select id from public.departments where key = p_key and is_active;
$$;

create or replace function private.ops_has_staff_or_role_permission(p_permission_key text)
returns boolean
language sql
stable
set search_path = public, private, pg_temp
as $$
  select private.rpc_is_service_role()
      or private.has_permission(p_permission_key)
      or private.rpc_has_role_permission(p_permission_key);
$$;

create or replace function private.ops_require_staff_or_role_permission(p_permission_key text, p_folio_id uuid)
returns void
language plpgsql
stable
set search_path = public, private, pg_temp
as $$
begin
  if private.rpc_is_service_role() then
    return;
  end if;
  if private.has_permission(p_permission_key) then
    return;
  end if;
  if private.rpc_has_role_permission(p_permission_key) and private.guest_owns_folio(p_folio_id) then
    return;
  end if;
  raise exception 'missing required permission: %', p_permission_key using errcode = '42501';
end;
$$;

alter table public.inventory_items drop constraint if exists stock_non_negative;

create or replace function private.guard_inventory_stock()
returns trigger
language plpgsql
set search_path = public, private, pg_temp
as $$
begin
  if new.current_stock < 0 and coalesce(current_setting('ops.allow_negative_stock', true), 'off') <> 'on' then
    raise exception 'stock cannot be negative without an override' using errcode = '23514';
  end if;
  return new;
end;
$$;

drop trigger if exists inventory_items_stock_guard on public.inventory_items;
create trigger inventory_items_stock_guard before update on public.inventory_items for each row execute function private.guard_inventory_stock();

create or replace function private.post_stock_movement(
  p_hotel_id uuid,
  p_item_id uuid,
  p_quantity numeric,
  p_movement_type public.inventory_movement_type,
  p_source_type text,
  p_source_id uuid,
  p_source_line_id uuid default null,
  p_unit_cost numeric default null,
  p_location_id uuid default null,
  p_department_id uuid default null,
  p_reason text default null,
  p_override_allowed boolean default false,
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
  v_movement_id uuid;
  v_key text;
begin
  if p_quantity is null or p_quantity = 0 then
    raise exception 'stock movement quantity cannot be zero' using errcode = '22023';
  end if;
  if p_override_allowed and btrim(coalesce(p_override_reason, '')) = '' then
    raise exception 'stock override reason is required' using errcode = '22023';
  end if;

  v_key := private.ops_idempotency_key(p_idempotency_key);

  select id into v_movement_id
  from public.inventory_movements
  where idempotency_key = v_key;
  if found then
    return v_movement_id;
  end if;

  select * into v_item
  from public.inventory_items
  where id = p_item_id and hotel_id = p_hotel_id
  for update;
  if not found then
    raise exception 'inventory item not found' using errcode = '22023';
  end if;

  if v_item.current_stock + p_quantity < 0 and not p_override_allowed then
    raise exception 'insufficient stock for item %', p_item_id using errcode = '23514';
  end if;

  if v_item.current_stock + p_quantity < 0 then
    perform set_config('ops.allow_negative_stock', 'on', true);
  end if;

  insert into public.inventory_movements (
    hotel_id, item_id, quantity, movement_type, previous_stock, new_stock,
    unit, unit_cost, currency, location_id, department_id, staff_id,
    source_type, source_id, source_line_id, reason, override_allowed,
    override_reason, idempotency_key, occurred_at
  )
  values (
    p_hotel_id, p_item_id, p_quantity, p_movement_type, v_item.current_stock,
    v_item.current_stock + p_quantity, v_item.base_unit,
    coalesce(p_unit_cost, v_item.unit_cost), v_item.currency, p_location_id,
    p_department_id, private.rpc_actor_staff_id(), p_source_type, p_source_id,
    p_source_line_id, p_reason, p_override_allowed, p_override_reason,
    v_key, now()
  )
  on conflict (idempotency_key) do nothing
  returning id into v_movement_id;

  perform set_config('ops.allow_negative_stock', 'off', true);

  if v_movement_id is null then
    select id into v_movement_id from public.inventory_movements where idempotency_key = v_key;
  end if;
  return v_movement_id;
end;
$$;

create or replace function private.log_staff_activity(
  p_staff_id uuid,
  p_activity_type text,
  p_entity_type text,
  p_entity_id uuid,
  p_metadata jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
begin
  if p_staff_id is null then
    return;
  end if;
  insert into public.staff_activity_logs (
    hotel_id, staff_id, activity_type, entity_type, entity_id, metadata
  )
  values (
    private.current_hotel_id(), p_staff_id, p_activity_type, p_entity_type,
    p_entity_id, coalesce(p_metadata, '{}'::jsonb)
  );
end;
$$;

create or replace function private.ops_active_stay(p_guest_id uuid, p_room_id uuid)
returns boolean
language sql
stable
set search_path = public, private, pg_temp
as $$
  select exists (
    select 1
    from public.reservations r
    join public.reservation_room_assignments ra on ra.reservation_id = r.id
    where r.guest_id = p_guest_id
      and ra.room_id = p_room_id
      and r.status = 'checked_in'
      and ra.check_in <= timezone(coalesce((select timezone from public.hotels where id = r.hotel_id), 'Africa/Lagos'), now())::date
      and ra.check_out > timezone(coalesce((select timezone from public.hotels where id = r.hotel_id), 'Africa/Lagos'), now())::date
  );
$$;

create or replace function private.ops_void_charge(
  p_source_type text,
  p_source_id uuid,
  p_reason text,
  p_idempotency_key uuid
)
returns void
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_bill record;
  v_department_key text;
  v_revenue_code text;
  v_net numeric(14,2);
  v_lines jsonb;
  v_ledger_id uuid;
  v_adjustment_id uuid;
begin
  select b.*, f.hotel_id, f.guest_id, d.key as department_key
  into v_bill
  from public.bills b
  join public.folios f on f.id = b.folio_id
  left join public.departments d on d.id = b.department_id
  where b.source_type = p_source_type
    and b.source_id = p_source_id
    and b.status = 'posted'
  order by b.created_at desc
  limit 1;
  if not found then
    return;
  end if;

  v_net := greatest(v_bill.total - v_bill.tax, 0);
  v_revenue_code := case v_department_key
    when 'restaurant' then '4010'
    when 'kitchen' then '4010'
    when 'bar' then '4020'
    when 'laundry' then '4030'
    else '4000'
  end;

  update public.bills
  set status = 'void',
      voided_by = private.rpc_actor_profile_id(),
      voided_at = now(),
      void_reason = p_reason,
      updated_at = now(),
      updated_by = private.rpc_actor_profile_id()
  where id = v_bill.id;

  update public.bill_items
  set is_void = true,
      void_reason = p_reason
  where bill_id = v_bill.id and not is_void;

  v_lines := jsonb_build_array();
  if v_net > 0 then
    v_lines := v_lines || jsonb_build_array(jsonb_build_object('code', v_revenue_code, 'debit', v_net::text));
  end if;
  if v_bill.tax > 0 then
    v_lines := v_lines || jsonb_build_array(jsonb_build_object('code', '2100', 'debit', v_bill.tax::text));
  end if;
  v_lines := v_lines || jsonb_build_array(jsonb_build_object('code', '1100', 'credit', v_bill.total::text));

  v_ledger_id := private.post_ledger(
    v_bill.hotel_id,
    'adjustment',
    'bill_void',
    v_bill.id,
    'void ' || p_source_type || ': ' || p_reason,
    p_idempotency_key::text,
    v_lines,
    v_bill.department_id,
    v_bill.guest_id,
    v_bill.folio_id
  );

  insert into public.financial_adjustments (
    folio_id, type, amount, reason, requester_id, approver_id, status,
    ledger_transaction_id, created_by, updated_by
  )
  values (
    v_bill.folio_id, 'discount', v_bill.total, p_reason,
    private.rpc_actor_profile_id(), private.rpc_actor_profile_id(), 'posted',
    v_ledger_id, private.rpc_actor_profile_id(), private.rpc_actor_profile_id()
  )
  returning id into v_adjustment_id;
end;
$$;

create table if not exists public.laundry_usage_rules (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  laundry_service_id uuid not null references public.laundry_services(id) on delete cascade,
  inventory_item_id uuid not null references public.inventory_items(id) on delete restrict,
  quantity_per_unit numeric(14,3) not null check (quantity_per_unit > 0),
  department_id uuid references public.departments(id) on delete set null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null,
  unique (hotel_id, laundry_service_id, inventory_item_id)
);

alter table public.laundry_usage_rules enable row level security;
revoke all on public.laundry_usage_rules from anon, authenticated;
grant select on public.laundry_usage_rules to authenticated;
grant insert, update, delete on public.laundry_usage_rules to authenticated;

drop policy if exists staff_select_laundry_usage_rules on public.laundry_usage_rules;
create policy staff_select_laundry_usage_rules on public.laundry_usage_rules for select to authenticated using (
  private.has_permission('laundry.read') or private.has_permission('inventory.read')
);
drop policy if exists manager_insert_laundry_usage_rules on public.laundry_usage_rules;
create policy manager_insert_laundry_usage_rules on public.laundry_usage_rules for insert to authenticated with check (
  private.has_permission('laundry.services.manage') or private.has_permission('inventory.manage')
);
drop policy if exists manager_update_laundry_usage_rules on public.laundry_usage_rules;
create policy manager_update_laundry_usage_rules on public.laundry_usage_rules for update to authenticated using (
  private.has_permission('laundry.services.manage') or private.has_permission('inventory.manage')
) with check (
  private.has_permission('laundry.services.manage') or private.has_permission('inventory.manage')
);
drop policy if exists manager_delete_laundry_usage_rules on public.laundry_usage_rules;
create policy manager_delete_laundry_usage_rules on public.laundry_usage_rules for delete to authenticated using (
  private.has_permission('laundry.services.manage') or private.has_permission('inventory.manage')
);
drop policy if exists owner_select_laundry_usage_rules on public.laundry_usage_rules;
create policy owner_select_laundry_usage_rules on public.laundry_usage_rules for select to authenticated using (private.has_role('owner'));

create or replace function private.ops_deduct_service_order_stock(
  p_order_id uuid,
  p_event text,
  p_override_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_order public.service_orders%rowtype;
  v_row record;
  v_deduct_quantity numeric(14,3);
  v_department_id uuid;
  v_override_allowed boolean;
  v_override_reason text;
begin
  select * into v_order from public.service_orders where id = p_order_id for update;
  if not found then
    raise exception 'service order not found' using errcode = '22023';
  end if;
  if v_order.stock_deducted_at is not null then
    return;
  end if;

  v_department_id := private.ops_department_id(v_order.hotel_id, v_order.department::text);
  v_override_allowed := private.rpc_is_service_role() or private.has_permission('inventory.manage');
  v_override_reason := coalesce(nullif(btrim(p_override_reason), ''), 'system stock override');

  if p_event = 'preparing' and v_order.department = 'restaurant' then
    for v_row in
      select soi.id as item_id, soi.quantity as ordered_quantity,
             ri.inventory_item_id, ri.quantity as recipe_quantity,
             fr.yield_quantity
      from public.service_order_items soi
      join public.food_recipes fr on fr.food_product_id = soi.food_product_id
      join public.recipe_ingredients ri on ri.recipe_id = fr.id
      where soi.service_order_id = p_order_id
    loop
      v_deduct_quantity := round(v_row.recipe_quantity * v_row.ordered_quantity / v_row.yield_quantity, 3);
      if v_deduct_quantity > 0 then
        perform private.post_stock_movement(
          v_order.hotel_id, v_row.inventory_item_id, -v_deduct_quantity, 'usage',
          'service_order', v_order.id, v_row.item_id, null, null, v_department_id,
          'recipe usage', v_override_allowed, v_override_reason,
          'service-order:' || v_order.id::text || ':' || v_row.item_id::text || ':' || v_row.inventory_item_id::text || ':preparing'
        );
      end if;
    end loop;
  elsif p_event = 'delivered' and v_order.department = 'bar' then
    for v_row in
      select soi.id as item_id, soi.quantity as ordered_quantity,
             bp.inventory_item_id, bp.pour_quantity
      from public.service_order_items soi
      join public.bar_products bp on bp.id = soi.bar_product_id
      where soi.service_order_id = p_order_id
        and bp.inventory_item_id is not null
    loop
      v_deduct_quantity := round(coalesce(v_row.pour_quantity, 0) * v_row.ordered_quantity, 3);
      if v_deduct_quantity > 0 then
        perform private.post_stock_movement(
          v_order.hotel_id, v_row.inventory_item_id, -v_deduct_quantity, 'usage',
          'service_order', v_order.id, v_row.item_id, null, null, v_department_id,
          'bar pour', v_override_allowed, v_override_reason,
          'service-order:' || v_order.id::text || ':' || v_row.item_id::text || ':' || v_row.inventory_item_id::text || ':delivered'
        );
      end if;
    end loop;
  end if;

  update public.service_orders
  set stock_deducted_at = now(),
      updated_at = now(),
      updated_by = private.rpc_actor_profile_id()
  where id = p_order_id;
end;
$$;

create or replace function private.ops_reverse_service_order_stock(p_order_id uuid, p_reason text)
returns void
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_movement record;
  v_order public.service_orders%rowtype;
begin
  select * into v_order from public.service_orders where id = p_order_id;
  for v_movement in
    select * from public.inventory_movements
    where source_type = 'service_order' and source_id = p_order_id and movement_type = 'usage'
  loop
    perform private.post_stock_movement(
      v_movement.hotel_id, v_movement.item_id, -v_movement.quantity, 'reversal',
      'service_order_cancel', p_order_id, v_movement.id, v_movement.unit_cost,
      v_movement.location_id, v_movement.department_id,
      p_reason, false, null,
      'service-order-cancel:' || v_movement.id::text
    );
  end loop;
end;
$$;

create or replace function public.create_service_order(
  p_department public.service_order_department,
  p_order_type public.service_order_type,
  p_folio_id uuid,
  p_items jsonb,
  p_guest_id uuid default null,
  p_room_id uuid default null,
  p_dining_table_id uuid default null,
  p_notes text default null,
  p_idempotency_key text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_folio public.folios%rowtype;
  v_order_id uuid;
  v_idem text;
  v_reference text;
  v_department_id uuid;
  v_guest_id uuid;
  v_item jsonb;
  v_product_type public.service_order_item_type;
  v_food_id uuid;
  v_bar_id uuid;
  v_product_id uuid;
  v_product_name text;
  v_unit_price numeric(14,2);
  v_tax_seed numeric(5,2);
  v_tax_rate numeric(5,2);
  v_quantity numeric(14,3);
  v_discount numeric(14,2);
  v_line_tax numeric(14,2);
  v_line_total numeric(14,2);
  v_subtotal numeric(14,2) := 0;
  v_tax numeric(14,2) := 0;
  v_discount_total numeric(14,2) := 0;
  v_total numeric(14,2);
begin
  perform private.ops_require_staff_or_role_permission('order.create', p_folio_id);

  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'at least one order item is required' using errcode = '22023';
  end if;

  v_idem := private.ops_idempotency_key(p_idempotency_key);
  select id into v_order_id from public.service_orders where idempotency_key = v_idem;
  if found then
    return v_order_id;
  end if;

  select * into v_folio from public.folios where id = p_folio_id for update;
  if not found then
    raise exception 'folio not found' using errcode = '22023';
  end if;
  if v_folio.status not in ('open', 'closed_with_balance') then
    raise exception 'folio does not accept charges' using errcode = '23514';
  end if;

  v_guest_id := coalesce(p_guest_id, v_folio.guest_id);
  if p_order_type = 'room' then
    if v_guest_id is null or p_room_id is null or not private.ops_active_stay(v_guest_id, p_room_id) then
      raise exception 'room orders require an active stay' using errcode = '23514';
    end if;
  elsif p_order_type = 'table' then
    if p_dining_table_id is null or not exists (
      select 1 from public.dining_tables
      where id = p_dining_table_id and hotel_id = v_folio.hotel_id and is_active
    ) then
      raise exception 'valid dining table is required' using errcode = '22023';
    end if;
  end if;

  v_department_id := private.ops_department_id(v_folio.hotel_id, p_department::text);
  if v_department_id is null then
    raise exception 'department not configured for hotel' using errcode = '22023';
  end if;

  v_reference := public.allocate_reference('service_order', 'SORD');

  insert into public.service_orders (
    hotel_id, reference, department, order_type, folio_id, guest_id, room_id,
    dining_table_id, status, currency, notes, idempotency_key, placed_at,
    created_by, updated_by
  )
  values (
    v_folio.hotel_id, v_reference, p_department, p_order_type, p_folio_id,
    v_guest_id, p_room_id, p_dining_table_id, 'pending', v_folio.currency,
    p_notes, v_idem, now(), private.rpc_actor_profile_id(), private.rpc_actor_profile_id()
  )
  on conflict (idempotency_key) do nothing
  returning id into v_order_id;

  if v_order_id is null then
    select id into v_order_id from public.service_orders where idempotency_key = v_idem;
    return v_order_id;
  end if;

  for v_item in select value from jsonb_array_elements(p_items) loop
    v_product_type := coalesce(nullif(v_item ->> 'product_type', ''), p_department::text)::public.service_order_item_type;
    if (p_department = 'restaurant' and v_product_type <> 'food')
       or (p_department = 'bar' and v_product_type <> 'bar') then
      raise exception 'item product type does not match order department' using errcode = '22023';
    end if;

    v_food_id := nullif(v_item ->> 'food_product_id', '')::uuid;
    v_bar_id := nullif(v_item ->> 'bar_product_id', '')::uuid;
    if p_department = 'restaurant' then
      v_product_id := v_food_id;
      if v_product_id is null then
        raise exception 'food_product_id is required' using errcode = '22023';
      end if;
      select name, price, tax_rate into v_product_name, v_unit_price, v_tax_seed
      from public.food_products
      where id = v_product_id and hotel_id = v_folio.hotel_id and is_active and is_available;
    else
      v_product_id := v_bar_id;
      if v_product_id is null then
        raise exception 'bar_product_id is required' using errcode = '22023';
      end if;
      select name, price, tax_rate into v_product_name, v_unit_price, v_tax_seed
      from public.bar_products
      where id = v_product_id and hotel_id = v_folio.hotel_id and is_active and is_available;
    end if;
    if not found then
      raise exception 'product not found or unavailable' using errcode = '22023';
    end if;

    v_quantity := nullif(v_item ->> 'quantity', '')::numeric;
    if v_quantity is null or v_quantity <= 0 then
      raise exception 'quantity must be positive' using errcode = '22023';
    end if;
    v_tax_rate := coalesce(nullif(v_item ->> 'tax_rate', '')::numeric, v_tax_seed, 0);
    v_discount := coalesce(nullif(v_item ->> 'discount', '')::numeric, 0);
    if v_tax_rate < 0 or v_tax_rate > 100 or v_discount < 0 then
      raise exception 'invalid tax rate or discount' using errcode = '22023';
    end if;
    v_line_tax := round(round(v_quantity * v_unit_price, 2) * v_tax_rate / 100, 2);
    v_line_total := round(round(v_quantity * v_unit_price, 2) - v_discount + v_line_tax, 2);
    if v_line_total < 0 then
      raise exception 'order line total cannot be negative' using errcode = '22023';
    end if;

    insert into public.service_order_items (
      service_order_id, product_type, food_product_id, bar_product_id,
      description, unit_price, quantity, tax_rate, tax_amount, discount,
      total, notes, modifiers, created_by
    )
    values (
      v_order_id, v_product_type, v_food_id, v_bar_id, v_product_name,
      v_unit_price, v_quantity, v_tax_rate, v_line_tax, v_discount,
      v_line_total, v_item ->> 'notes', coalesce(v_item -> 'modifiers', '{}'::jsonb),
      private.rpc_actor_profile_id()
    );

    v_subtotal := v_subtotal + round(v_quantity * v_unit_price, 2);
    v_tax := v_tax + v_line_tax;
    v_discount_total := v_discount_total + v_discount;
  end loop;

  v_total := v_subtotal - v_discount_total + v_tax;
  update public.service_orders
  set subtotal = v_subtotal, tax = v_tax, discount = v_discount_total, total = v_total
  where id = v_order_id;

  perform private.log_staff_activity(
    private.rpc_actor_staff_id(), 'service_order_created', 'service_order', v_order_id,
    jsonb_build_object('reference', v_reference, 'department', p_department, 'total', v_total)
  );
  return v_order_id;
end;
$$;

create or replace function public.accept_service_order(p_service_order_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_order public.service_orders%rowtype;
begin
  select * into v_order from public.service_orders where id = p_service_order_id for update;
  if not found then
    raise exception 'service order not found' using errcode = '22023';
  end if;
  if v_order.department = 'restaurant' then
    perform private.rpc_require_permission('order.kitchen.update');
  else
    perform private.rpc_require_permission('order.bar.update');
  end if;
  if v_order.status <> 'pending' then
    raise exception 'only pending service orders can be accepted' using errcode = '23514';
  end if;
  update public.service_orders
  set status = 'accepted', accepted_at = now(),
      assigned_to = coalesce(assigned_to, private.rpc_actor_staff_id()),
      updated_at = now(), updated_by = private.rpc_actor_profile_id()
  where id = p_service_order_id;
  perform private.log_staff_activity(
    private.rpc_actor_staff_id(), 'service_order_accepted', 'service_order', p_service_order_id,
    jsonb_build_object('reference', v_order.reference)
  );
  return p_service_order_id;
end;
$$;

create or replace function public.start_service_order_preparation(
  p_service_order_id uuid,
  p_override_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_order public.service_orders%rowtype;
begin
  select * into v_order from public.service_orders where id = p_service_order_id for update;
  if not found then
    raise exception 'service order not found' using errcode = '22023';
  end if;
  if v_order.department = 'restaurant' then
    perform private.rpc_require_permission('order.kitchen.update');
  else
    perform private.rpc_require_permission('order.bar.update');
  end if;
  if v_order.status <> 'accepted' then
    raise exception 'only accepted service orders can start preparation' using errcode = '23514';
  end if;
  if v_order.department = 'restaurant' then
    perform private.ops_deduct_service_order_stock(p_service_order_id, 'preparing', p_override_reason);
  end if;
  update public.service_orders
  set status = 'preparing', preparing_at = now(),
      updated_at = now(), updated_by = private.rpc_actor_profile_id()
  where id = p_service_order_id;
  return p_service_order_id;
end;
$$;

create or replace function public.mark_service_order_ready(p_service_order_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_order public.service_orders%rowtype;
begin
  select * into v_order from public.service_orders where id = p_service_order_id for update;
  if not found then
    raise exception 'service order not found' using errcode = '22023';
  end if;
  if v_order.department = 'restaurant' then
    perform private.rpc_require_permission('order.kitchen.update');
  else
    perform private.rpc_require_permission('order.bar.update');
  end if;
  if v_order.status <> 'preparing' then
    raise exception 'only preparing service orders can be marked ready' using errcode = '23514';
  end if;
  update public.service_orders
  set status = 'ready', ready_at = now(),
      updated_at = now(), updated_by = private.rpc_actor_profile_id()
  where id = p_service_order_id;
  return p_service_order_id;
end;
$$;

create or replace function public.deliver_service_order(
  p_service_order_id uuid,
  p_override_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_order public.service_orders%rowtype;
begin
  select * into v_order from public.service_orders where id = p_service_order_id for update;
  if not found then
    raise exception 'service order not found' using errcode = '22023';
  end if;
  perform private.rpc_require_any_permission(array['order.deliver', 'order.bar.update']);
  if v_order.status <> 'ready' then
    raise exception 'only ready service orders can be delivered' using errcode = '23514';
  end if;
  if v_order.department = 'bar' then
    perform private.ops_deduct_service_order_stock(p_service_order_id, 'delivered', p_override_reason);
  end if;
  update public.service_orders
  set status = 'delivered', delivered_at = now(),
      updated_at = now(), updated_by = private.rpc_actor_profile_id()
  where id = p_service_order_id;
  perform private.log_staff_activity(
    private.rpc_actor_staff_id(), 'service_order_delivered', 'service_order', p_service_order_id,
    jsonb_build_object('reference', v_order.reference)
  );
  return p_service_order_id;
end;
$$;

create or replace function public.close_service_order(p_service_order_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_order public.service_orders%rowtype;
  v_department_id uuid;
  v_bill_id uuid;
  v_tax_rate numeric(10,4);
begin
  select * into v_order from public.service_orders where id = p_service_order_id for update;
  if not found then
    raise exception 'service order not found' using errcode = '22023';
  end if;
  perform private.rpc_require_any_permission(array['order.deliver', 'folio.charge']);
  if v_order.status = 'closed' then
    return p_service_order_id;
  end if;
  if v_order.status <> 'delivered' then
    raise exception 'only delivered service orders can be closed' using errcode = '23514';
  end if;

  v_department_id := private.ops_department_id(v_order.hotel_id, v_order.department::text);
  v_tax_rate := case when v_order.subtotal > 0 then round(v_order.tax / v_order.subtotal * 100, 4) else 0 end;

  v_bill_id := public.post_bill_item(
    v_order.folio_id,
    v_department_id,
    v_order.reference || ' - ' || v_order.department::text || ' service order',
    1,
    v_order.subtotal + v_order.discount,
    v_tax_rate,
    v_order.discount,
    'service_order',
    p_service_order_id,
    private.ops_uuid_key('service-order-bill:' || v_order.id::text)::text
  );

  update public.service_orders
  set status = 'closed', closed_at = now(),
      updated_at = now(), updated_by = private.rpc_actor_profile_id()
  where id = p_service_order_id;
  perform private.log_staff_activity(
    private.rpc_actor_staff_id(), 'service_order_closed', 'service_order', p_service_order_id,
    jsonb_build_object('reference', v_order.reference, 'bill_item_id', v_bill_id)
  );
  return p_service_order_id;
end;
$$;

create or replace function public.cancel_service_order(
  p_service_order_id uuid,
  p_reason text,
  p_override_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_order public.service_orders%rowtype;
begin
  select * into v_order from public.service_orders where id = p_service_order_id for update;
  if not found then
    raise exception 'service order not found' using errcode = '22023';
  end if;
  perform private.rpc_require_permission('order.cancel');
  if btrim(coalesce(p_reason, '')) = '' then
    raise exception 'cancellation reason is required' using errcode = '22023';
  end if;
  if v_order.status not in ('pending', 'accepted', 'preparing', 'ready') then
    raise exception 'service order cannot be cancelled in its current status' using errcode = '23514';
  end if;
  if v_order.stock_deducted_at is not null then
    perform private.ops_reverse_service_order_stock(p_service_order_id, p_reason);
  end if;
  update public.service_orders
  set status = 'cancelled', cancelled_at = now(), cancel_reason = p_reason,
      updated_at = now(), updated_by = private.rpc_actor_profile_id()
  where id = p_service_order_id;
  perform private.log_staff_activity(
    private.rpc_actor_staff_id(), 'service_order_cancelled', 'service_order', p_service_order_id,
    jsonb_build_object('reference', v_order.reference, 'reason', p_reason)
  );
  return p_service_order_id;
end;
$$;

create or replace function private.ops_deduct_laundry_stock(
  p_laundry_order_id uuid,
  p_override_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_order public.laundry_orders%rowtype;
  v_row record;
  v_deduct_quantity numeric(14,3);
  v_department_id uuid;
  v_override_allowed boolean;
  v_override_reason text;
begin
  select * into v_order from public.laundry_orders where id = p_laundry_order_id for update;
  if not found then
    raise exception 'laundry order not found' using errcode = '22023';
  end if;
  if v_order.stock_deducted_at is not null then
    return;
  end if;

  v_department_id := private.ops_department_id(v_order.hotel_id, 'laundry');
  v_override_allowed := private.rpc_is_service_role() or private.has_permission('inventory.manage');
  v_override_reason := coalesce(nullif(btrim(p_override_reason), ''), 'system stock override');

  for v_row in
    select loi.id as item_id, loi.laundry_service_id, loi.quantity_received,
           lur.inventory_item_id, lur.quantity_per_unit, lur.department_id as rule_department_id
    from public.laundry_order_items loi
    join public.laundry_usage_rules lur
      on lur.laundry_service_id = loi.laundry_service_id
     and lur.hotel_id = v_order.hotel_id
     and lur.is_active
    where loi.laundry_order_id = p_laundry_order_id
  loop
    v_deduct_quantity := round(v_row.quantity_per_unit * v_row.quantity_received, 3);
    if v_deduct_quantity > 0 then
      perform private.post_stock_movement(
        v_order.hotel_id, v_row.inventory_item_id, -v_deduct_quantity, 'usage',
        'laundry_order', v_order.id, v_row.item_id, null, null,
        coalesce(v_row.rule_department_id, v_department_id), 'laundry supplies',
        v_override_allowed, v_override_reason,
        'laundry-order:' || v_order.id::text || ':' || v_row.item_id::text || ':' || v_row.inventory_item_id::text || ':processing'
      );
    end if;
  end loop;

  update public.laundry_orders
  set stock_deducted_at = now(),
      updated_at = now(),
      updated_by = private.rpc_actor_profile_id()
  where id = p_laundry_order_id;
end;
$$;

create or replace function private.ops_reverse_laundry_stock(p_laundry_order_id uuid, p_reason text)
returns void
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_movement record;
begin
  for v_movement in
    select * from public.inventory_movements
    where source_type = 'laundry_order' and source_id = p_laundry_order_id and movement_type = 'usage'
  loop
    perform private.post_stock_movement(
      v_movement.hotel_id, v_movement.item_id, -v_movement.quantity, 'reversal',
      'laundry_order_cancel', p_laundry_order_id, v_movement.id, v_movement.unit_cost,
      v_movement.location_id, v_movement.department_id, p_reason, false, null,
      'laundry-order-cancel:' || v_movement.id::text
    );
  end loop;
end;
$$;

create or replace function public.create_laundry_order(
  p_folio_id uuid,
  p_items jsonb,
  p_guest_id uuid default null,
  p_room_id uuid default null,
  p_instructions text default null,
  p_idempotency_key text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_folio public.folios%rowtype;
  v_order_id uuid;
  v_idem text;
  v_reference text;
  v_department_id uuid;
  v_guest_id uuid;
  v_tax_rate numeric(5,2);
  v_item jsonb;
  v_service_id uuid;
  v_service record;
  v_quantity_received numeric(14,3);
  v_quantity_expected numeric(14,3);
  v_price numeric(14,2);
  v_total numeric(14,2);
  v_subtotal numeric(14,2) := 0;
  v_tax numeric(14,2) := 0;
  v_bill_id uuid;
begin
  perform private.ops_require_staff_or_role_permission('laundry.create', p_folio_id);
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'at least one laundry item is required' using errcode = '22023';
  end if;

  v_idem := private.ops_idempotency_key(p_idempotency_key);
  select id into v_order_id from public.laundry_orders where idempotency_key = v_idem;
  if found then
    return v_order_id;
  end if;

  select * into v_folio from public.folios where id = p_folio_id for update;
  if not found then
    raise exception 'folio not found' using errcode = '22023';
  end if;
  if v_folio.status not in ('open', 'closed_with_balance') then
    raise exception 'folio does not accept charges' using errcode = '23514';
  end if;

  v_guest_id := coalesce(p_guest_id, v_folio.guest_id);
  if p_room_id is not null and (v_guest_id is null or not private.ops_active_stay(v_guest_id, p_room_id)) then
    raise exception 'laundry room requests require an active stay' using errcode = '23514';
  end if;

  v_department_id := private.ops_department_id(v_folio.hotel_id, 'laundry');
  if v_department_id is null then
    raise exception 'laundry department not configured for hotel' using errcode = '22023';
  end if;
  select tax_rate into v_tax_rate from public.hotel_settings where hotel_id = v_folio.hotel_id;
  v_tax_rate := coalesce(v_tax_rate, 0);

  v_reference := public.allocate_reference('laundry_order', 'LND');

  insert into public.laundry_orders (
    hotel_id, reference, folio_id, guest_id, room_id, status, instructions,
    currency, assigned_to, received_at, idempotency_key, created_by, updated_by
  )
  values (
    v_folio.hotel_id, v_reference, p_folio_id, v_guest_id, p_room_id, 'received',
    p_instructions, v_folio.currency, private.rpc_actor_staff_id(), now(), v_idem,
    private.rpc_actor_profile_id(), private.rpc_actor_profile_id()
  )
  on conflict (idempotency_key) do nothing
  returning id into v_order_id;

  if v_order_id is null then
    select id into v_order_id from public.laundry_orders where idempotency_key = v_idem;
    return v_order_id;
  end if;

  for v_item in select value from jsonb_array_elements(p_items) loop
    v_service_id := nullif(v_item ->> 'laundry_service_id', '')::uuid;
    if v_service_id is null then
      raise exception 'laundry_service_id is required' using errcode = '22023';
    end if;
    select name, price into v_service
    from public.laundry_services
    where id = v_service_id and hotel_id = v_folio.hotel_id and is_active;
    if not found then
      raise exception 'laundry service not found' using errcode = '22023';
    end if;

    v_quantity_received := nullif(v_item ->> 'quantity_received', '')::numeric;
    v_quantity_expected := coalesce(nullif(v_item ->> 'quantity_expected', '')::numeric, v_quantity_received);
    if v_quantity_received is null or v_quantity_received <= 0 or v_quantity_expected <= 0 then
      raise exception 'laundry quantities must be positive' using errcode = '22023';
    end if;
    v_price := coalesce(nullif(v_item ->> 'price', '')::numeric, v_service.price);
    if v_price < 0 then
      raise exception 'laundry price cannot be negative' using errcode = '22023';
    end if;
    v_total := round(v_price * v_quantity_received, 2);

    insert into public.laundry_order_items (
      laundry_order_id, laundry_service_id, service_name_snapshot,
      quantity_received, quantity_expected, price, total, created_by
    )
    values (
      v_order_id, v_service_id, v_service.name, v_quantity_received,
      v_quantity_expected, v_price, v_total, private.rpc_actor_profile_id()
    );

    v_subtotal := v_subtotal + v_total;
  end loop;

  v_tax := round(v_subtotal * v_tax_rate / 100, 2);
  update public.laundry_orders
  set subtotal = v_subtotal, tax = v_tax, total = v_subtotal + v_tax
  where id = v_order_id;

  v_bill_id := public.post_bill_item(
    p_folio_id,
    v_department_id,
    v_reference || ' - laundry service',
    1,
    v_subtotal,
    v_tax_rate,
    0,
    'laundry_order',
    v_order_id,
    private.ops_uuid_key('laundry-order-bill:' || v_order_id::text)::text
  );

  perform private.log_staff_activity(
    private.rpc_actor_staff_id(), 'laundry_order_created', 'laundry_order', v_order_id,
    jsonb_build_object('reference', v_reference, 'bill_item_id', v_bill_id)
  );
  return v_order_id;
end;
$$;

create or replace function public.start_laundry_processing(
  p_laundry_order_id uuid,
  p_override_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_order public.laundry_orders%rowtype;
begin
  select * into v_order from public.laundry_orders where id = p_laundry_order_id for update;
  if not found then
    raise exception 'laundry order not found' using errcode = '22023';
  end if;
  perform private.rpc_require_permission('laundry.process');
  if v_order.status <> 'received' then
    raise exception 'only received laundry orders can start processing' using errcode = '23514';
  end if;
  perform private.ops_deduct_laundry_stock(p_laundry_order_id, p_override_reason);
  update public.laundry_orders
  set status = 'processing', processing_at = now(),
      assigned_to = coalesce(assigned_to, private.rpc_actor_staff_id()),
      updated_at = now(), updated_by = private.rpc_actor_profile_id()
  where id = p_laundry_order_id;
  return p_laundry_order_id;
end;
$$;

create or replace function public.mark_laundry_ready(p_laundry_order_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_order public.laundry_orders%rowtype;
begin
  select * into v_order from public.laundry_orders where id = p_laundry_order_id for update;
  if not found then
    raise exception 'laundry order not found' using errcode = '22023';
  end if;
  perform private.rpc_require_permission('laundry.process');
  if v_order.status <> 'processing' then
    raise exception 'only processing laundry orders can be marked ready' using errcode = '23514';
  end if;
  update public.laundry_orders
  set status = 'ready', ready_at = now(),
      updated_at = now(), updated_by = private.rpc_actor_profile_id()
  where id = p_laundry_order_id;
  return p_laundry_order_id;
end;
$$;

create or replace function public.deliver_laundry_order(
  p_laundry_order_id uuid,
  p_items jsonb default null
)
returns uuid
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_order public.laundry_orders%rowtype;
  v_item jsonb;
  v_item_id uuid;
  v_quantity_delivered numeric(14,3);
  v_difference numeric(14,3);
begin
  select * into v_order from public.laundry_orders where id = p_laundry_order_id for update;
  if not found then
    raise exception 'laundry order not found' using errcode = '22023';
  end if;
  perform private.rpc_require_permission('laundry.deliver');
  if v_order.status <> 'ready' then
    raise exception 'only ready laundry orders can be delivered' using errcode = '23514';
  end if;

  if p_items is not null then
    if jsonb_typeof(p_items) <> 'array' then
      raise exception 'delivery items must be an array' using errcode = '22023';
    end if;
    for v_item in select value from jsonb_array_elements(p_items) loop
      v_item_id := nullif(v_item ->> 'laundry_order_item_id', '')::uuid;
      v_quantity_delivered := nullif(v_item ->> 'quantity_delivered', '')::numeric;
      if v_item_id is null or v_quantity_delivered is null or v_quantity_delivered < 0 then
        raise exception 'invalid laundry delivery item' using errcode = '22023';
      end if;
      select quantity_expected - v_quantity_delivered into v_difference
      from public.laundry_order_items
      where id = v_item_id and laundry_order_id = p_laundry_order_id;
      if not found then
        raise exception 'laundry order item not found' using errcode = '22023';
      end if;
      update public.laundry_order_items
      set quantity_delivered = v_quantity_delivered,
          discrepancy_note = coalesce(
            nullif(v_item ->> 'discrepancy_note', ''),
            case when v_difference <> 0 then 'quantity discrepancy' else null end
          )
      where id = v_item_id;
    end loop;
  else
    update public.laundry_order_items
    set quantity_delivered = quantity_expected
    where laundry_order_id = p_laundry_order_id and quantity_delivered is null;
  end if;

  update public.laundry_orders
  set status = 'delivered', delivered_at = now(),
      updated_at = now(), updated_by = private.rpc_actor_profile_id()
  where id = p_laundry_order_id;
  perform private.log_staff_activity(
    private.rpc_actor_staff_id(), 'laundry_order_delivered', 'laundry_order', p_laundry_order_id,
    jsonb_build_object('reference', v_order.reference)
  );
  return p_laundry_order_id;
end;
$$;

create or replace function public.cancel_laundry_order(
  p_laundry_order_id uuid,
  p_reason text
)
returns uuid
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_order public.laundry_orders%rowtype;
begin
  select * into v_order from public.laundry_orders where id = p_laundry_order_id for update;
  if not found then
    raise exception 'laundry order not found' using errcode = '22023';
  end if;
  perform private.rpc_require_any_permission(array['laundry.create', 'laundry.process']);
  if btrim(coalesce(p_reason, '')) = '' then
    raise exception 'cancellation reason is required' using errcode = '22023';
  end if;
  if v_order.status not in ('received', 'processing', 'ready') then
    raise exception 'laundry order cannot be cancelled in its current status' using errcode = '23514';
  end if;
  if v_order.stock_deducted_at is not null then
    perform private.ops_reverse_laundry_stock(p_laundry_order_id, p_reason);
  end if;
  perform private.ops_void_charge(
    'laundry_order', p_laundry_order_id, p_reason,
    private.ops_uuid_key('laundry-order-void:' || p_laundry_order_id::text)
  );
  update public.laundry_orders
  set status = 'cancelled', cancelled_at = now(), cancel_reason = p_reason,
      updated_at = now(), updated_by = private.rpc_actor_profile_id()
  where id = p_laundry_order_id;
  perform private.log_staff_activity(
    private.rpc_actor_staff_id(), 'laundry_order_cancelled', 'laundry_order', p_laundry_order_id,
    jsonb_build_object('reference', v_order.reference, 'reason', p_reason)
  );
  return p_laundry_order_id;
end;
$$;

revoke all on function public.create_service_order(public.service_order_department, public.service_order_type, uuid, jsonb, uuid, uuid, uuid, text, text) from public, anon;
grant execute on function public.create_service_order(public.service_order_department, public.service_order_type, uuid, jsonb, uuid, uuid, uuid, text, text) to authenticated, service_role;

revoke all on function public.accept_service_order(uuid) from public, anon;
grant execute on function public.accept_service_order(uuid) to authenticated, service_role;

revoke all on function public.start_service_order_preparation(uuid, text) from public, anon;
grant execute on function public.start_service_order_preparation(uuid, text) to authenticated, service_role;

revoke all on function public.mark_service_order_ready(uuid) from public, anon;
grant execute on function public.mark_service_order_ready(uuid) to authenticated, service_role;

revoke all on function public.deliver_service_order(uuid, text) from public, anon;
grant execute on function public.deliver_service_order(uuid, text) to authenticated, service_role;

revoke all on function public.close_service_order(uuid) from public, anon;
grant execute on function public.close_service_order(uuid) to authenticated, service_role;

revoke all on function public.cancel_service_order(uuid, text, text) from public, anon;
grant execute on function public.cancel_service_order(uuid, text, text) to authenticated, service_role;

revoke all on function public.create_laundry_order(uuid, jsonb, uuid, uuid, text, text) from public, anon;
grant execute on function public.create_laundry_order(uuid, jsonb, uuid, uuid, text, text) to authenticated, service_role;

revoke all on function public.start_laundry_processing(uuid, text) from public, anon;
grant execute on function public.start_laundry_processing(uuid, text) to authenticated, service_role;

revoke all on function public.mark_laundry_ready(uuid) from public, anon;
grant execute on function public.mark_laundry_ready(uuid) to authenticated, service_role;

revoke all on function public.deliver_laundry_order(uuid, jsonb) from public, anon;
grant execute on function public.deliver_laundry_order(uuid, jsonb) to authenticated, service_role;

revoke all on function public.cancel_laundry_order(uuid, text) from public, anon;
grant execute on function public.cancel_laundry_order(uuid, text) to authenticated, service_role;
