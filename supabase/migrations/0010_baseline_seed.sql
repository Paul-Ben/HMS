insert into public.hotels (id, code, name, timezone, currency, address, contacts, is_active)
values ('11111111-1111-4111-8111-111111111111', 'AUR', 'Aurelia Hotel & Suites', 'Africa/Lagos', 'NGN', '{}'::jsonb, '{}'::jsonb, true)
on conflict (code) do update
set name = excluded.name,
    timezone = excluded.timezone,
    currency = excluded.currency,
    is_active = true;

insert into public.hotel_settings (hotel_id, tax_rate, service_charge_rate, check_in_time, check_out_time, receipt_prefix, cancellation_hours, late_checkout_grace_minutes, social_links)
values ('11111111-1111-4111-8111-111111111111', 7.50, 0, '14:00', '12:00', 'RCP', 48, 10, '{}'::jsonb)
on conflict (hotel_id) do update
set tax_rate = excluded.tax_rate,
    service_charge_rate = excluded.service_charge_rate,
    check_in_time = excluded.check_in_time,
    check_out_time = excluded.check_out_time,
    receipt_prefix = excluded.receipt_prefix,
    cancellation_hours = excluded.cancellation_hours,
    late_checkout_grace_minutes = excluded.late_checkout_grace_minutes;

insert into public.departments (key, name, is_active)
select key, name, true
from (values
  ('front_desk', 'Front Desk'),
  ('restaurant', 'Restaurant'),
  ('kitchen', 'Kitchen'),
  ('bar', 'Bar'),
  ('laundry', 'Laundry'),
  ('housekeeping', 'Housekeeping'),
  ('accounting', 'Accounting'),
  ('inventory', 'Inventory')
) as d(key, name)
on conflict (key) do update set name = excluded.name, is_active = true;

insert into public.roles (key, name, is_system)
select key, name, true
from (values
  ('owner', 'Owner'),
  ('manager', 'Manager'),
  ('receptionist', 'Receptionist'),
  ('bartender', 'Bartender'),
  ('cook', 'Cook'),
  ('waiter', 'Waiter'),
  ('laundry', 'Laundry'),
  ('housekeeping', 'Housekeeping'),
  ('accountant', 'Accountant'),
  ('guest', 'Guest')
) as r(key, name)
on conflict (key) do update set name = excluded.name, is_system = true;

insert into public.permissions (key, description, scope)
select key, key, 'self'::public.permission_scope
from unnest(array[
  'profile.read_self', 'profile.update_self', 'attendance.self', 'payment.online', 'refund.request', 'notifications.read'
]) as keys(key)
on conflict (key) do update set scope = excluded.scope;

insert into public.permissions (key, description, scope)
select key, key, 'assigned'::public.permission_scope
from unnest(array[
  'housekeeping.execute', 'housekeeping.inspect', 'order.deliver', 'handover.acknowledge'
]) as keys(key)
on conflict (key) do update set scope = excluded.scope;

insert into public.permissions (key, description, scope)
select key, key, 'department'::public.permission_scope
from unnest(array[
  'staff.read', 'maintenance.report', 'housekeeping.read', 'housekeeping.assign', 'folio.charge',
  'payment.cash', 'payment.pos', 'payment.transfer.submit', 'order.read', 'order.create',
  'order.kitchen.update', 'order.bar.update', 'menu.read', 'recipe.usage', 'bar_stock.usage',
  'laundry.read', 'laundry.create', 'laundry.process', 'laundry.deliver', 'inventory.read',
  'inventory.usage', 'attendance.read_department', 'handover.create', 'handover.read',
  'expense.create', 'reports.operational'
]) as keys(key)
on conflict (key) do update set scope = excluded.scope;

insert into public.permissions (key, description, scope)
select key, key, 'all'::public.permission_scope
from unnest(array[
  'staff.read_hr', 'staff.manage', 'staff.assign_roles', 'roles.manage', 'audit.read', 'audit.read_finance',
  'rooms.read', 'rooms.manage', 'rates.manage', 'room_status.manage', 'availability.read',
  'reservation.create', 'reservation.update', 'reservation.cancel', 'reservation.checkin',
  'reservation.checkout', 'reservation.expire', 'guest.read', 'guest.manage', 'guest.merge',
  'folio.read', 'folio.adjust', 'folio.void', 'payment.transfer.verify', 'refund.approve',
  'receipt.read', 'ledger.read', 'order.cancel', 'menu.manage', 'laundry.services.manage',
  'inventory.read_cost', 'inventory.manage', 'inventory.purchase', 'inventory.adjust',
  'inventory.transfer', 'inventory.recipes.manage', 'shifts.read', 'shifts.manage',
  'attendance.read', 'attendance.adjust', 'performance.read', 'expense.approve',
  'expense.categories.manage', 'reports.financial', 'reports.inventory', 'reports.staff',
  'settings.manage', 'content.manage', 'policy.manage'
]) as keys(key)
on conflict (key) do update set scope = excluded.scope;

insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
from public.roles r
cross join public.permissions p
where r.key = 'manager'
  and p.key not in ('roles.manage', 'refund.request', 'audit.read_finance')
on conflict do nothing;

insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
from public.roles r
join public.permissions p on p.key = any(array[
  'profile.read_self', 'staff.read', 'staff.read_hr', 'audit.read', 'rooms.read', 'availability.read',
  'housekeeping.read', 'guest.read', 'folio.read', 'receipt.read', 'ledger.read', 'order.read',
  'menu.read', 'laundry.read', 'inventory.read', 'inventory.read_cost', 'shifts.read', 'handover.read',
  'performance.read', 'reports.operational', 'reports.financial', 'reports.inventory', 'reports.staff',
  'notifications.read'
])
where r.key = 'owner'
on conflict do nothing;

insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
from public.roles r
join public.permissions p on p.key = any(array[
  'profile.read_self', 'profile.update_self', 'staff.read', 'rooms.read', 'maintenance.report',
  'housekeeping.read', 'availability.read', 'reservation.create', 'reservation.update',
  'reservation.cancel', 'reservation.checkin', 'reservation.checkout', 'reservation.expire',
  'guest.read', 'guest.manage', 'folio.read', 'folio.charge', 'payment.cash', 'payment.pos',
  'payment.transfer.submit', 'payment.online', 'receipt.read', 'order.read', 'order.create',
  'menu.read', 'laundry.read', 'laundry.create', 'attendance.self', 'attendance.read_department',
  'shifts.read', 'handover.create', 'handover.acknowledge', 'handover.read', 'reports.operational',
  'notifications.read'
])
where r.key = 'receptionist'
on conflict do nothing;

insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
from public.roles r
join public.permissions p on p.key = any(array[
  'profile.read_self', 'profile.update_self', 'staff.read', 'maintenance.report', 'folio.charge',
  'order.read', 'order.create', 'order.bar.update', 'order.deliver', 'menu.read', 'bar_stock.usage',
  'inventory.read', 'inventory.usage', 'attendance.self', 'shifts.read', 'reports.operational',
  'notifications.read'
])
where r.key = 'bartender'
on conflict do nothing;

insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
from public.roles r
join public.permissions p on p.key = any(array[
  'profile.read_self', 'profile.update_self', 'staff.read', 'maintenance.report', 'folio.charge',
  'order.read', 'order.kitchen.update', 'menu.read', 'recipe.usage', 'inventory.read',
  'inventory.usage', 'attendance.self', 'shifts.read', 'reports.operational', 'notifications.read'
])
where r.key = 'cook'
on conflict do nothing;

insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
from public.roles r
join public.permissions p on p.key = any(array[
  'profile.read_self', 'profile.update_self', 'staff.read', 'rooms.read', 'maintenance.report',
  'folio.charge', 'order.read', 'order.deliver', 'menu.read', 'attendance.self', 'shifts.read',
  'reports.operational', 'notifications.read'
])
where r.key = 'waiter'
on conflict do nothing;

insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
from public.roles r
join public.permissions p on p.key = any(array[
  'profile.read_self', 'profile.update_self', 'staff.read', 'rooms.read', 'maintenance.report',
  'folio.charge', 'laundry.read', 'laundry.create', 'laundry.process', 'laundry.deliver',
  'inventory.read', 'inventory.usage', 'attendance.self', 'shifts.read', 'reports.operational',
  'notifications.read'
])
where r.key = 'laundry'
on conflict do nothing;

insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
from public.roles r
join public.permissions p on p.key = any(array[
  'profile.read_self', 'profile.update_self', 'staff.read', 'rooms.read', 'maintenance.report',
  'housekeeping.read', 'housekeeping.execute', 'inventory.read', 'inventory.usage',
  'attendance.self', 'shifts.read', 'notifications.read'
])
where r.key = 'housekeeping'
on conflict do nothing;

insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
from public.roles r
join public.permissions p on p.key = any(array[
  'profile.read_self', 'profile.update_self', 'staff.read', 'staff.read_hr', 'audit.read_finance',
  'rooms.read', 'guest.read', 'folio.read', 'folio.adjust', 'folio.void',
  'payment.transfer.submit', 'payment.transfer.verify', 'refund.approve', 'receipt.read',
  'ledger.read', 'order.read', 'laundry.read', 'inventory.read', 'inventory.read_cost',
  'inventory.purchase', 'inventory.adjust', 'shifts.read', 'attendance.self', 'attendance.read',
  'handover.create', 'handover.acknowledge', 'handover.read', 'performance.read', 'expense.create',
  'expense.approve', 'expense.categories.manage', 'reports.operational', 'reports.financial',
  'reports.inventory', 'reports.staff', 'notifications.read'
])
where r.key = 'accountant'
on conflict do nothing;

insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
from public.roles r
join public.permissions p on p.key = any(array[
  'profile.read_self', 'profile.update_self', 'availability.read', 'reservation.create', 'folio.read',
  'payment.online', 'refund.request', 'receipt.read', 'order.read', 'order.create', 'menu.read',
  'laundry.read', 'notifications.read'
])
where r.key = 'guest'
on conflict do nothing;

insert into public.cancellation_policies (hotel_id, code, name, free_cancellation_hours, charge_type, charge_value, terms, is_default, is_active)
values ('11111111-1111-4111-8111-111111111111', 'STANDARD_48H', 'Standard 48-hour cancellation', 48, 'first_night', null, 'Free cancellation until 48 hours before arrival; first-night no-show fee.', true, true)
on conflict (hotel_id, code) do update
set name = excluded.name,
    free_cancellation_hours = excluded.free_cancellation_hours,
    charge_type = excluded.charge_type,
    is_default = true,
    is_active = true;

insert into public.booking_settings (hotel_id, deposit_percentage, deposit_required, full_payment_allowed, hold_minutes, default_cancellation_policy_code)
values ('11111111-1111-4111-8111-111111111111', 30, true, true, 30, 'STANDARD_48H')
on conflict (hotel_id) do update
set deposit_percentage = excluded.deposit_percentage,
    deposit_required = excluded.deposit_required,
    full_payment_allowed = excluded.full_payment_allowed,
    hold_minutes = excluded.hold_minutes,
    default_cancellation_policy_code = excluded.default_cancellation_policy_code;

insert into public.financial_accounts (hotel_id, code, name, type, normal_balance, is_active)
select '11111111-1111-4111-8111-111111111111', code, name, type::public.financial_account_type, normal_balance, true
from (values
  ('1000', 'Cash', 'asset', 'debit'),
  ('1010', 'Bank', 'asset', 'debit'),
  ('1020', 'Paystack Clearing', 'asset', 'debit'),
  ('1030', 'POS Clearing', 'asset', 'debit'),
  ('1100', 'Guest Receivables', 'asset', 'debit'),
  ('1200', 'Guest Advances', 'liability', 'credit'),
  ('2100', 'Tax Payable', 'liability', 'credit'),
  ('2200', 'Refunds Payable', 'liability', 'credit'),
  ('4000', 'Accommodation Revenue', 'revenue', 'credit'),
  ('4010', 'Restaurant Revenue', 'revenue', 'credit'),
  ('4020', 'Bar Revenue', 'revenue', 'credit'),
  ('4030', 'Laundry Revenue', 'revenue', 'credit'),
  ('4040', 'Other Income', 'revenue', 'credit'),
  ('5000', 'Operating Expenses', 'expense', 'debit')
) as a(code, name, type, normal_balance)
on conflict (hotel_id, code) do update
set name = excluded.name,
    type = excluded.type,
    normal_balance = excluded.normal_balance,
    is_active = true;

insert into public.room_categories (hotel_id, name, slug, base_rate, currency, max_occupancy, bed_config, size_sqm, sort_order, is_active)
select '11111111-1111-4111-8111-111111111111', name, slug, base_rate, 'NGN', max_occupancy, bed_config, size_sqm, sort_order, true
from (values
  ('Classic Queen', 'classic-queen', 68000, 2, 'Queen bed', 28, 1),
  ('Deluxe King', 'deluxe-king', 95000, 2, 'King bed', 34, 2),
  ('Garden Twin', 'garden-twin', 82000, 2, 'Two twin beds', 30, 3),
  ('Premier Suite', 'premier-suite', 165000, 3, 'King bed + sofa bed', 55, 4),
  ('The Penthouse', 'penthouse', 380000, 4, 'King bed + guest room', 110, 5)
) as c(name, slug, base_rate, max_occupancy, bed_config, size_sqm, sort_order)
on conflict (hotel_id, slug) do update
set name = excluded.name,
    base_rate = excluded.base_rate,
    max_occupancy = excluded.max_occupancy,
    bed_config = excluded.bed_config,
    size_sqm = excluded.size_sqm,
    sort_order = excluded.sort_order,
    is_active = true;

