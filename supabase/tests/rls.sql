begin;
reset role;

select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claims', '{}', true);

insert into auth.users (id)
values
  ('a0000000-0000-4000-8000-000000000001'),
  ('a0000000-0000-4000-8000-000000000002'),
  ('a0000000-0000-4000-8000-000000000003'),
  ('a0000000-0000-4000-8000-000000000004'),
  ('a0000000-0000-4000-8000-000000000005'),
  ('b0000000-0000-4000-8000-000000000001'),
  ('b0000000-0000-4000-8000-000000000002')
on conflict do nothing;

insert into public.profiles (id, full_name, email)
values
  ('a0000000-0000-4000-8000-000000000001', 'RLS Owner', 'rls-owner@example.test'),
  ('a0000000-0000-4000-8000-000000000002', 'RLS Accountant A', 'rls-accountant-a@example.test'),
  ('a0000000-0000-4000-8000-000000000003', 'RLS Accountant B', 'rls-accountant-b@example.test'),
  ('a0000000-0000-4000-8000-000000000004', 'RLS Receptionist', 'rls-receptionist@example.test'),
  ('a0000000-0000-4000-8000-000000000005', 'RLS Manager', 'rls-manager@example.test'),
  ('b0000000-0000-4000-8000-000000000001', 'RLS Guest A', 'rls-guest-a@example.test'),
  ('b0000000-0000-4000-8000-000000000002', 'RLS Guest B', 'rls-guest-b@example.test')
on conflict do nothing;

insert into public.user_roles (user_id, role_id)
select 'a0000000-0000-4000-8000-000000000001'::uuid, r.id from public.roles r where r.key = 'owner'
union all
select 'a0000000-0000-4000-8000-000000000002'::uuid, r.id from public.roles r where r.key = 'accountant'
union all
select 'a0000000-0000-4000-8000-000000000003'::uuid, r.id from public.roles r where r.key = 'accountant'
union all
select 'a0000000-0000-4000-8000-000000000004'::uuid, r.id from public.roles r where r.key = 'receptionist'
union all
select 'a0000000-0000-4000-8000-000000000005'::uuid, r.id from public.roles r where r.key = 'manager'
union all
select 'b0000000-0000-4000-8000-000000000001'::uuid, r.id from public.roles r where r.key = 'guest'
union all
select 'b0000000-0000-4000-8000-000000000002'::uuid, r.id from public.roles r where r.key = 'guest'
on conflict do nothing;

insert into public.staff_profiles (id, profile_id, staff_number, department_id, job_title)
select 'a0000000-0000-4000-8000-000000000002'::uuid, 'a0000000-0000-4000-8000-000000000002'::uuid, 'RLS-S2', d.id, 'Accountant' from public.departments d where d.key = 'accounting'
union all
select 'a0000000-0000-4000-8000-000000000003'::uuid, 'a0000000-0000-4000-8000-000000000003'::uuid, 'RLS-S3', d.id, 'Accountant' from public.departments d where d.key = 'accounting'
union all
select 'a0000000-0000-4000-8000-000000000004'::uuid, 'a0000000-0000-4000-8000-000000000004'::uuid, 'RLS-S4', d.id, 'Receptionist' from public.departments d where d.key = 'front_desk'
union all
select 'a0000000-0000-4000-8000-000000000005'::uuid, 'a0000000-0000-4000-8000-000000000005'::uuid, 'RLS-S5', d.id, 'Manager' from public.departments d where d.key = 'front_desk'
on conflict do nothing;

insert into public.floors (id, hotel_id, name, level)
values ('60000000-0000-4000-8000-000000000001', '11111111-1111-4111-8111-111111111111', 'RLS Test Floor', 99)
on conflict do nothing;

insert into public.room_categories (id, hotel_id, name, slug, base_rate, max_occupancy)
values ('61000000-0000-4000-8000-000000000001', '11111111-1111-4111-8111-111111111111', 'RLS Test Category', 'rls-test-category', 100, 2)
on conflict do nothing;

insert into public.rooms (id, hotel_id, floor_id, category_id, number, max_occupancy)
values ('62000000-0000-4000-8000-000000000001', '11111111-1111-4111-8111-111111111111', '60000000-0000-4000-8000-000000000001', '61000000-0000-4000-8000-000000000001', 'RLS-TEST', 2)
on conflict do nothing;

