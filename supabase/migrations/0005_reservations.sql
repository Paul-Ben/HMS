do $$
begin
  create type public.reservation_status as enum ('pending', 'confirmed', 'checked_in', 'checked_out', 'cancelled', 'no_show', 'expired');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.reservation_payment_status as enum ('unpaid', 'partially_paid', 'paid', 'overpaid', 'refunded', 'partially_refunded');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.reservation_source as enum ('web', 'phone', 'walk_in', 'ota', 'staff');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.cancellation_charge_type as enum ('none', 'fixed', 'percentage', 'first_night');
exception when duplicate_object then null;
end $$;

create table public.guests (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  full_name text not null,
  first_name text,
  last_name text,
  email extensions.citext,
  email_normalized text,
  phone text,
  phone_normalized text,
  address jsonb not null default '{}'::jsonb,
  country text,
  id_type text,
  id_document_path text,
  emergency_contact jsonb not null default '{}'::jsonb,
  notes text,
  marketing_consent boolean not null default false,
  auth_user_id uuid unique references auth.users(id) on delete set null,
  merged_into_id uuid references public.guests(id) on delete restrict,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid
);

create table public.cancellation_policies (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  code text not null,
  name text not null,
  free_cancellation_hours integer not null check (free_cancellation_hours >= 0),
  charge_type public.cancellation_charge_type not null default 'first_night',
  charge_value numeric(14,2) check (charge_value >= 0),
  terms text,
  is_default boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  unique (hotel_id, code)
);

