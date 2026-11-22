do $$
begin
  create type public.employment_status as enum ('active', 'on_leave', 'suspended', 'terminated');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.permission_scope as enum ('self', 'department', 'assigned', 'all');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.room_operational_status as enum ('available', 'occupied', 'blocked', 'maintenance');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.room_housekeeping_status as enum ('clean', 'dirty', 'cleaning', 'inspection');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.room_maintenance_status as enum ('reported', 'scheduled', 'in_progress', 'resolved', 'cancelled');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.housekeeping_task_type as enum ('departure', 'stayover', 'deep_clean', 'inspection', 'maintenance_followup');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.housekeeping_task_status as enum ('pending', 'assigned', 'in_progress', 'inspection', 'completed', 'rejected');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.housekeeping_task_priority as enum ('low', 'normal', 'high', 'urgent');
exception when duplicate_object then null;
end $$;