insert into public.guests (id, hotel_id, full_name, auth_user_id)
values
  ('c0000000-0000-4000-8000-000000000001', '11111111-1111-4111-8111-111111111111', 'RLS Guest A', 'b0000000-0000-4000-8000-000000000001'),
  ('c0000000-0000-4000-8000-000000000002', '11111111-1111-4111-8111-111111111111', 'RLS Guest B', 'b0000000-0000-4000-8000-000000000002')
on conflict do nothing;

insert into public.reservations (id, hotel_id, reference, guest_id, check_in, check_out, adults)
values
  ('d0000000-0000-4000-8000-000000000001', '11111111-1111-4111-8111-111111111111', 'RLS-RES-A', 'c0000000-0000-4000-8000-000000000001', date '2027-01-01', date '2027-01-03', 2),
  ('d0000000-0000-4000-8000-000000000002', '11111111-1111-4111-8111-111111111111', 'RLS-RES-B', 'c0000000-0000-4000-8000-000000000002', date '2027-01-01', date '2027-01-03', 2)
on conflict do nothing;

insert into public.folios (id, folio_number, hotel_id, reservation_id, guest_id, type)
values
  ('e0000000-0000-4000-8000-000000000001', 'RLS-FOLIO-A', '11111111-1111-4111-8111-111111111111', 'd0000000-0000-4000-8000-000000000001', 'c0000000-0000-4000-8000-000000000001', 'guest'),
  ('e0000000-0000-4000-8000-000000000002', 'RLS-FOLIO-B', '11111111-1111-4111-8111-111111111111', 'd0000000-0000-4000-8000-000000000002', 'c0000000-0000-4000-8000-000000000002', 'guest')
on conflict do nothing;

insert into public.payments (id, reference, hotel_id, folio_id, provider, amount, idempotency_key, status, recorded_by)
values
  ('f0000000-0000-4000-8000-000000000001', 'RLS-PAY-A', '11111111-1111-4111-8111-111111111111', 'e0000000-0000-4000-8000-000000000001', 'bank_transfer', 100, 'RLS-IDEM-A', 'pending_verification', null),
  ('f0000000-0000-4000-8000-000000000002', 'RLS-PAY-B', '11111111-1111-4111-8111-111111111111', 'e0000000-0000-4000-8000-000000000002', 'bank_transfer', 100, 'RLS-IDEM-B', 'pending_verification', null),
  ('f0000000-0000-4000-8000-000000000003', 'RLS-PAY-SAME', '11111111-1111-4111-8111-111111111111', 'e0000000-0000-4000-8000-000000000001', 'bank_transfer', 100, 'RLS-IDEM-SAME', 'pending_verification', 'a0000000-0000-4000-8000-000000000002'),
  ('f0000000-0000-4000-8000-000000000004', 'RLS-PAY-DIFF', '11111111-1111-4111-8111-111111111111', 'e0000000-0000-4000-8000-000000000001', 'bank_transfer', 100, 'RLS-IDEM-DIFF', 'pending_verification', 'a0000000-0000-4000-8000-000000000002')
on conflict do nothing;

insert into public.number_sequences (scope, prefix, year)
values ('rls_test', 'RLS', 2026)
on conflict do nothing;

insert into public.payment_gateway_events (provider, provider_event_id, event_type)
values ('paystack', 'rls-seed-event', 'rls.test')
on conflict do nothing;

select plan(32);

set local role anon;
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claims', jsonb_build_object('role', 'anon', 'aud', 'anon', 'hotel_id', '11111111-1111-4111-8111-111111111111')::text, true);
select is((select count(*) from public.room_categories where id = '61000000-0000-4000-8000-000000000001'), 1::bigint, 'anon can read active room categories');
select is((select count(*) from public.rooms where id = '62000000-0000-4000-8000-000000000001'), 0::bigint, 'anon cannot read rooms');
select is((select count(*) from public.guests where id = 'c0000000-0000-4000-8000-000000000001'), 0::bigint, 'anon cannot read guests');
reset role;

