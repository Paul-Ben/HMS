# Row Level Security (RLS) Policy Matrix

**Status:** Draft for approval · **Version:** 0.2 · **Date:** 22 November 2026

## 1. Principles

1. **Deny by default.** RLS is enabled on every table in `public`; no policy means no access.
2. **Server-side public operations.** Anonymous users have no direct table or business-RPC access. Public booking, availability and lookup go through rate-limited Next.js server routes using a server-only client. Only published content is readable with the anon key.
3. **Authenticated guests** can read/write only their own linked records.
4. **Staff** access is permission- and department-scoped. A role name alone is never sufficient.
5. **Financial and audit rows are append-only.** No application role may update/delete posted payments, bill items, ledger lines, refunds or audit events. Corrections use RPCs that append reversals.
6. **Service role bypasses RLS** and is confined to server code, cron and Edge Functions. It must never be shipped to the browser.
7. **Views exposed to clients use `security_invoker = true`** or are replaced by authorised RPCs; otherwise they can leak base-table data.
8. **RLS is not the only check.** Business-state rules (closed folio, allowed order transition, submitter ≠ verifier) are enforced in RPCs and triggers.

## 2. Helper functions (`private` schema)

```sql
create or replace function private.current_staff_id() returns uuid
language sql stable security definer set search_path = public, pg_temp as $$
  select sp.id from public.staff_profiles sp
  join public.profiles p on p.id = sp.profile_id
  where p.id = auth.uid() and p.is_active and sp.employment_status = 'active'
  limit 1;
$$;

create or replace function private.current_guest_id() returns uuid
language sql stable security definer set search_path = public, pg_temp as $$
  select g.id from public.guests g
  where g.auth_user_id = auth.uid() and g.is_active and g.merged_into_id is null
  limit 1;
$$;

create or replace function private.has_role(role_key text) returns boolean
language sql stable security definer set search_path = public, pg_temp as $$
  select exists (
    select 1 from public.user_roles ur
    join public.roles r on r.id = ur.role_id
    join public.profiles p on p.id = ur.user_id
    where ur.user_id = auth.uid() and r.key = role_key and p.is_active
  );
$$;

create or replace function private.has_permission(permission_key text) returns boolean
language sql stable security definer set search_path = public, pg_temp as $$
  select exists (
    select 1
    from public.user_roles ur
    join public.role_permissions rp on rp.role_id = ur.role_id
    join public.permissions perm on perm.id = rp.permission_id
    join public.profiles p on p.id = ur.user_id
    join public.staff_profiles sp on sp.profile_id = ur.user_id
    where ur.user_id = auth.uid()
      and perm.key = permission_key
      and p.is_active
      and sp.employment_status = 'active'
  );
$$;

create or replace function private.is_staff() returns boolean
language sql stable as $$ select private.current_staff_id() is not null $$;

create or replace function private.is_active_profile() returns boolean
language sql stable security definer set search_path = public, pg_temp as $$
  select exists (select 1 from public.profiles where id = auth.uid() and is_active);
$$;
```

Owner read-only behaviour is expressed by granting owner select policies and only the write policies explicitly configured. The `owner` role does **not** inherit manager write policies.

Department scope is checked with a function that compares the row's `department_id` to the staff profile's department, with manager/accountant exceptions.

## 3. Policy patterns

### 3.1 Guest own-row

```sql
create policy guest_read_own_reservations on public.reservations
for select to authenticated
using (guest_id = private.current_guest_id());
```

Guest writes use narrow RPCs (`guest_update_profile`, `guest_request_cancellation`), not direct table updates. Guests never see internal notes, other guests, staff data or cost values.

### 3.2 Staff permission + scope

```sql
create policy staff_read_reservations on public.reservations
for select to authenticated
using (private.has_permission('reservation.create'));
```

Where department scope applies, the RPC/table carries `department_id` or is joined through a room/order; the policy calls `private.has_department_scope(department_id)` or checks the staff's department. Managers and owner-read have broader select policies.

