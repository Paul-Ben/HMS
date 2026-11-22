do $$
begin
  create type public.service_order_department as enum ('restaurant', 'bar');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.service_order_status as enum ('pending', 'accepted', 'preparing', 'ready', 'delivered', 'closed', 'cancelled');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.service_order_item_type as enum ('food', 'bar');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.service_order_type as enum ('room', 'table', 'walk_in');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.dining_table_status as enum ('available', 'occupied', 'reserved', 'cleaning');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.laundry_order_status as enum ('received', 'processing', 'ready', 'delivered', 'cancelled');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.inventory_location_type as enum ('store', 'bar', 'kitchen', 'laundry');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.inventory_movement_type as enum ('opening_stock', 'purchase', 'usage', 'wastage', 'expiry', 'transfer_in', 'transfer_out', 'adjustment', 'reversal');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.stock_purchase_status as enum ('draft', 'received', 'cancelled');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.stock_adjustment_status as enum ('pending', 'approved', 'rejected', 'posted');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.stock_alert_status as enum ('open', 'acknowledged', 'resolved');
exception when duplicate_object then null;
end $$;

create table public.suppliers (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  name text not null,
  contacts jsonb not null default '{}'::jsonb,
  address jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id) on delete set null,
  unique (hotel_id, name)
);

create table public.inventory_categories (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  name text not null,
  department_id uuid references public.departments(id) on delete set null,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id) on delete set null,
  unique (hotel_id, name)
);

create table public.inventory_locations (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  name text not null,
  type public.inventory_location_type not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id) on delete set null,
  unique (hotel_id, name)
);

create table public.inventory_items (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  sku text not null,
  category_id uuid not null references public.inventory_categories(id) on delete restrict,
  name text not null,
  description text,
  base_unit text not null,
  current_stock numeric(14,3) not null default 0,
  reorder_level numeric(14,3) not null default 0 check (reorder_level >= 0),
  unit_cost numeric(14,2) not null default 0 check (unit_cost >= 0),
  currency text not null default 'NGN',
  track_expiry boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id) on delete set null,
  constraint stock_non_negative check (current_stock >= 0),
  unique (hotel_id, sku)
);

create table public.food_categories (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  name text not null,
  slug text not null,
  description text,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id) on delete set null,
  unique (hotel_id, name),
  unique (hotel_id, slug)
);

create table public.food_products (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  food_category_id uuid not null references public.food_categories(id) on delete restrict,
  name text not null,
  description text,
  sku text,
  price numeric(14,2) not null check (price >= 0),
  currency text not null default 'NGN',
  photo_path text,
  prep_minutes integer check (prep_minutes >= 0),
  is_available boolean not null default true,
  unavailable_reason text,
  tax_rate numeric(5,2) not null default 0 check (tax_rate between 0 and 100),
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id) on delete set null,
  unique (hotel_id, sku)
);

create table public.food_recipes (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  food_product_id uuid not null unique references public.food_products(id) on delete cascade,
  yield_quantity numeric(14,3) not null check (yield_quantity > 0),
  notes text,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id) on delete set null
);

create table public.recipe_ingredients (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references public.food_recipes(id) on delete cascade,
  inventory_item_id uuid not null references public.inventory_items(id) on delete restrict,
  quantity numeric(14,3) not null check (quantity > 0),
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null,
  unique (recipe_id, inventory_item_id)
);

create table public.bar_categories (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  name text not null,
  slug text not null,
  description text,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id) on delete set null,
  unique (hotel_id, name),
  unique (hotel_id, slug)
);

create table public.bar_products (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  bar_category_id uuid not null references public.bar_categories(id) on delete restrict,
  inventory_item_id uuid references public.inventory_items(id) on delete set null,
  name text not null,
  description text,
  price numeric(14,2) not null check (price >= 0),
  currency text not null default 'NGN',
  pour_quantity numeric(14,3) check (pour_quantity > 0),
  photo_path text,
  is_available boolean not null default true,
  unavailable_reason text,
  tax_rate numeric(5,2) not null default 0 check (tax_rate between 0 and 100),
  is_age_restricted boolean not null default false,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id) on delete set null
);

