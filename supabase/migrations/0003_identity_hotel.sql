create table public.profiles (
  id uuid primary key references auth.users(id) on delete restrict,
  full_name text not null,
  email extensions.citext not null unique,
  phone text,
  avatar_path text,
  is_active boolean not null default true,
  last_seen_at timestamptz,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid
);

create table public.departments (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  name text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid
);

create table public.roles (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  name text not null,
  description text,
  is_system boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid
);

create table public.permissions (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  description text,
  scope public.permission_scope not null default 'self',
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid
);

create table public.role_permissions (
  role_id uuid not null references public.roles(id) on delete cascade,
  permission_id uuid not null references public.permissions(id) on delete cascade,
  granted_by uuid,
  granted_at timestamptz not null default now(),
  primary key (role_id, permission_id)
);

create table public.user_roles (
  user_id uuid not null references public.profiles(id) on delete cascade,
  role_id uuid not null references public.roles(id) on delete restrict,
  granted_by uuid,
  granted_at timestamptz not null default now(),
  primary key (user_id, role_id)
);

create table public.hotels (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  timezone text not null default 'Africa/Lagos',
  currency text not null default 'NGN',
  address jsonb not null default '{}'::jsonb,
  contacts jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid
);

create table public.hotel_settings (
  hotel_id uuid primary key references public.hotels(id) on delete cascade,
  tax_rate numeric(5,2) not null default 7.50 check (tax_rate between 0 and 100),
  service_charge_rate numeric(5,2) not null default 0 check (service_charge_rate between 0 and 100),
  check_in_time time not null default '14:00',
  check_out_time time not null default '12:00',
  receipt_prefix text not null default 'RCP',
  cancellation_hours integer not null default 48 check (cancellation_hours >= 0),
  late_checkout_grace_minutes integer not null default 10 check (late_checkout_grace_minutes >= 0),
  logo_path text,
  social_links jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid
);

create table public.booking_settings (
  hotel_id uuid primary key references public.hotels(id) on delete cascade,
  deposit_percentage numeric(5,2) not null default 30 check (deposit_percentage between 0 and 100),
  deposit_required boolean not null default true,
  full_payment_allowed boolean not null default true,
  hold_minutes integer not null default 30 check (hold_minutes > 0),
  default_cancellation_policy_code text,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid
);

create table public.staff_profiles (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null unique references public.profiles(id) on delete restrict,
  staff_number text not null unique,
  department_id uuid references public.departments(id) on delete set null,
  job_title text not null,
  employment_status public.employment_status not null default 'active',
  hired_on date,
  terminated_on date,
  emergency_contact jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  check (terminated_on is null or hired_on is null or terminated_on >= hired_on)
);

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid references public.hotels(id) on delete restrict,
  actor_profile_id uuid references public.profiles(id) on delete restrict,
  actor_role_key text,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  before_state jsonb,
  after_state jsonb,
  ip_address inet,
  user_agent text,
  request_id text,
  created_at timestamptz not null default now()
);

create table public.system_settings (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  description text,
  is_public boolean not null default false,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid
);

alter table public.profiles add constraint profiles_created_by_fk foreign key (created_by) references public.profiles(id);
alter table public.profiles add constraint profiles_updated_by_fk foreign key (updated_by) references public.profiles(id);
alter table public.departments add constraint departments_created_by_fk foreign key (created_by) references public.profiles(id);
alter table public.departments add constraint departments_updated_by_fk foreign key (updated_by) references public.profiles(id);
alter table public.roles add constraint roles_created_by_fk foreign key (created_by) references public.profiles(id);
alter table public.roles add constraint roles_updated_by_fk foreign key (updated_by) references public.profiles(id);
alter table public.permissions add constraint permissions_created_by_fk foreign key (created_by) references public.profiles(id);
alter table public.permissions add constraint permissions_updated_by_fk foreign key (updated_by) references public.profiles(id);
alter table public.role_permissions add constraint role_permissions_granted_by_fk foreign key (granted_by) references public.profiles(id);
alter table public.user_roles add constraint user_roles_granted_by_fk foreign key (granted_by) references public.profiles(id);
alter table public.hotels add constraint hotels_created_by_fk foreign key (created_by) references public.profiles(id);
alter table public.hotels add constraint hotels_updated_by_fk foreign key (updated_by) references public.profiles(id);
alter table public.hotel_settings add constraint hotel_settings_created_by_fk foreign key (created_by) references public.profiles(id);
alter table public.hotel_settings add constraint hotel_settings_updated_by_fk foreign key (updated_by) references public.profiles(id);
alter table public.booking_settings add constraint booking_settings_created_by_fk foreign key (created_by) references public.profiles(id);
alter table public.booking_settings add constraint booking_settings_updated_by_fk foreign key (updated_by) references public.profiles(id);
alter table public.staff_profiles add constraint staff_profiles_created_by_fk foreign key (created_by) references public.profiles(id);
alter table public.staff_profiles add constraint staff_profiles_updated_by_fk foreign key (updated_by) references public.profiles(id);
alter table public.system_settings add constraint system_settings_created_by_fk foreign key (created_by) references public.profiles(id);
alter table public.system_settings add constraint system_settings_updated_by_fk foreign key (updated_by) references public.profiles(id);