### 3.3 Public published content

```sql
create policy public_read_published_pages on public.content_pages
for select to anon, authenticated
using (status = 'published');
```

Public room types/gallery/testimonials use similar `is_published`/`is_active` policies. Operational tables are never public.

### 3.4 Append-only

```sql
create policy staff_read_audit on public.audit_logs
for select to authenticated
using (private.has_permission('audit.read'));
-- No INSERT/UPDATE/DELETE policy for application roles.
-- Rows are written by SECURITY DEFINER triggers/functions.
```

## 4. Table policy matrix

Legend: **PUB** published/active rows only; **OWN** own linked rows; **PERM** permission + scope; **DEPT** department scope; **FIN** manager/accountant finance permission; **MGR** manager/owner-write; **SRV** service role/server only; **—** no access; **RO** read-only.

| Table | anon | guest | housekeeping / laundry / kitchen / bar / waiter | receptionist | manager | accountant | owner |
|---|---|---|---|---|---|---|---|
| `content_pages`, `gallery_images`, `testimonials`, `faqs` | PUB | PUB | PUB | RO | MGR | PUB | RO |
| `hotels`, `hotel_settings` | — | — | RO safe view | RO safe view | MGR | RO | RO |
| `booking_settings` | RO public policy fields | RO | RO | RO | MGR | RO | RO |
| `profiles` | — | OWN (limited fields) | OWN; staff directory basic if perm | PERM | MGR | RO staff basic | RO |
| `roles`, `permissions`, `role_permissions` | — | — | RO keys | RO keys | MGR manage | RO | RO |
| `user_roles` | — | OWN effective roles | — | — | MGR via RPC | — | RO |
| `departments` | — | — | RO | RO | MGR | RO | RO |
| `staff_profiles` | — | — | OWN; department roster basic | PERM | MGR | RO basic | RO |
| `staff_activity_logs` | — | — | OWN insert/read via RPC | PERM | RO all | RO finance | RO |
| `audit_logs` | — | — | — | — | RO | finance scope RO | RO |
| `floors`, `room_categories`, `amenities` | RO published | RO | RO | RO | MGR | RO | RO |
| `rooms` | — | — | RO assigned/relevant; no rates | PERM | MGR | RO | RO |
| `room_category_amenities`, `room_amenities`, `room_images` | PUB | PUB | PUB | RO | MGR | PUB | RO |
| `room_maintenance` | — | — | RO own reports; insert report via RPC | RO; create issue | MGR | RO cost | RO |
| `housekeeping_tasks` | — | — | OWN/assigned via RPC; supervisor RO all | RO | MGR | — | RO |
| `guests` | — | OWN limited | Minimal task context via safe RPC; no contact/billing | PERM | MGR | RO billing identity | RO (PII minimised) |
| `reservations` | — | OWN | — (use task/order context) | PERM | MGR | RO financial | RO |
| `reservation_guests`, `reservation_status_history` | — | OWN | — | PERM | MGR | RO | RO |
| `reservation_room_assignments`, `room_allocation_holds` | — | OWN assignment | — | PERM | MGR | RO | RO |
| `cancellation_policies`, `rate_plans` | RO public terms | RO | — | RO | MGR | RO | RO |
| `folios` | — | OWN | — | PERM | MGR | FIN | RO |
| `bills`, `bill_items` | — | OWN | — | PERM | MGR | FIN | RO |
| `payments` | — | OWN (no internal notes) | — | PERM record/read | MGR | FIN all | RO |
| `payment_verifications` | — | — | — | RO submitted transfers | MGR verify | FIN verify | RO |
| `payment_gateway_events` | — | — | — | — | — | FIN RO via view | — |
| `payment_exceptions` | — | — | — | RO own submissions | MGR | FIN | RO |
| `refunds` | — | OWN (status only) | — | RO requested | MGR approve | FIN | RO |
| `receipts` | — | OWN | — | PERM | MGR | FIN | RO |
| `financial_accounts`, `financial_transactions`, `financial_transaction_lines` | — | — | — | — | RO | FIN | RO |
| `financial_adjustments` | — | — | — | RO | MGR approve | FIN | RO |
| `number_sequences` | — | — | — | — | SRV | SRV | — |
| `food_categories`, `food_products`, `bar_categories`, `bar_products` | PUB menu only | PUB | RO dept | RO | MGR | — | RO |
| `food_recipes`, `recipe_ingredients` | — | — | RO kitchen/bar only | — | MGR | — | RO |
| `dining_tables` | RO public labels? no | — | RO | RO | MGR | — | RO |
| `service_orders` | — | OWN | DEPT queue/assigned via RPC | RO/create | MGR | RO totals | RO |
| `service_order_items`, `service_order_status_history` | — | OWN | DEPT | RO | MGR | RO | RO |
| `laundry_services` | PUB | PUB | RO | RO | MGR | — | RO |
| `laundry_orders`, `laundry_order_items` | — | OWN | OWN/DEPT | RO/create | MGR | RO totals | RO |
| `inventory_categories`, `inventory_locations` | — | — | RO relevant | — | MGR | RO | RO |
| `inventory_items` | — | — | DEPT read, no cost | — | MGR | RO cost | RO cost |
| `inventory_movements` | — | — | OWN dept read, no cost | — | MGR | RO | RO |
| `suppliers`, `stock_purchases`, `stock_purchase_items` | — | — | — | — | MGR | FIN | RO |
| `stock_adjustments`, `stock_alerts` | — | — | RO own dept alerts | — | MGR | FIN | RO |
| `shifts`, `staff_shift_assignments` | — | — | OWN schedule | DEPT RO | MGR | RO | RO |
| `attendance_records` | — | — | OWN via RPC | DEPT front-desk RO | MGR | RO | RO |
| `shift_handovers` | — | — | — | DEPT create/ack/read | MGR | FIN cash scope | RO |
| `expense_categories`, `expenses`, `expense_approvals` | — | — | — | — | MGR | FIN | RO |
| `services` | PUB | PUB | PUB | RO | MGR | RO | RO |
| `notifications` | — | OWN | OWN | OWN | OWN | OWN | OWN |
| `email_outbox` | — | — | — | — | SRV | SRV | — |
| `report_exports` | — | — | — | own requested | MGR | own/finance | own |
| `contact_messages` | — | — | — | — | MGR | — | RO |
| `system_settings` | — | — | — | — | SRV/MGR read | — | RO |
| `audit_logs` | — | — | — | — | RO | finance RO | RO |