set local role authenticated;
select set_config('request.jwt.claim.sub', 'b0000000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claims', jsonb_build_object('sub', 'b0000000-0000-4000-8000-000000000001', 'role', 'authenticated', 'aud', 'authenticated', 'hotel_id', '11111111-1111-4111-8111-111111111111', 'staff_id', null)::text, true);
select is((select count(*) from public.reservations where id = 'd0000000-0000-4000-8000-000000000001'), 1::bigint, 'guest can read own reservation');
select is((select count(*) from public.reservations where id = 'd0000000-0000-4000-8000-000000000002'), 0::bigint, 'guest cannot read other reservation');
select is((select count(*) from public.folios where id = 'e0000000-0000-4000-8000-000000000001'), 1::bigint, 'guest can read own folio');
select is((select count(*) from public.folios where id = 'e0000000-0000-4000-8000-000000000002'), 0::bigint, 'guest cannot read other folio');
select is((select count(*) from public.payments where id = 'f0000000-0000-4000-8000-000000000001'), 1::bigint, 'guest can read own payment');
select is((select count(*) from public.payments where id = 'f0000000-0000-4000-8000-000000000002'), 0::bigint, 'guest cannot read other payment');
select throws_ok($$insert into public.reservations (hotel_id, reference, guest_id, check_in, check_out, adults) values ('11111111-1111-4111-8111-111111111111', 'RLS-GUEST-INSERT', 'c0000000-0000-4000-8000-000000000001', date '2027-02-01', date '2027-02-02', 1)$$, '42501', 'new row violates row-level security policy for table "reservations"', 'guest cannot create reservations');
reset role;

set local role authenticated;
select set_config('request.jwt.claim.sub', 'a0000000-0000-4000-8000-000000000004', true);
select set_config('request.jwt.claims', jsonb_build_object('sub', 'a0000000-0000-4000-8000-000000000004', 'role', 'authenticated', 'aud', 'authenticated', 'hotel_id', '11111111-1111-4111-8111-111111111111', 'staff_id', 'a0000000-0000-4000-8000-000000000004')::text, true);
select is((select count(*) from public.rooms where id = '62000000-0000-4000-8000-000000000001'), 1::bigint, 'receptionist can read rooms');
select is((select count(*) from public.guests where id = 'c0000000-0000-4000-8000-000000000001'), 1::bigint, 'receptionist can read guest directory');
reset role;

set local role authenticated;
select set_config('request.jwt.claim.sub', 'a0000000-0000-4000-8000-000000000005', true);
select set_config('request.jwt.claims', jsonb_build_object('sub', 'a0000000-0000-4000-8000-000000000005', 'role', 'authenticated', 'aud', 'authenticated', 'hotel_id', '11111111-1111-4111-8111-111111111111', 'staff_id', 'a0000000-0000-4000-8000-000000000005')::text, true);
select lives_ok($$update public.rooms set operational_status = 'occupied' where id = '62000000-0000-4000-8000-000000000001'$$, 'manager can update room status');
select throws_ok($$insert into public.user_roles (user_id, role_id) values ('b0000000-0000-4000-8000-000000000001', (select id from public.roles where key = 'owner'))$$, '42501', 'new row violates row-level security policy for table "user_roles"', 'manager cannot grant roles');
reset role;
select is((select operational_status::text from public.rooms where id = '62000000-0000-4000-8000-000000000001'), 'occupied', 'manager room update persisted');

set local role authenticated;
select set_config('request.jwt.claim.sub', 'a0000000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claims', jsonb_build_object('sub', 'a0000000-0000-4000-8000-000000000001', 'role', 'authenticated', 'aud', 'authenticated', 'hotel_id', '11111111-1111-4111-8111-111111111111', 'staff_id', null)::text, true);
select is((select count(*) from public.rooms where id = '62000000-0000-4000-8000-000000000001'), 1::bigint, 'owner can read rooms');
select is((select count(*) from public.reservations where id = 'd0000000-0000-4000-8000-000000000001'), 1::bigint, 'owner can read reservations');
select throws_ok($$insert into public.room_categories (hotel_id, name, slug, base_rate, max_occupancy) values ('11111111-1111-4111-8111-111111111111', 'RLS Owner Category', 'rls-owner-category', 100, 2)$$, '42501', 'new row violates row-level security policy for table "room_categories"', 'owner cannot insert room categories');
update public.rooms set operational_status = 'maintenance' where id = '62000000-0000-4000-8000-000000000001';
reset role;
select is((select operational_status::text from public.rooms where id = '62000000-0000-4000-8000-000000000001'), 'occupied', 'owner cannot update rooms');