create table public.dining_tables (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  label text not null,
  area text,
  capacity integer not null check (capacity > 0),
  status public.dining_table_status not null default 'available',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id) on delete set null,
  unique (hotel_id, label)
);

create table public.service_orders (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  reference text not null unique,
  department public.service_order_department not null,
  order_type public.service_order_type not null,
  folio_id uuid not null references public.folios(id) on delete restrict,
  guest_id uuid references public.guests(id) on delete restrict,
  room_id uuid references public.rooms(id) on delete restrict,
  dining_table_id uuid references public.dining_tables(id) on delete restrict,
  status public.service_order_status not null default 'pending',
  assigned_to uuid references public.staff_profiles(id) on delete set null,
  subtotal numeric(14,2) not null default 0 check (subtotal >= 0),
  tax numeric(14,2) not null default 0 check (tax >= 0),
  discount numeric(14,2) not null default 0 check (discount >= 0),
  total numeric(14,2) not null default 0 check (total >= 0),
  currency text not null default 'NGN',
  notes text,
  placed_at timestamptz not null default now(),
  accepted_at timestamptz,
  preparing_at timestamptz,
  ready_at timestamptz,
  delivered_at timestamptz,
  closed_at timestamptz,
  cancelled_at timestamptz,
  stock_deducted_at timestamptz,
  cancelled_by uuid references public.profiles(id) on delete set null,
  cancel_reason text,
  idempotency_key text unique,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id) on delete set null
);

create table public.service_order_items (
  id uuid primary key default gen_random_uuid(),
  service_order_id uuid not null references public.service_orders(id) on delete cascade,
  product_type public.service_order_item_type not null,
  food_product_id uuid references public.food_products(id) on delete restrict,
  bar_product_id uuid references public.bar_products(id) on delete restrict,
  description text not null,
  unit_price numeric(14,2) not null check (unit_price >= 0),
  quantity numeric(14,3) not null check (quantity > 0),
  tax_rate numeric(5,2) not null default 0 check (tax_rate between 0 and 100),
  tax_amount numeric(14,2) not null default 0 check (tax_amount >= 0),
  discount numeric(14,2) not null default 0 check (discount >= 0),
  total numeric(14,2) not null check (total >= 0),
  notes text,
  modifiers jsonb not null default '{}'::jsonb,
  stock_deducted_at timestamptz,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null,
  check ((food_product_id is null) <> (bar_product_id is null))
);

create table public.service_order_status_history (
  id uuid primary key default gen_random_uuid(),
  service_order_id uuid not null references public.service_orders(id) on delete cascade,
  from_status public.service_order_status,
  to_status public.service_order_status not null,
  reason text,
  actor_id uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.laundry_services (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  name text not null,
  category text,
  description text,
  price numeric(14,2) not null check (price >= 0),
  currency text not null default 'NGN',
  unit text,
  turnaround_minutes integer check (turnaround_minutes >= 0),
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id) on delete set null,
  unique (hotel_id, name)
);

create table public.laundry_orders (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  reference text not null unique,
  folio_id uuid not null references public.folios(id) on delete restrict,
  guest_id uuid references public.guests(id) on delete restrict,
  room_id uuid references public.rooms(id) on delete restrict,
  status public.laundry_order_status not null default 'received',
  instructions text,
  subtotal numeric(14,2) not null default 0 check (subtotal >= 0),
  tax numeric(14,2) not null default 0 check (tax >= 0),
  discount numeric(14,2) not null default 0 check (discount >= 0),
  total numeric(14,2) not null default 0 check (total >= 0),
  currency text not null default 'NGN',
  assigned_to uuid references public.staff_profiles(id) on delete set null,
  received_at timestamptz,
  processing_at timestamptz,
  ready_at timestamptz,
  delivered_at timestamptz,
  cancelled_at timestamptz,
  stock_deducted_at timestamptz,
  cancelled_by uuid references public.profiles(id) on delete set null,
  cancel_reason text,
  idempotency_key text unique,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id) on delete set null
);