**Notes**
- "PERM" means the policy uses `private.has_permission(...)` with the exact capability from `docs/04-RBAC-MATRIX.md`.
- Housekeeping and department staff do not read reservation contact or billing data; their RPCs return only task/order context.
- Owner select access is broad but ID documents and private evidence require an explicit permission grant and are never exposed through list views.
- Accountant select on operational tables is financial-scope only; no editing of reservations/rooms.
- Waiter sees assigned/ready orders, not payments or other guests' history.

## 5. Storage bucket policies

| Bucket | Public | Write | Read |
|---|---|---|---|
| `public-media` | Yes (published images only) | Manager/`content.manage` | Everyone |
| `room-images` | Via signed/public URL for published records | `rooms.manage` | Public for active rooms |
| `guest-evidence` (ID, transfer proof) | No | Server upload only after permission check | `payment.transfer.verify`, `guest.read_hr`; short-lived signed URL |
| `receipts` | No | Server-generated only | Guest own; finance roles; signed URL via authorised route |
| `report-exports` | No | Server job only | Requester, manager, accountant; expiring URL |
| `staff-documents` | No | `staff.manage` | `staff.read_hr`, self |

Policies are path-prefixed by hotel, entity type and UUID. Guests never list a bucket; the server issues a signed URL after verifying ownership. Uploads are restricted to MIME types (`image/jpeg`, `image/png`, `application/pdf`) and size limits; filenames are randomised. Storage helpers are `security definer` with pinned `search_path`; published room images are checked through `private.storage_room_is_public()` so anon/RLS restrictions on `public.rooms` cannot suppress public image access. `supabase/tests/storage.sql` passes 15 pgTAP assertions.

