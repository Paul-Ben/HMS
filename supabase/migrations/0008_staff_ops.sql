do $$
begin
  create type public.shift_assignment_status as enum ('scheduled', 'cancelled', 'completed');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.attendance_status as enum ('scheduled', 'present', 'absent', 'no_show', 'adjusted');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.handover_status as enum ('draft', 'submitted', 'acknowledged');
exception when duplicate_object then null;
end $$;

create table public.shifts (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  department_id uuid references public.departments(id) on delete set null,
  name text not null,
  start_time time not null,
  end_time time not null,
  grace_minutes integer not null default 0 check (grace_minutes >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id) on delete set null
);

create table public.staff_shift_assignments (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  staff_id uuid not null references public.staff_profiles(id) on delete restrict,
  shift_id uuid not null references public.shifts(id) on delete restrict,
  work_date date not null,
  status public.shift_assignment_status not null default 'scheduled',
  assigned_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id) on delete set null,
  unique (staff_id, work_date, shift_id)
);

create table public.attendance_records (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  staff_id uuid not null references public.staff_profiles(id) on delete restrict,
  assignment_id uuid not null unique references public.staff_shift_assignments(id) on delete restrict,
  work_date date not null,
  clock_in_at timestamptz,
  clock_out_at timestamptz,
  late_minutes integer not null default 0 check (late_minutes >= 0),
  early_minutes integer not null default 0 check (early_minutes >= 0),
  worked_minutes integer not null default 0 check (worked_minutes >= 0),
  status public.attendance_status not null default 'scheduled',
  notes text,
  adjusted_by uuid references public.profiles(id) on delete set null,
  adjusted_at timestamptz,
  adjustment_reason text,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id) on delete set null,
  check (clock_out_at is null or clock_in_at is null or clock_out_at >= clock_in_at),
  check (adjusted_by is null or adjustment_reason is not null)
);

create table public.shift_handovers (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  department_id uuid references public.departments(id) on delete set null,
  shift_date date not null,
  shift_id uuid references public.shifts(id) on delete restrict,
  outgoing_staff_id uuid not null references public.staff_profiles(id) on delete restrict,
  incoming_staff_id uuid references public.staff_profiles(id) on delete restrict,
  status public.handover_status not null default 'draft',
  checklist jsonb not null default '{}'::jsonb,
  notes text,
  expected_cash numeric(14,2) not null default 0 check (expected_cash >= 0),
  counted_cash numeric(14,2) check (counted_cash >= 0),
  cash_variance numeric(14,2) generated always as (counted_cash - expected_cash) stored,
  variance_reason text,
  submitted_at timestamptz,
  acknowledged_at timestamptz,
  acknowledged_by uuid references public.staff_profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id) on delete set null,
  check (outgoing_staff_id is distinct from incoming_staff_id),
  check (status <> 'acknowledged' or (incoming_staff_id is not null and acknowledged_at is not null and acknowledged_by is not null)),
  check (acknowledged_by is null or acknowledged_by = incoming_staff_id)
);

create table public.staff_activity_logs (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  staff_id uuid not null references public.staff_profiles(id) on delete restrict,
  activity_type text not null,
  entity_type text not null,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create unique index one_open_attendance_per_staff on public.attendance_records (staff_id) where clock_out_at is null;
create index shifts_hotel_id_active_idx on public.shifts (hotel_id, is_active);
create index staff_shift_assignments_hotel_id_work_date_idx on public.staff_shift_assignments (hotel_id, work_date);
create index staff_shift_assignments_staff_id_work_date_idx on public.staff_shift_assignments (staff_id, work_date);
create index staff_shift_assignments_shift_id_idx on public.staff_shift_assignments (shift_id);
create index attendance_records_staff_work_date_idx on public.attendance_records (staff_id, work_date);
create index attendance_records_work_date_status_idx on public.attendance_records (work_date, status);
create index shift_handovers_hotel_department_date_idx on public.shift_handovers (hotel_id, department_id, shift_date);
create index shift_handovers_hotel_status_date_idx on public.shift_handovers (hotel_id, status, shift_date);
create index shift_handovers_outgoing_staff_date_idx on public.shift_handovers (outgoing_staff_id, shift_date);
create index shift_handovers_incoming_staff_date_idx on public.shift_handovers (incoming_staff_id, shift_date);
create index staff_activity_logs_hotel_staff_occurred_idx on public.staff_activity_logs (hotel_id, staff_id, occurred_at desc);
create index staff_activity_logs_entity_idx on public.staff_activity_logs (entity_type, entity_id);
create index staff_activity_logs_type_idx on public.staff_activity_logs (activity_type);

create trigger shifts_set_updated_at before update on public.shifts for each row execute function private.set_updated_at();
create trigger staff_shift_assignments_set_updated_at before update on public.staff_shift_assignments for each row execute function private.set_updated_at();
create trigger attendance_records_set_updated_at before update on public.attendance_records for each row execute function private.set_updated_at();
create trigger shift_handovers_set_updated_at before update on public.shift_handovers for each row execute function private.set_updated_at();

create or replace function private.guard_shift_handover()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'UPDATE' and old.status = 'acknowledged' then
    raise exception 'acknowledged handovers are immutable' using errcode = '23514';
  end if;

  if new.status in ('submitted', 'acknowledged')
     and new.cash_variance is not null
     and new.cash_variance <> 0
     and new.variance_reason is null then
    raise exception 'cash variance requires a reason' using errcode = '23514';
  end if;

  return new;
end;
$$;

create trigger shift_handovers_guard before insert or update on public.shift_handovers for each row execute function private.guard_shift_handover();
create trigger staff_activity_logs_append_only before update or delete on public.staff_activity_logs for each row execute function private.prevent_append_only_mutation();

alter table public.shifts enable row level security;
alter table public.staff_shift_assignments enable row level security;
alter table public.attendance_records enable row level security;
alter table public.shift_handovers enable row level security;
alter table public.staff_activity_logs enable row level security;

revoke all on public.shifts from anon, authenticated;
revoke all on public.staff_shift_assignments from anon, authenticated;
revoke all on public.attendance_records from anon, authenticated;
revoke all on public.shift_handovers from anon, authenticated;
revoke all on public.staff_activity_logs from anon, authenticated;