create table public.laundry_order_items (
  id uuid primary key default gen_random_uuid(),
  laundry_order_id uuid not null references public.laundry_orders(id) on delete cascade,
  laundry_service_id uuid not null references public.laundry_services(id) on delete restrict,
  service_name_snapshot text not null,
  quantity_received numeric(14,3) not null check (quantity_received > 0),
  quantity_expected numeric(14,3) not null check (quantity_expected > 0),
  quantity_delivered numeric(14,3) check (quantity_delivered >= 0),
  price numeric(14,2) not null check (price >= 0),
  total numeric(14,2) not null check (total >= 0),
  discrepancy_note text,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null,
  check (quantity_delivered is null or quantity_delivered = quantity_expected or discrepancy_note is not null)
);

create table public.laundry_order_status_history (
  id uuid primary key default gen_random_uuid(),
  laundry_order_id uuid not null references public.laundry_orders(id) on delete cascade,
  from_status public.laundry_order_status,
  to_status public.laundry_order_status not null,
  reason text,
  actor_id uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.inventory_movements (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  item_id uuid not null references public.inventory_items(id) on delete restrict,
  quantity numeric(14,3) not null check (quantity <> 0),
  movement_type public.inventory_movement_type not null,
  previous_stock numeric(14,3) not null,
  new_stock numeric(14,3) not null,
  unit text not null,
  unit_cost numeric(14,2) check (unit_cost >= 0),
  currency text not null default 'NGN',
  location_id uuid references public.inventory_locations(id) on delete set null,
  department_id uuid references public.departments(id) on delete set null,
  staff_id uuid references public.staff_profiles(id) on delete set null,
  source_type text,
  source_id uuid,
  source_line_id uuid,
  reason text,
  override_allowed boolean not null default false,
  override_reason text,
  idempotency_key text not null unique,
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint inventory_movement_idem unique (idempotency_key),
  check (new_stock = previous_stock + quantity),
  check (not override_allowed or override_reason is not null)
);

create table public.stock_purchases (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  supplier_id uuid not null references public.suppliers(id) on delete restrict,
  invoice_number text,
  purchase_date date,
  subtotal numeric(14,2) not null default 0 check (subtotal >= 0),
  tax numeric(14,2) not null default 0 check (tax >= 0),
  total numeric(14,2) not null default 0 check (total >= 0),
  currency text not null default 'NGN',
  status public.stock_purchase_status not null default 'draft',
  evidence_path text,
  recorded_by uuid references public.profiles(id) on delete set null,
  received_at timestamptz,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id) on delete set null
);

create table public.stock_purchase_items (
  id uuid primary key default gen_random_uuid(),
  stock_purchase_id uuid not null references public.stock_purchases(id) on delete cascade,
  inventory_item_id uuid not null references public.inventory_items(id) on delete restrict,
  quantity numeric(14,3) not null check (quantity > 0),
  unit_cost numeric(14,2) not null check (unit_cost >= 0),
  tax_rate numeric(5,2) not null default 0 check (tax_rate between 0 and 100),
  tax_amount numeric(14,2) not null default 0 check (tax_amount >= 0),
  total numeric(14,2) not null check (total >= 0),
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null
);

create table public.stock_adjustments (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  item_id uuid not null references public.inventory_items(id) on delete restrict,
  quantity numeric(14,3) not null check (quantity <> 0),
  reason text not null,
  requested_by uuid references public.profiles(id) on delete set null,
  approved_by uuid references public.profiles(id) on delete set null,
  status public.stock_adjustment_status not null default 'pending',
  approved_at timestamptz,
  movement_id uuid references public.inventory_movements(id) on delete set null,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id) on delete set null
);

create table public.stock_alerts (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  item_id uuid not null references public.inventory_items(id) on delete restrict,
  threshold_snapshot numeric(14,3) not null,
  status public.stock_alert_status not null default 'open',
  opened_at timestamptz not null default now(),
  acknowledged_at timestamptz,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id) on delete set null
);