create table public.rate_plans (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  category_id uuid references public.room_categories(id) on delete cascade,
  room_id uuid references public.rooms(id) on delete cascade,
  name text not null,
  rate numeric(14,2) not null check (rate >= 0),
  currency text not null default 'NGN',
  valid_from date,
  valid_to date,
  min_nights integer check (min_nights > 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  check (not (category_id is not null and room_id is not null)),
  check (valid_to is null or valid_from is null or valid_to >= valid_from)
);

create table public.reservations (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  reference text not null unique,
  guest_id uuid not null references public.guests(id) on delete restrict,
  cancellation_policy_id uuid references public.cancellation_policies(id) on delete set null,
  check_in date not null,
  check_out date not null,
  nights integer generated always as (check_out - check_in) stored,
  adults integer not null check (adults > 0),
  children integer not null default 0 check (children >= 0),
  room_subtotal numeric(14,2) not null default 0 check (room_subtotal >= 0),
  discount numeric(14,2) not null default 0 check (discount >= 0),
  tax numeric(14,2) not null default 0 check (tax >= 0),
  fees numeric(14,2) not null default 0 check (fees >= 0),
  accommodation_total numeric(14,2) not null default 0 check (accommodation_total >= 0),
  deposit_percentage numeric(5,2) not null default 30 check (deposit_percentage between 0 and 100),
  required_deposit numeric(14,2) not null default 0 check (required_deposit >= 0),
  currency text not null default 'NGN',
  status public.reservation_status not null default 'pending',
  payment_status public.reservation_payment_status not null default 'unpaid',
  source public.reservation_source not null default 'web',
  special_requests text,
  internal_notes text,
  hold_expires_at timestamptz,
  cancelled_at timestamptz,
  cancelled_by uuid references public.profiles(id) on delete set null,
  cancellation_reason text,
  cancellation_fee numeric(14,2) check (cancellation_fee >= 0),
  no_show_at timestamptz,
  no_show_by uuid references public.profiles(id) on delete set null,
  rate_snapshot jsonb not null default '{}'::jsonb,
  tax_snapshot jsonb not null default '{}'::jsonb,
  policy_snapshot jsonb not null default '{}'::jsonb,
  idempotency_key text unique,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  check (check_out > check_in),
  check (nights > 0)
);

create table public.reservation_guests (
  reservation_id uuid not null references public.reservations(id) on delete cascade,
  guest_id uuid not null references public.guests(id) on delete restrict,
  is_primary boolean not null default false,
  relationship text,
  primary key (reservation_id, guest_id)
);

create table public.reservation_room_assignments (
  id uuid primary key default gen_random_uuid(),
  reservation_id uuid not null references public.reservations(id) on delete cascade,
  room_id uuid not null references public.rooms(id) on delete restrict,
  nightly_rate numeric(14,2) not null check (nightly_rate >= 0),
  check_in date not null,
  check_out date not null,
  occupancy integer not null check (occupancy > 0),
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  created_by uuid,
  check (check_out > check_in),
  unique (reservation_id, room_id)
);

create table public.room_allocation_holds (
  id uuid primary key default gen_random_uuid(),
  reservation_id uuid not null references public.reservations(id) on delete cascade,
  room_id uuid not null references public.rooms(id) on delete restrict,
  check_in date not null,
  check_out date not null,
  stay daterange generated always as (daterange(check_in, check_out, '[)')) stored,
  created_at timestamptz not null default now(),
  check (check_out > check_in)
);

create table public.reservation_status_history (
  id uuid primary key default gen_random_uuid(),
  reservation_id uuid not null references public.reservations(id) on delete cascade,
  from_status public.reservation_status,
  to_status public.reservation_status not null,
  reason text,
  actor_id uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

alter table public.guests add constraint guests_created_by_fk foreign key (created_by) references public.profiles(id);
alter table public.guests add constraint guests_updated_by_fk foreign key (updated_by) references public.profiles(id);
alter table public.cancellation_policies add constraint cancellation_policies_created_by_fk foreign key (created_by) references public.profiles(id);
alter table public.cancellation_policies add constraint cancellation_policies_updated_by_fk foreign key (updated_by) references public.profiles(id);
alter table public.rate_plans add constraint rate_plans_created_by_fk foreign key (created_by) references public.profiles(id);
alter table public.rate_plans add constraint rate_plans_updated_by_fk foreign key (updated_by) references public.profiles(id);
alter table public.reservations add constraint reservations_created_by_fk foreign key (created_by) references public.profiles(id);
alter table public.reservations add constraint reservations_updated_by_fk foreign key (updated_by) references public.profiles(id);
alter table public.reservation_room_assignments add constraint reservation_room_assignments_created_by_fk foreign key (created_by) references public.profiles(id);

alter table public.booking_settings add constraint booking_settings_default_cancellation_policy_fk foreign key (hotel_id, default_cancellation_policy_code) references public.cancellation_policies(hotel_id, code) on delete set null;
alter table public.housekeeping_tasks add constraint housekeeping_tasks_reservation_fk foreign key (reservation_id) references public.reservations(id) on delete set null;

alter table public.room_allocation_holds add constraint room_allocation_no_overlap exclude using gist (room_id with =, stay with &&);

create unique index one_primary_guest_per_reservation on public.reservation_guests (reservation_id) where is_primary;
create unique index one_primary_room_per_reservation on public.reservation_room_assignments (reservation_id) where is_primary;
create unique index one_default_cancellation_policy_per_hotel on public.cancellation_policies (hotel_id) where is_default;
create index guests_hotel_id_email_normalized_idx on public.guests (hotel_id, email_normalized);
create index guests_hotel_id_phone_normalized_idx on public.guests (hotel_id, phone_normalized);
create index guests_full_name_trgm_idx on public.guests using gin (full_name extensions.gin_trgm_ops);
create index reservations_hotel_id_check_in_idx on public.reservations (hotel_id, check_in);
create index reservations_hotel_id_check_out_idx on public.reservations (hotel_id, check_out);
create index reservations_hotel_id_status_idx on public.reservations (hotel_id, status);
create index reservations_guest_id_idx on public.reservations (guest_id);
create index reservations_pending_hold_expires_at_idx on public.reservations (hold_expires_at) where status = 'pending';
create index reservation_guests_guest_id_idx on public.reservation_guests (guest_id);
create index reservation_room_assignments_room_id_idx on public.reservation_room_assignments (room_id);
create index room_allocation_holds_reservation_id_idx on public.room_allocation_holds (reservation_id);
create index cancellation_policies_hotel_id_active_idx on public.cancellation_policies (hotel_id, is_active);
create index rate_plans_hotel_id_active_idx on public.rate_plans (hotel_id, is_active);

create trigger guests_set_updated_at before update on public.guests for each row execute function private.set_updated_at();
create trigger cancellation_policies_set_updated_at before update on public.cancellation_policies for each row execute function private.set_updated_at();
create trigger rate_plans_set_updated_at before update on public.rate_plans for each row execute function private.set_updated_at();
create trigger reservations_set_updated_at before update on public.reservations for each row execute function private.set_updated_at();

create or replace function private.record_reservation_status_history()
returns trigger
language plpgsql
as $$
begin
  if old.status is distinct from new.status then
    insert into public.reservation_status_history (reservation_id, from_status, to_status, actor_id)
    values (new.id, old.status, new.status, nullif(coalesce(current_setting('request.jwt.claims', true), '{}')::jsonb ->> 'staff_id', '')::uuid);
  end if;
  return new;
end;
$$;

create trigger reservations_status_history after update on public.reservations for each row execute function private.record_reservation_status_history();

alter table public.guests enable row level security;
alter table public.cancellation_policies enable row level security;
alter table public.rate_plans enable row level security;
alter table public.reservations enable row level security;
alter table public.reservation_guests enable row level security;
alter table public.reservation_room_assignments enable row level security;
alter table public.room_allocation_holds enable row level security;
alter table public.reservation_status_history enable row level security;

revoke all on public.guests from anon, authenticated;
revoke all on public.cancellation_policies from anon, authenticated;
revoke all on public.rate_plans from anon, authenticated;
revoke all on public.reservations from anon, authenticated;
revoke all on public.reservation_guests from anon, authenticated;
revoke all on public.reservation_room_assignments from anon, authenticated;
revoke all on public.room_allocation_holds from anon, authenticated;
revoke all on public.reservation_status_history from anon, authenticated;
