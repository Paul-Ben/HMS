begin;
reset role;

insert into auth.users (id, email, email_confirmed_at, raw_app_meta_data, is_sso_user, is_anonymous)
values
  ('e0000000-0000-4000-8000-000000000001', 'storage-none@example.test', now(), '{}'::jsonb, false, false),
  ('e0000000-0000-4000-8000-000000000002', 'storage-accountant@example.test', now(), '{}'::jsonb, false, false),
  ('e0000000-0000-4000-8000-000000000003', 'storage-manager@example.test', now(), '{}'::jsonb, false, false)
on conflict (id) do nothing;

insert into public.profiles (id, full_name, email)
values
  ('e0000000-0000-4000-8000-000000000001', 'Storage None', 'storage-none@example.test'),
  ('e0000000-0000-4000-8000-000000000002', 'Storage Accountant', 'storage-accountant@example.test'),
  ('e0000000-0000-4000-8000-000000000003', 'Storage Manager', 'storage-manager@example.test')
on conflict (id) do nothing;

insert into public.staff_profiles (id, profile_id, staff_number, department_id, job_title, employment_status)
values
  ('e1000000-0000-4000-8000-000000000001', 'e0000000-0000-4000-8000-000000000001', 'STORAGE-001', (select id from public.departments where key = 'front_desk'), 'Storage None', 'active'),
  ('e1000000-0000-4000-8000-000000000002', 'e0000000-0000-4000-8000-000000000002', 'STORAGE-002', (select id from public.departments where key = 'front_desk'), 'Storage Accountant', 'active'),
  ('e1000000-0000-4000-8000-000000000003', 'e0000000-0000-4000-8000-000000000003', 'STORAGE-003', (select id from public.departments where key = 'front_desk'), 'Storage Manager', 'active')
on conflict (id) do nothing;

insert into public.user_roles (user_id, role_id)
select 'e0000000-0000-4000-8000-000000000002'::uuid, r.id from public.roles r where r.key = 'accountant'
union all
select 'e0000000-0000-4000-8000-000000000003'::uuid, r.id from public.roles r where r.key = 'manager'
on conflict do nothing;

do $$
declare
  v_hotel uuid := '11111111-1111-4111-8111-111111111111';
  v_room uuid;
begin
  select id into v_room from public.rooms
  where is_active and operational_status = 'available'
  order by number
  limit 1;

  insert into storage.objects (id, bucket_id, name, owner, owner_id, metadata, is_delete_marker, is_versioned)
  values
    ('90000000-0000-4000-8000-000000000001', 'public-media', v_hotel || '/media/90000000-0000-4000-8000-000000000001/hero.jpg', 'e0000000-0000-4000-8000-000000000003', 'e0000000-0000-4000-8000-000000000003', '{}'::jsonb, false, false),
    ('90000000-0000-4000-8000-000000000002', 'guest-evidence', v_hotel || '/payment/90000000-0000-4000-8000-000000000002/proof.pdf', 'e0000000-0000-4000-8000-000000000001', 'e0000000-0000-4000-8000-000000000001', '{}'::jsonb, false, false),
    ('90000000-0000-4000-8000-000000000003', 'receipts', v_hotel || '/receipt/90000000-0000-4000-8000-000000000003/receipt.pdf', 'e0000000-0000-4000-8000-000000000002', 'e0000000-0000-4000-8000-000000000002', '{}'::jsonb, false, false),
    ('90000000-0000-4000-8000-000000000004', 'room-images', v_hotel || '/room/' || v_room || '/main.jpg', 'e0000000-0000-4000-8000-000000000003', 'e0000000-0000-4000-8000-000000000003', '{}'::jsonb, false, false),
    ('90000000-0000-4000-8000-000000000005', 'report-exports', v_hotel || '/report/90000000-0000-4000-8000-000000000005/export.csv', 'e0000000-0000-4000-8000-000000000003', 'e0000000-0000-4000-8000-000000000003', '{}'::jsonb, false, false),
    ('90000000-0000-4000-8000-000000000006', 'staff-documents', v_hotel || '/profile/e0000000-0000-4000-8000-000000000001/cv.pdf', 'e0000000-0000-4000-8000-000000000001', 'e0000000-0000-4000-8000-000000000001', '{}'::jsonb, false, false),
    ('90000000-0000-4000-8000-000000000007', 'staff-documents', v_hotel || '/profile/e0000000-0000-4000-8000-000000000002/contract.pdf', 'e0000000-0000-4000-8000-000000000002', 'e0000000-0000-4000-8000-000000000002', '{}'::jsonb, false, false)
  on conflict (id) do update set
    bucket_id = excluded.bucket_id,
    name = excluded.name,
    owner = excluded.owner,
    owner_id = excluded.owner_id,
    metadata = excluded.metadata;