create unique index one_open_stock_alert on public.stock_alerts (item_id) where status = 'open';
create index suppliers_hotel_id_active_idx on public.suppliers (hotel_id, is_active);
create index inventory_categories_hotel_id_active_idx on public.inventory_categories (hotel_id, is_active);
create index inventory_locations_hotel_id_active_idx on public.inventory_locations (hotel_id, is_active);
create index inventory_items_hotel_id_active_idx on public.inventory_items (hotel_id, is_active);
create index inventory_items_category_id_idx on public.inventory_items (category_id);
create index inventory_items_low_stock_idx on public.inventory_items (hotel_id, reorder_level) where is_active and current_stock <= reorder_level;
create index food_categories_hotel_id_active_idx on public.food_categories (hotel_id, is_active);
create index food_products_hotel_id_active_idx on public.food_products (hotel_id, is_active);
create index food_products_category_id_idx on public.food_products (food_category_id);
create index recipe_ingredients_inventory_item_id_idx on public.recipe_ingredients (inventory_item_id);
create index bar_categories_hotel_id_active_idx on public.bar_categories (hotel_id, is_active);
create index bar_products_hotel_id_active_idx on public.bar_products (hotel_id, is_active);
create index bar_products_inventory_item_id_idx on public.bar_products (inventory_item_id);
create index dining_tables_hotel_id_active_idx on public.dining_tables (hotel_id, is_active);
create index service_orders_queue_idx on public.service_orders (hotel_id, department, status, placed_at);
create index service_orders_assigned_to_idx on public.service_orders (assigned_to);
create index service_orders_room_id_idx on public.service_orders (room_id);
create index service_orders_folio_id_idx on public.service_orders (folio_id);
create index service_order_items_order_id_idx on public.service_order_items (service_order_id);
create index laundry_services_hotel_id_active_idx on public.laundry_services (hotel_id, is_active);
create index laundry_orders_queue_idx on public.laundry_orders (hotel_id, status, received_at);
create index laundry_orders_folio_id_idx on public.laundry_orders (folio_id);
create index laundry_orders_guest_id_idx on public.laundry_orders (guest_id);
create index laundry_orders_room_id_idx on public.laundry_orders (room_id);
create index laundry_order_items_order_id_idx on public.laundry_order_items (laundry_order_id);
create index inventory_movements_item_occurred_idx on public.inventory_movements (item_id, occurred_at desc);
create index inventory_movements_department_occurred_idx on public.inventory_movements (department_id, occurred_at);
create index inventory_movements_source_idx on public.inventory_movements (source_type, source_id);
create index stock_purchases_hotel_id_status_idx on public.stock_purchases (hotel_id, status);
create index stock_purchases_supplier_id_idx on public.stock_purchases (supplier_id);
create index stock_purchase_items_purchase_id_idx on public.stock_purchase_items (stock_purchase_id);
create index stock_purchase_items_item_id_idx on public.stock_purchase_items (inventory_item_id);
create index stock_adjustments_item_status_idx on public.stock_adjustments (item_id, status);
create index stock_alerts_item_status_idx on public.stock_alerts (item_id, status);

create trigger suppliers_set_updated_at before update on public.suppliers for each row execute function private.set_updated_at();
create trigger inventory_categories_set_updated_at before update on public.inventory_categories for each row execute function private.set_updated_at();
create trigger inventory_locations_set_updated_at before update on public.inventory_locations for each row execute function private.set_updated_at();
create trigger inventory_items_set_updated_at before update on public.inventory_items for each row execute function private.set_updated_at();
create trigger food_categories_set_updated_at before update on public.food_categories for each row execute function private.set_updated_at();
create trigger food_products_set_updated_at before update on public.food_products for each row execute function private.set_updated_at();
create trigger food_recipes_set_updated_at before update on public.food_recipes for each row execute function private.set_updated_at();
create trigger bar_categories_set_updated_at before update on public.bar_categories for each row execute function private.set_updated_at();
create trigger bar_products_set_updated_at before update on public.bar_products for each row execute function private.set_updated_at();
create trigger dining_tables_set_updated_at before update on public.dining_tables for each row execute function private.set_updated_at();
create trigger service_orders_set_updated_at before update on public.service_orders for each row execute function private.set_updated_at();
create trigger laundry_services_set_updated_at before update on public.laundry_services for each row execute function private.set_updated_at();
create trigger laundry_orders_set_updated_at before update on public.laundry_orders for each row execute function private.set_updated_at();
create trigger stock_purchases_set_updated_at before update on public.stock_purchases for each row execute function private.set_updated_at();
create trigger stock_adjustments_set_updated_at before update on public.stock_adjustments for each row execute function private.set_updated_at();
create trigger stock_alerts_set_updated_at before update on public.stock_alerts for each row execute function private.set_updated_at();