set local role authenticated;
select set_config('request.jwt.claim.sub', 'a0000000-0000-4000-8000-000000000002', true);
select set_config('request.jwt.claims', jsonb_build_object('sub', 'a0000000-0000-4000-8000-000000000002', 'role', 'authenticated', 'aud', 'authenticated', 'hotel_id', '11111111-1111-4111-8111-111111111111', 'staff_id', 'a0000000-0000-4000-8000-000000000002')::text, true);
select throws_ok($$insert into public.payment_verifications (payment_id, action, checker_id) values ('f0000000-0000-4000-8000-000000000003', 'approve', 'a0000000-0000-4000-8000-000000000002')$$, '42501', 'new row violates row-level security policy for table "payment_verifications"', 'submitter cannot verify own bank transfer');
reset role;

set local role authenticated;
select set_config('request.jwt.claim.sub', 'a0000000-0000-4000-8000-000000000003', true);
select set_config('request.jwt.claims', jsonb_build_object('sub', 'a0000000-0000-4000-8000-000000000003', 'role', 'authenticated', 'aud', 'authenticated', 'hotel_id', '11111111-1111-4111-8111-111111111111', 'staff_id', 'a0000000-0000-4000-8000-000000000003')::text, true);
select lives_ok($$insert into public.payment_verifications (payment_id, action, checker_id) values ('f0000000-0000-4000-8000-000000000004', 'approve', 'a0000000-0000-4000-8000-000000000003')$$, 'different verifier can approve bank transfer');
reset role;

set local role authenticated;
select set_config('request.jwt.claim.sub', 'a0000000-0000-4000-8000-000000000004', true);
select set_config('request.jwt.claims', jsonb_build_object('sub', 'a0000000-0000-4000-8000-000000000004', 'role', 'authenticated', 'aud', 'authenticated', 'hotel_id', '11111111-1111-4111-8111-111111111111', 'staff_id', 'a0000000-0000-4000-8000-000000000004')::text, true);
select throws_ok($$insert into public.payment_verifications (payment_id, action, checker_id) values ('f0000000-0000-4000-8000-000000000003', 'approve', 'a0000000-0000-4000-8000-000000000004')$$, '42501', 'new row violates row-level security policy for table "payment_verifications"', 'submit-only role cannot verify bank transfer');
reset role;

set local role anon;
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claims', '{"role":"anon","aud":"anon","hotel_id":"11111111-1111-4111-8111-111111111111"}', true);
select is((select count(*) from public.number_sequences where scope = 'rls_test'), 0::bigint, 'anon cannot read number sequences');
select is((select count(*) from public.payment_gateway_events where provider_event_id = 'rls-seed-event'), 0::bigint, 'anon cannot read gateway events');
reset role;

set local role authenticated;
select set_config('request.jwt.claim.sub', 'a0000000-0000-4000-8000-000000000005', true);
select set_config('request.jwt.claims', jsonb_build_object('sub', 'a0000000-0000-4000-8000-000000000005', 'role', 'authenticated', 'aud', 'authenticated', 'hotel_id', '11111111-1111-4111-8111-111111111111', 'staff_id', 'a0000000-0000-4000-8000-000000000005')::text, true);
select is((select count(*) from public.number_sequences where scope = 'rls_test'), 0::bigint, 'authenticated cannot read number sequences');
select is((select count(*) from public.payment_gateway_events where provider_event_id = 'rls-seed-event'), 0::bigint, 'authenticated cannot read gateway events');
select throws_ok($$insert into public.number_sequences (scope, prefix, year) values ('rls_test_auth', 'AUT', 2026)$$, '42501', 'new row violates row-level security policy for table "number_sequences"', 'authenticated cannot insert number sequences');
select throws_ok($$insert into public.payment_gateway_events (provider, provider_event_id, event_type) values ('paystack', 'rls-auth-event', 'rls.test')$$, '42501', 'new row violates row-level security policy for table "payment_gateway_events"', 'authenticated cannot insert gateway events');
reset role;

set local role service_role;
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claims', '{"role":"service_role","aud":"authenticated"}', true);
select is((select count(*) from public.number_sequences where scope = 'rls_test'), 1::bigint, 'service role can read number sequences');
select is((select count(*) from public.payment_gateway_events where provider_event_id = 'rls-seed-event'), 1::bigint, 'service role can read gateway events');
select lives_ok($$insert into public.number_sequences (scope, prefix, year) values ('rls_test_service', 'SVC', 2026)$$, 'service role can insert number sequences');
select lives_ok($$insert into public.payment_gateway_events (provider, provider_event_id, event_type) values ('paystack', 'rls-service-event', 'rls.test')$$, 'service role can insert gateway events');
reset role;

select * from finish();
rollback;