insert into public.floors (hotel_id, name, level, sort_order, is_active)
select '11111111-1111-4111-8111-111111111111', name, level, level, true
from (values
  ('First floor', 1),
  ('Second floor', 2),
  ('Third floor', 3),
  ('Fourth floor', 4),
  ('Penthouse', 5)
) as f(name, level)
on conflict (hotel_id, name) do update
set level = excluded.level,
    sort_order = excluded.sort_order,
    is_active = true;

insert into public.amenities (hotel_id, name, is_active)
select '11111111-1111-4111-8111-111111111111', name, true
from unnest(array[
  'Rain shower', 'Smart TV', 'Work desk', 'Nespresso', 'Wi-Fi', 'In-room safe', 'King bed',
  'Lounge chair', 'Mini bar', 'Garden balcony', 'Twin beds', 'Living room', 'Soaking tub',
  'Butler service', 'Airport transfer', 'Private terrace', 'Dining for six'
]) as a(name)
on conflict (hotel_id, name) do update set is_active = true;

insert into public.rooms (hotel_id, floor_id, category_id, number, currency, max_occupancy, operational_status, housekeeping_status, is_active, sort_order)
select
  '11111111-1111-4111-8111-111111111111',
  f.id,
  c.id,
  rs.number,
  'NGN',
  c.max_occupancy,
  'available'::public.room_operational_status,
  'clean'::public.room_housekeeping_status,
  true,
  rs.sort_order
from (values
  ('101', 'classic-queen', 'First floor', 1),
  ('102', 'classic-queen', 'First floor', 2),
  ('103', 'classic-queen', 'First floor', 3),
  ('104', 'classic-queen', 'First floor', 4),
  ('105', 'classic-queen', 'First floor', 5),
  ('106', 'classic-queen', 'First floor', 6),
  ('108', 'classic-queen', 'First floor', 7),
  ('201', 'deluxe-king', 'Second floor', 8),
  ('202', 'deluxe-king', 'Second floor', 9),
  ('203', 'deluxe-king', 'Second floor', 10),
  ('204', 'deluxe-king', 'Second floor', 11),
  ('205', 'deluxe-king', 'Second floor', 12),
  ('206', 'deluxe-king', 'Second floor', 13),
  ('208', 'deluxe-king', 'Second floor', 14),
  ('301', 'garden-twin', 'Third floor', 15),
  ('302', 'garden-twin', 'Third floor', 16),
  ('303', 'garden-twin', 'Third floor', 17),
  ('304', 'garden-twin', 'Third floor', 18),
  ('305', 'garden-twin', 'Third floor', 19),
  ('306', 'garden-twin', 'Third floor', 20),
  ('401', 'premier-suite', 'Fourth floor', 21),
  ('402', 'premier-suite', 'Fourth floor', 22),
  ('403', 'premier-suite', 'Fourth floor', 23),
  ('404', 'premier-suite', 'Fourth floor', 24),
  ('PH1', 'penthouse', 'Penthouse', 25)
) as rs(number, category_slug, floor_name, sort_order)
join public.room_categories c on c.hotel_id = '11111111-1111-4111-8111-111111111111' and c.slug = rs.category_slug
join public.floors f on f.hotel_id = '11111111-1111-4111-8111-111111111111' and f.name = rs.floor_name
on conflict (hotel_id, number) do update
set floor_id = excluded.floor_id,
    category_id = excluded.category_id,
    max_occupancy = excluded.max_occupancy,
    operational_status = excluded.operational_status,
    housekeeping_status = excluded.housekeeping_status,
    is_active = true,
    sort_order = excluded.sort_order;

insert into public.shifts (hotel_id, department_id, name, start_time, end_time, grace_minutes, is_active)
select '11111111-1111-4111-8111-111111111111', null, s.name, s.start_time, s.end_time, 10, true
from (values
  ('Morning', '06:00'::time, '14:00'::time),
  ('Afternoon', '14:00'::time, '22:00'::time),
  ('Night', '22:00'::time, '06:00'::time)
) as s(name, start_time, end_time)
where not exists (
  select 1
  from public.shifts existing
  where existing.hotel_id = '11111111-1111-4111-8111-111111111111'
    and existing.name = s.name
);