create or replace function private.actor_id_from_jwt()
returns uuid
language sql
stable
as $$
  select nullif(coalesce(current_setting('request.jwt.claims', true), '{}')::jsonb ->> 'staff_id', '')::uuid;
$$;

create or replace function private.enforce_service_order_transition()
returns trigger
language plpgsql
as $$
begin
  if new.status is distinct from old.status then
    if not (
      (old.status = 'pending' and new.status in ('accepted', 'cancelled'))
      or (old.status = 'accepted' and new.status in ('preparing', 'cancelled'))
      or (old.status = 'preparing' and new.status in ('ready', 'cancelled'))
      or (old.status = 'ready' and new.status in ('delivered', 'cancelled'))
      or (old.status = 'delivered' and new.status = 'closed')
    ) then
      raise exception 'invalid service order transition: % -> %', old.status, new.status using errcode = '23514';
    end if;
  end if;
  return new;
end;
$$;

create trigger service_orders_transition_guard before update on public.service_orders for each row execute function private.enforce_service_order_transition();

create or replace function private.record_service_order_status_history()
returns trigger
language plpgsql
as $$
begin
  if old.status is distinct from new.status then
    insert into public.service_order_status_history (service_order_id, from_status, to_status, reason, actor_id)
    values (new.id, old.status, new.status, new.cancel_reason, private.actor_id_from_jwt());
  end if;
  return new;
end;
$$;

create trigger service_orders_status_history after update on public.service_orders for each row execute function private.record_service_order_status_history();

create or replace function private.enforce_laundry_order_transition()
returns trigger
language plpgsql
as $$
begin
  if new.status is distinct from old.status then
    if not (
      (old.status = 'received' and new.status in ('processing', 'cancelled'))
      or (old.status = 'processing' and new.status in ('ready', 'cancelled'))
      or (old.status = 'ready' and new.status in ('delivered', 'cancelled'))
    ) then
      raise exception 'invalid laundry order transition: % -> %', old.status, new.status using errcode = '23514';
    end if;
  end if;
  return new;
end;
$$;

create trigger laundry_orders_transition_guard before update on public.laundry_orders for each row execute function private.enforce_laundry_order_transition();

create or replace function private.record_laundry_order_status_history()
returns trigger
language plpgsql
as $$
begin
  if old.status is distinct from new.status then
    insert into public.laundry_order_status_history (laundry_order_id, from_status, to_status, reason, actor_id)
    values (new.id, old.status, new.status, new.cancel_reason, private.actor_id_from_jwt());
  end if;
  return new;
end;
$$;

create trigger laundry_orders_status_history after update on public.laundry_orders for each row execute function private.record_laundry_order_status_history();

create or replace function private.prevent_append_only_mutation()
returns trigger
language plpgsql
as $$
begin
  raise exception '% is append-only', tg_table_name using errcode = '23514';
end;
$$;

create trigger service_order_status_history_append_only before update or delete on public.service_order_status_history for each row execute function private.prevent_append_only_mutation();
create trigger laundry_order_status_history_append_only before update or delete on public.laundry_order_status_history for each row execute function private.prevent_append_only_mutation();
create trigger inventory_movements_append_only before update or delete on public.inventory_movements for each row execute function private.prevent_append_only_mutation();

