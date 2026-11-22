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
    join public.staff_profiles sp on sp.profile_id = ur.user_id and sp.employment_status = 'active'::public.employment_status
    where ur.user_id = auth.uid() and p.key = permission_key
  );
$$;
