create table public.floors (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  name text not null,
  level integer not null,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  unique (hotel_id, name)
);

create table public.room_categories (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  name text not null,
  slug text not null,
  description text,
  base_rate numeric(14,2) not null check (base_rate >= 0),
  currency text not null default 'NGN',
  max_occupancy integer not null check (max_occupancy > 0),
  bed_config text,
  size_sqm numeric(10,2),
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  unique (hotel_id, slug)
);

create table public.amenities (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  name text not null,
  icon_key text,
  category text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  unique (hotel_id, name)
);

create table public.room_category_amenities (
  room_category_id uuid not null references public.room_categories(id) on delete cascade,
  amenity_id uuid not null references public.amenities(id) on delete cascade,
  primary key (room_category_id, amenity_id)
);

create table public.rooms (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  floor_id uuid references public.floors(id) on delete set null,
  category_id uuid not null references public.room_categories(id) on delete restrict,
  number text not null,
  name text,
  rate_override numeric(14,2) check (rate_override >= 0),
  currency text not null default 'NGN',
  max_occupancy integer not null check (max_occupancy > 0),
  operational_status public.room_operational_status not null default 'available',
  housekeeping_status public.room_housekeeping_status not null default 'clean',
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  unique (hotel_id, number)
);

create table public.room_amenities (
  room_id uuid not null references public.rooms(id) on delete cascade,
  amenity_id uuid not null references public.amenities(id) on delete cascade,
  primary key (room_id, amenity_id)
);

create table public.room_images (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  room_id uuid references public.rooms(id) on delete cascade,
  room_category_id uuid references public.room_categories(id) on delete cascade,
  storage_path text not null,
  alt_text text,
  is_primary boolean not null default false,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  created_by uuid,
  check ((room_id is null) <> (room_category_id is null))
);

create table public.room_maintenance (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  room_id uuid not null references public.rooms(id) on delete restrict,
  reason text not null,
  description text,
  reported_by uuid references public.staff_profiles(id) on delete set null,
  started_at timestamptz,
  resolved_at timestamptz,
  status public.room_maintenance_status not null default 'reported',
  cost numeric(14,2) check (cost >= 0),
  supplier text,
  resolved_by uuid references public.staff_profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  check (resolved_at is null or started_at is null or resolved_at >= started_at)
);

create table public.housekeeping_tasks (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  room_id uuid not null references public.rooms(id) on delete restrict,
  reservation_id uuid,
  task_type public.housekeeping_task_type not null,
  status public.housekeeping_task_status not null default 'pending',
  priority public.housekeeping_task_priority not null default 'normal',
  assigned_to uuid references public.staff_profiles(id) on delete set null,
  due_at timestamptz,
  started_at timestamptz,
  completed_at timestamptz,
  inspected_at timestamptz,
  inspector_id uuid references public.staff_profiles(id) on delete set null,
  notes text,
  evidence_path text,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  check (started_at is null or completed_at is null or completed_at >= started_at)
);

alter table public.floors add constraint floors_created_by_fk foreign key (created_by) references public.profiles(id);
alter table public.floors add constraint floors_updated_by_fk foreign key (updated_by) references public.profiles(id);
alter table public.room_categories add constraint room_categories_created_by_fk foreign key (created_by) references public.profiles(id);
alter table public.room_categories add constraint room_categories_updated_by_fk foreign key (updated_by) references public.profiles(id);
alter table public.amenities add constraint amenities_created_by_fk foreign key (created_by) references public.profiles(id);
alter table public.amenities add constraint amenities_updated_by_fk foreign key (updated_by) references public.profiles(id);
alter table public.rooms add constraint rooms_created_by_fk foreign key (created_by) references public.profiles(id);
alter table public.rooms add constraint rooms_updated_by_fk foreign key (updated_by) references public.profiles(id);
alter table public.room_images add constraint room_images_created_by_fk foreign key (created_by) references public.profiles(id);
alter table public.room_maintenance add constraint room_maintenance_created_by_fk foreign key (created_by) references public.profiles(id);
alter table public.room_maintenance add constraint room_maintenance_updated_by_fk foreign key (updated_by) references public.profiles(id);
alter table public.housekeeping_tasks add constraint housekeeping_tasks_created_by_fk foreign key (created_by) references public.profiles(id);
alter table public.housekeeping_tasks add constraint housekeeping_tasks_updated_by_fk foreign key (updated_by) references public.profiles(id);

create index floors_hotel_id_active_idx on public.floors (hotel_id, is_active);
create index room_categories_hotel_id_active_idx on public.room_categories (hotel_id, is_active);
create index amenities_hotel_id_active_idx on public.amenities (hotel_id, is_active);
create index rooms_hotel_id_floor_id_idx on public.rooms (hotel_id, floor_id);
create index rooms_hotel_id_category_id_idx on public.rooms (hotel_id, category_id);
create index rooms_hotel_id_operational_status_idx on public.rooms (hotel_id, operational_status) where is_active;
create index room_images_room_id_idx on public.room_images (room_id);
create index room_images_room_category_id_idx on public.room_images (room_category_id);
create index room_maintenance_room_id_idx on public.room_maintenance (room_id);
create index housekeeping_tasks_hotel_id_status_idx on public.housekeeping_tasks (hotel_id, status);
create index housekeeping_tasks_room_id_status_idx on public.housekeeping_tasks (room_id, status);
create unique index housekeeping_tasks_open_departure_uniq on public.housekeeping_tasks (room_id, reservation_id) where task_type = 'departure' and status <> 'completed' and reservation_id is not null;

create trigger floors_set_updated_at before update on public.floors for each row execute function private.set_updated_at();
create trigger room_categories_set_updated_at before update on public.room_categories for each row execute function private.set_updated_at();
create trigger amenities_set_updated_at before update on public.amenities for each row execute function private.set_updated_at();
create trigger rooms_set_updated_at before update on public.rooms for each row execute function private.set_updated_at();
create trigger room_maintenance_set_updated_at before update on public.room_maintenance for each row execute function private.set_updated_at();
create trigger housekeeping_tasks_set_updated_at before update on public.housekeeping_tasks for each row execute function private.set_updated_at();

alter table public.floors enable row level security;
alter table public.room_categories enable row level security;
alter table public.amenities enable row level security;
alter table public.room_category_amenities enable row level security;
alter table public.rooms enable row level security;
alter table public.room_amenities enable row level security;
alter table public.room_images enable row level security;
alter table public.room_maintenance enable row level security;
alter table public.housekeeping_tasks enable row level security;

revoke all on public.floors from anon, authenticated;
revoke all on public.room_categories from anon, authenticated;
revoke all on public.amenities from anon, authenticated;
revoke all on public.room_category_amenities from anon, authenticated;
revoke all on public.rooms from anon, authenticated;
revoke all on public.room_amenities from anon, authenticated;
revoke all on public.room_images from anon, authenticated;
revoke all on public.room_maintenance from anon, authenticated;
revoke all on public.housekeeping_tasks from anon, authenticated;