create or replace function private.sync_stock_from_movement()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_old_cost numeric(14,2);
  v_new_cost numeric(14,2);
  v_reorder_level numeric(14,3);
begin
  select unit_cost, reorder_level into v_old_cost, v_reorder_level
  from public.inventory_items
  where id = new.item_id;

  if new.quantity > 0 and new.movement_type in ('opening_stock', 'purchase', 'transfer_in') and new.unit_cost is not null then
    if new.previous_stock > 0 then
      v_new_cost := round(((new.previous_stock * v_old_cost) + (new.quantity * new.unit_cost)) / (new.previous_stock + new.quantity), 2);
    else
      v_new_cost := new.unit_cost;
    end if;
  else
    v_new_cost := v_old_cost;
  end if;

  update public.inventory_items
  set current_stock = new.new_stock,
      unit_cost = v_new_cost,
      updated_at = now()
  where id = new.item_id;

  if new.new_stock <= v_reorder_level then
    insert into public.stock_alerts (hotel_id, item_id, threshold_snapshot, status, opened_at)
    values (new.hotel_id, new.item_id, v_reorder_level, 'open', now())
    on conflict (item_id) where status = 'open' do nothing;
  else
    update public.stock_alerts
    set status = 'resolved',
        resolved_at = now(),
        updated_at = now()
    where item_id = new.item_id
      and status = 'open';
  end if;

  return null;
end;
$$;

create trigger inventory_movements_sync_stock after insert on public.inventory_movements for each row execute function private.sync_stock_from_movement();

insert into public.number_sequences (scope, prefix, year, current_value)
values
  ('service_order', 'SORD', extract(year from now())::integer, 0),
  ('laundry_order', 'LND', extract(year from now())::integer, 0)
on conflict (scope, prefix, year) do nothing;

alter table public.suppliers enable row level security;
alter table public.inventory_categories enable row level security;
alter table public.inventory_locations enable row level security;
alter table public.inventory_items enable row level security;
alter table public.food_categories enable row level security;
alter table public.food_products enable row level security;
alter table public.food_recipes enable row level security;
alter table public.recipe_ingredients enable row level security;
alter table public.bar_categories enable row level security;
alter table public.bar_products enable row level security;
alter table public.dining_tables enable row level security;
alter table public.service_orders enable row level security;
alter table public.service_order_items enable row level security;
alter table public.service_order_status_history enable row level security;
alter table public.laundry_services enable row level security;
alter table public.laundry_orders enable row level security;
alter table public.laundry_order_items enable row level security;
alter table public.laundry_order_status_history enable row level security;
alter table public.inventory_movements enable row level security;
alter table public.stock_purchases enable row level security;
alter table public.stock_purchase_items enable row level security;
alter table public.stock_adjustments enable row level security;
alter table public.stock_alerts enable row level security;

revoke all on public.suppliers from anon, authenticated;
revoke all on public.inventory_categories from anon, authenticated;
revoke all on public.inventory_locations from anon, authenticated;
revoke all on public.inventory_items from anon, authenticated;
revoke all on public.food_categories from anon, authenticated;
revoke all on public.food_products from anon, authenticated;
revoke all on public.food_recipes from anon, authenticated;
revoke all on public.recipe_ingredients from anon, authenticated;
revoke all on public.bar_categories from anon, authenticated;
revoke all on public.bar_products from anon, authenticated;
revoke all on public.dining_tables from anon, authenticated;
revoke all on public.service_orders from anon, authenticated;
revoke all on public.service_order_items from anon, authenticated;
revoke all on public.service_order_status_history from anon, authenticated;
revoke all on public.laundry_services from anon, authenticated;
revoke all on public.laundry_orders from anon, authenticated;
revoke all on public.laundry_order_items from anon, authenticated;
revoke all on public.laundry_order_status_history from anon, authenticated;
revoke all on public.inventory_movements from anon, authenticated;
revoke all on public.stock_purchases from anon, authenticated;
revoke all on public.stock_purchase_items from anon, authenticated;
revoke all on public.stock_adjustments from anon, authenticated;
revoke all on public.stock_alerts from anon, authenticated;