create trigger profiles_set_updated_at before update on public.profiles for each row execute function private.set_updated_at();
create trigger departments_set_updated_at before update on public.departments for each row execute function private.set_updated_at();
create trigger roles_set_updated_at before update on public.roles for each row execute function private.set_updated_at();
create trigger permissions_set_updated_at before update on public.permissions for each row execute function private.set_updated_at();
create trigger hotels_set_updated_at before update on public.hotels for each row execute function private.set_updated_at();
create trigger hotel_settings_set_updated_at before update on public.hotel_settings for each row execute function private.set_updated_at();
create trigger booking_settings_set_updated_at before update on public.booking_settings for each row execute function private.set_updated_at();
create trigger staff_profiles_set_updated_at before update on public.staff_profiles for each row execute function private.set_updated_at();
create trigger system_settings_set_updated_at before update on public.system_settings for each row execute function private.set_updated_at();

create or replace function private.current_staff_id()
returns uuid
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select sp.id
  from public.staff_profiles sp
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
  select nullif(current_setting('request.jwt.claims', true)::jsonb ->> 'guest_id', '')::uuid;
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
    where ur.user_id = auth.uid()
      and r.key = role_key
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
    where ur.user_id = auth.uid()
      and p.key = permission_key
  );
$$;

create or replace function private.has_department_scope(target_department_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select target_department_id is null
    or exists (
      select 1
      from public.staff_profiles sp
      where sp.id = private.current_staff_id()
        and sp.department_id = target_department_id
    )
    or exists (
      select 1
      from public.user_roles ur
      join public.role_permissions rp on rp.role_id = ur.role_id
      join public.permissions p on p.id = rp.permission_id
      where ur.user_id = auth.uid()
        and p.scope = 'all'::public.permission_scope
    );
$$;

create or replace function private.is_staff()
returns boolean
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select private.current_staff_id() is not null;
$$;

create or replace function private.is_active_profile()
returns boolean
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.is_active
  );
$$;

create or replace function private.is_owner_readonly()
returns boolean
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select private.has_role('owner') and not private.has_permission('owner.write');
$$;

alter table public.profiles enable row level security;
alter table public.departments enable row level security;
alter table public.roles enable row level security;
alter table public.permissions enable row level security;
alter table public.role_permissions enable row level security;
alter table public.user_roles enable row level security;
alter table public.hotels enable row level security;
alter table public.hotel_settings enable row level security;
alter table public.booking_settings enable row level security;
alter table public.staff_profiles enable row level security;
alter table public.audit_logs enable row level security;
alter table public.system_settings enable row level security;

revoke all on public.profiles from anon, authenticated;
revoke all on public.departments from anon, authenticated;
revoke all on public.roles from anon, authenticated;
revoke all on public.permissions from anon, authenticated;
revoke all on public.role_permissions from anon, authenticated;
revoke all on public.user_roles from anon, authenticated;
revoke all on public.hotels from anon, authenticated;
revoke all on public.hotel_settings from anon, authenticated;
revoke all on public.booking_settings from anon, authenticated;
revoke all on public.staff_profiles from anon, authenticated;
revoke all on public.audit_logs from anon, authenticated;
revoke all on public.system_settings from anon, authenticated;
