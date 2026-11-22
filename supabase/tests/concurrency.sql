begin;
reset role;

select set_config('request.jwt.claim.sub', '', false);
select set_config('request.jwt.claims', jsonb_build_object('role', 'service_role')::text, false);

insert into public.guests (id, hotel_id, full_name, email)
values ('c1000000-0000-4000-8000-000000000001', '11111111-1111-4111-8111-111111111111', 'Concurrency Guest', 'concurrency.guest@example.test')
on conflict (id) do nothing;

insert into public.folios (id, folio_number, hotel_id, guest_id, type, status, currency, opened_at)
values ('c2000000-0000-4000-8000-000000000001', public.allocate_reference('folio', 'FOL'), '11111111-1111-4111-8111-111111111111', 'c1000000-0000-4000-8000-000000000001', 'walk_in', 'open', 'NGN', now())
on conflict (id) do nothing;

insert into public.inventory_categories (id, hotel_id, name, department_id)
values ('c3000000-0000-4000-8000-000000000001', '11111111-1111-4111-8111-111111111111', 'Concurrency Stores', (select id from public.departments where key = 'restaurant'))
on conflict (id) do nothing;

insert into public.inventory_items (id, hotel_id, sku, category_id, name, base_unit, current_stock, reorder_level, unit_cost)
values ('c3000000-0000-4000-8000-000000000002', '11111111-1111-4111-8111-111111111111', 'CONCURRENCY-ITEM', 'c3000000-0000-4000-8000-000000000001', 'Concurrency Item', 'unit', 100, 0, 1000)
on conflict (id) do nothing;

insert into public.floors (id, hotel_id, name, level)
values ('c5000000-0000-4000-8000-000000000001', '11111111-1111-4111-8111-111111111111', 'Concurrency Floor', 99)
on conflict (id) do nothing;

insert into public.room_categories (id, hotel_id, name, slug, base_rate, max_occupancy)
values ('c5000000-0000-4000-8000-000000000002', '11111111-1111-4111-8111-111111111111', 'Concurrency Category', 'concurrency-category', 50000, 2)
on conflict (id) do nothing;

insert into public.rooms (id, hotel_id, floor_id, category_id, number, max_occupancy, operational_status, housekeeping_status)
values ('c5000000-0000-4000-8000-000000000003', '11111111-1111-4111-8111-111111111111', 'c5000000-0000-4000-8000-000000000001', 'c5000000-0000-4000-8000-000000000002', 'CONC-001', 2, 'available', 'clean')
on conflict (id) do nothing;

select plan(14);

select is(public.folio_balance('c2000000-0000-4000-8000-000000000001'), 0::numeric, 'folio starts with zero balance');

select is(
  public.post_bill_item('c2000000-0000-4000-8000-000000000001', (select id from public.departments where key = 'restaurant'), 'idempotent bill item', 1, 10000, 0, 0, 'concurrency_test', null, 'c4000000-0000-4000-8000-000000000001'),
  public.post_bill_item('c2000000-0000-4000-8000-000000000001', (select id from public.departments where key = 'restaurant'), 'idempotent bill item', 1, 10000, 0, 0, 'concurrency_test', null, 'c4000000-0000-4000-8000-000000000001'),
  'bill item idempotency replay returns same id'
);
select is((select count(*) from public.financial_transactions where idempotency_key = 'c4000000-0000-4000-8000-000000000001'), 1::bigint, 'bill item posts one ledger transaction');
select is(public.folio_balance('c2000000-0000-4000-8000-000000000001'), 10000::numeric, 'bill item increases folio balance once');

select is(
  public.record_manual_payment('c2000000-0000-4000-8000-000000000001', 4000, 'cash', 'CONC-CASH-1', 'idempotent payment', 'concurrency-payment-1'),
  public.record_manual_payment('c2000000-0000-4000-8000-000000000001', 4000, 'cash', 'CONC-CASH-1', 'idempotent payment', 'concurrency-payment-1'),
  'manual payment idempotency replay returns same id'
);
select is(public.folio_balance('c2000000-0000-4000-8000-000000000001'), 6000::numeric, 'manual payment reduces folio balance once');
select throws_ok(
  $$select public.record_manual_payment('c2000000-0000-4000-8000-000000000001', 99999, 'cash', 'CONC-CASH-OVER', 'overpayment', 'concurrency-payment-over')$$,
  '23514',
  'payment amount 99999 exceeds folio balance 6000.00',
  'manual payment rejects overpayment'
);

do $$
begin
  perform public.post_bill_item('c2000000-0000-4000-8000-000000000001', (select id from public.departments where key = 'restaurant'), 'null key bill item', 1, 500, 0, 0, 'concurrency_null_key', null, null);
  perform public.post_bill_item('c2000000-0000-4000-8000-000000000001', (select id from public.departments where key = 'restaurant'), 'null key bill item', 1, 500, 0, 0, 'concurrency_null_key', null, null);
end $$;
select is((select count(*) from public.bill_items where description = 'null key bill item'), 2::bigint, 'null idempotency key creates distinct bill items');

select throws_ok(
  $$select private.post_stock_movement('11111111-1111-4111-8111-111111111111', 'c3000000-0000-4000-8000-000000000002', -200, 'usage', 'concurrency_test', null, null, null, null, null, null, false, null, 'concurrency-stock-blocked')$$,
  '23514',
  'insufficient stock for item c3000000-0000-4000-8000-000000000002',
  'stock movement rejects negative stock without override'
);

select is(
  private.post_stock_movement('11111111-1111-4111-8111-111111111111', 'c3000000-0000-4000-8000-000000000002', -200, 'usage', 'concurrency_test', null, null, null, null, null, null, true, 'concurrency override', 'concurrency-stock-override'),
  private.post_stock_movement('11111111-1111-4111-8111-111111111111', 'c3000000-0000-4000-8000-000000000002', -200, 'usage', 'concurrency_test', null, null, null, null, null, null, true, 'concurrency override', 'concurrency-stock-override'),
  'stock movement idempotency replay returns same id'
);
select is((select current_stock from public.inventory_items where id = 'c3000000-0000-4000-8000-000000000002'), (-100)::numeric, 'negative stock override applies once');

with first_reservation as (
  select * from public.create_reservation(
    '11111111-1111-4111-8111-111111111111',
    'c5000000-0000-4000-8000-000000000003',
    date '2030-01-01',
    date '2030-01-03',
    'c1000000-0000-4000-8000-000000000001',
    null,
    null,
    null,
    1,
    0,
    'web',
    'c6000000-0000-4000-8000-000000000001'
  )
)
select is((select reservation_id is not null from first_reservation), true, 'first reservation for contested room succeeds');

select throws_ok(
  $$select * from public.create_reservation('11111111-1111-4111-8111-111111111111', 'c5000000-0000-4000-8000-000000000003', date '2030-01-01', date '2030-01-03', 'c1000000-0000-4000-8000-000000000001', null, null, null, 1, 0, 'web', 'c6000000-0000-4000-8000-000000000002')$$,
  '23P01',
  'room no longer available',
  'second reservation for contested room is rejected'
);
select is((select count(*) from public.room_allocation_holds where room_id = 'c5000000-0000-4000-8000-000000000003'), 1::bigint, 'contested room has exactly one active hold');

select coalesce(string_agg(result, chr(10)), 'ALL CONCURRENCY TESTS PASSED') as results from extensions.finish() as result;
rollback;