## 6. RPC execution matrix

| RPC | anon | guest | department staff | receptionist | manager | accountant | owner |
|---|---|---|---|---|---|---|---|
| `get_available_rooms` (public endpoint wrapper) | via Next server | via Next server | ✓ | ✓ | ✓ | ✓ read | ✓ read |
| `create_reservation` | via Next server | own | — | ✓ | ✓ | — | — |
| `modify_reservation` | — | request only | — | ✓ | ✓ | — | — |
| `cancel_reservation` | — | request only | — | ✓* | ✓ | — | — |
| `check_in`, `check_out` | — | — | — | ✓ | ✓ | — | — |
| `post_bill_item` | — | — | dept order only | ✓ | ✓ | — | — |
| `record_manual_payment` | — | — | — | ✓ | ✓ | ✓ | — |
| `submit_bank_transfer` | — | — | — | ✓ | ✓ | ✓ | — |
| `verify_bank_transfer` | — | — | — | — | ✓ | ✓ | — |
| `confirm_paystack_payment` | — | — | — | — | server | server | — |
| `refund_payment` | — | request | — | — | ✓ | ✓ | — |
| `create_service_order`, `transition_service_order` | — | OWN | dept | — | ✓ | — | — |
| `create_laundry_order`, `cancel_laundry_order`, `deliver_laundry_order` | — | OWN | dept | ✓ | ✓ | RO totals | — |
| `record_inventory_movement`, `record_stock_usage`, `transfer_stock` | — | — | authorised dept | — | ✓ | ✓ adjust | — |
| `receive_stock_purchase`, `request_stock_adjustment`, `approve_stock_adjustment` | — | — | — | — | ✓ | ✓ adjust | — |
| `clock_in`, `clock_out` | — | — | self | self | self | self | self |
| `mark_attendance_exception`, `adjust_attendance` | — | — | — | DEPT | ✓ | RO | — |
| `create_shift_handover`, `submit_shift_handover`, `acknowledge_shift_handover` | — | — | — | ✓ | ✓ | ✓ | — |
| `approve_expense` | — | — | — | — | ✓ | ✓ | — |
| `guest_*` RPCs | — | own | — | — | — | — | — |

\* Within receptionist cancellation policy and value threshold.

Server actions and route handlers use a service-role client **after** authenticating the request and checking the same permission. They never forward arbitrary client payloads into service-role queries.

## 7. RLS test matrix (minimum)

For every table and role: one allow and one deny test. In addition:

| Test | Expected |
|---|---|
| Guest A reads Guest B's reservation/folio/payment/receipt | 0 rows |
| Anonymous calls internal table/RPC directly | denied |
| Deactivated staff retains valid JWT | denied after profile check |
| Receptionist tries to verify own transfer | denied |
| Receptionist tries to approve refund | denied |
| Kitchen staff selects `payments` | denied |
| Housekeeper selects `guests` contact details | denied |
| Owner tries to update a room rate without grant | denied |
| Manager grants self `owner` | denied |
| Manager grants permission they do not hold | denied |
| Accountant updates a reservation | denied |
| Any role updates/deletes a posted ledger line | denied |
| Any role deletes a successful payment | denied |
| Guest reads another guest's storage object | denied |
| Signed URL from a different guest's receipt | denied |
| Staff lists all audit logs without permission | denied |
| Security-definer helper with manipulated `search_path` | safe (pinned) |
| `service_role` key bundled in client | build/test check fails |

Automated with pgTAP in `supabase/tests/` and Playwright for API/storage boundaries. See `docs/11-TESTING.md`.