end $$;

select plan(15);

select ok(private.storage_path_is_valid('11111111-1111-4111-8111-111111111111/room/62000000-0000-4000-8000-000000000001/main.jpg'), 'storage path helper accepts valid path');
select ok(not private.storage_path_is_valid('bad/path'), 'storage path helper rejects invalid path');

set local role anon;
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claims', jsonb_build_object('role', 'anon', 'aud', 'anon')::text, true);
select is((select count(*) from storage.objects where id = '90000000-0000-4000-8000-000000000001'), 1::bigint, 'anon reads public media');
select is((select count(*) from storage.objects where id = '90000000-0000-4000-8000-000000000002'), 0::bigint, 'anon cannot read guest evidence');
select is((select count(*) from storage.objects where id = '90000000-0000-4000-8000-000000000004'), 1::bigint, 'anon reads published room image');
reset role;

set local role authenticated;
select set_config('request.jwt.claim.sub', 'e0000000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claims', jsonb_build_object('sub', 'e0000000-0000-4000-8000-000000000001', 'role', 'authenticated', 'aud', 'authenticated')::text, true);
select is((select count(*) from storage.objects where id = '90000000-0000-4000-8000-000000000002'), 0::bigint, 'unprivileged user cannot read guest evidence');
select is((select count(*) from storage.objects where id = '90000000-0000-4000-8000-000000000003'), 0::bigint, 'unprivileged user cannot read receipts');
select is((select count(*) from storage.objects where id = '90000000-0000-4000-8000-000000000005'), 0::bigint, 'unprivileged user cannot read report exports');
select is((select count(*) from storage.objects where id = '90000000-0000-4000-8000-000000000006'), 1::bigint, 'user can read own staff document');
select is((select count(*) from storage.objects where id = '90000000-0000-4000-8000-000000000007'), 0::bigint, 'user cannot read another staff document');
reset role;

set local role authenticated;
select set_config('request.jwt.claim.sub', 'e0000000-0000-4000-8000-000000000002', true);
select set_config('request.jwt.claims', jsonb_build_object('sub', 'e0000000-0000-4000-8000-000000000002', 'role', 'authenticated', 'aud', 'authenticated')::text, true);
select is((select count(*) from storage.objects where id = '90000000-0000-4000-8000-000000000002'), 1::bigint, 'accountant reads guest evidence');
select is((select count(*) from storage.objects where id = '90000000-0000-4000-8000-000000000003'), 1::bigint, 'accountant reads receipts');
reset role;

set local role authenticated;
select set_config('request.jwt.claim.sub', 'e0000000-0000-4000-8000-000000000003', true);
select set_config('request.jwt.claims', jsonb_build_object('sub', 'e0000000-0000-4000-8000-000000000003', 'role', 'authenticated', 'aud', 'authenticated')::text, true);
select is((select count(*) from storage.objects where id = '90000000-0000-4000-8000-000000000004'), 1::bigint, 'manager reads room image');
select is((select count(*) from storage.objects where id = '90000000-0000-4000-8000-000000000006'), 1::bigint, 'manager reads staff document');
select is((select count(*) from storage.objects where id = '90000000-0000-4000-8000-000000000005'), 1::bigint, 'manager reads report export');
reset role;

select coalesce(string_agg(result, chr(10)), 'ALL STORAGE TESTS PASSED') as results from extensions.finish() as result;
rollback;
