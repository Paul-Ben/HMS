# Role and Permission Matrix

**Status:** Draft for approval · **Version:** 0.1 · **Date:** 20 November 2026

## 1. Model

Access is the intersection of four checks:

1. **Authenticated identity** (Supabase Auth user).
2. **Role permission** (`role_permissions` → `permissions.key`), default deny.
3. **Record/department scope** (own records, own department, assigned records, all).
4. **Record state** (e.g. a closed folio cannot accept charges; a posted ledger entry cannot be edited).

RLS enforces row scope in the database. Server actions/route handlers repeat the permission check because RLS on a joined row does not express every business rule. UI visibility is never the control.

### Legend

| Symbol | Meaning |
|---|---|
| **F** | Full: create, read, update within role/department scope (no hard delete of financial/audit records). |
| **R** | Read only. |
| **X** | Execute a specific workflow transition (read + assigned/allowed action). |
| **A** | Approve/verify/authorise, subject to segregation-of-duties rules. |
| **–** | No access. |

### Scope rules

- **Owner:** all-hotel read by default. Writes only where an explicit permission grant exists. Owner cannot self-grant permissions; grants are owner-approved and audited.
- **Manager:** all operational writes and approvals except platform secrets, owner role changes and actions explicitly reserved for the owner.
- **Department staff:** records limited to their department and assigned work. They may read the minimum guest context needed to perform the task (name, room, order notes) but not contact/billing history.
- **Accountant:** finance-wide read; expense and reconciliation writes; verification of transfers and refunds. Cannot alter reservation, room or public content.
- **Guest:** own records only. No staff directory, inventory, internal notes or other guests.
- **Anonymous guest:** access only through a rate-limited lookup using booking reference + email/phone; no direct table access.

## 2. Capability matrix

Columns: **O** owner, **M** manager, **R** receptionist, **B** bartender, **K** cook, **W** waiter, **L** laundry, **H** housekeeping, **A** accountant, **G** guest.

### Identity and staff

| Capability | O | M | R | B | K | W | L | H | A | G |
|---|---|---|---|---|---|---|---|---|---|---|
| View own profile | R | R | R | R | R | R | R | R | R | R |
| Edit own contact details | – | F | F | F | F | F | F | F | F | F |
| View staff directory (basic) | R | F | R | R | R | R | R | R | R | – |
| View staff HR/contact records | R | F | – | – | – | – | – | – | R | – |
| Create/invite staff | – | F | – | – | – | – | – | – | – | – |
| Edit staff profile/department | – | F | – | – | – | – | – | – | – | – |
| Activate/deactivate staff | – | F | – | – | – | – | – | – | – | – |
| Assign staff roles | – | F* | – | – | – | – | – | – | – | – |
| View audit log | R | R | – | – | – | – | – | – | R† | – |
| Manage permissions/role matrix | A | R | – | – | – | – | – | – | – | – |

\* Manager cannot grant `owner`, cannot grant permissions the manager does not hold, and cannot remove the last owner.
† Accountant reads only finance-scoped audit events.

### Rooms, rates and housekeeping

| Capability | O | M | R | B | K | W | L | H | A | G |
|---|---|---|---|---|---|---|---|---|---|---|
| View room inventory/status | R | F | R | – | – | R | R | R | R | R‡ |
| Manage floors/categories/rooms | – | F | – | – | – | – | – | – | – | – |
| Manage rates/rate plans | R | F | – | – | – | – | – | – | R | – |
| Manage room images/amenities | – | F | – | – | – | – | – | – | – | – |
| Put room in maintenance/OOS | – | F | – | – | – | – | – | – | – | – |
| Report maintenance issue | R | X | X | X | X | X | X | X | – | – |
| View housekeeping board | R | F | R | – | – | – | – | F | – | – |
| Assign housekeeping tasks | – | F | – | – | – | – | – | X§ | – | – |
| Start/complete cleaning | – | X | – | – | – | – | – | X | – | – |
| Inspect/release room | – | A | – | – | – | – | – | A§ | – | – |
| View cleaning history | R | R | R | – | – | – | – | R | – | – |

‡ Guest sees public room type/availability, not operational notes.
§ Only if granted housekeeping supervisor permission.

### Reservations and guests

| Capability | O | M | R | B | K | W | L | H | A | G |
|---|---|---|---|---|---|---|---|---|---|---|
| Search room availability | R | F | F | – | – | – | – | – | – | R |
| Create reservation | – | F | F | – | – | – | – | – | – | F¶ |
| Edit reservation (dates/room/occupancy) | – | F | F | – | – | – | – | – | – | – |
| Cancel reservation | – | F | A* | – | – | – | – | – | – | Request |
| Check in guest | – | F | F | – | – | – | – | – | – | – |
| Check out guest | – | F | F | – | – | – | – | – | – | – |
| No-show / expire reservation | – | F | X | – | – | – | – | – | – | – |
| View guest profile/history | R | F | F | – | – | – | – | – | R† | Own |
| Create/edit guest profile | – | F | F | – | – | – | – | – | – | Own limited |
| Merge duplicate guests | – | F | – | – | – | – | – | – | – | – |
| View reservation notes (internal) | R | F | F | – | – | – | – | – | – | – |
| View booking source/rate detail | R | F | F | – | – | – | – | – | R | Own |

¶ Guest may create own reservation; anonymous guest uses public booking. * Receptionist may cancel only within policy and below value threshold; otherwise requests manager approval.
† Accountant sees guest billing identity, not identity documents.

### Billing, payments and refunds

| Capability | O | M | R | B | K | W | L | H | A | G |
|---|---|---|---|---|---|---|---|---|---|---|
| View folio/bill | R | F | F | – | – | – | – | – | R | Own |
| Post departmental charge to folio | – | F | X | X | X | X | X | – | – | – |
| Apply discount/adjustment | – | A | – | – | – | – | – | – | A* | – |
| Void erroneous charge (pre-close) | – | A | – | – | – | – | – | – | A | – |
| Record cash payment | – | F | F | – | – | – | – | – | R | – |
| Record POS payment | – | F | F | – | – | – | – | – | R | – |
| Submit bank transfer | – | F | F | – | – | – | – | – | F | – |
| Verify bank transfer | – | A | – | – | – | – | – | – | A | – |
| Initiate Paystack payment | – | F | F | – | – | – | – | – | – | Own |
| Refund payment | – | A | – | – | – | – | – | – | A | Request |
| Approve post-stay outstanding balance | – | A | – | – | – | – | – | – | A | – |
| Print/reprint receipt | – | F | F | – | – | – | – | – | R | Own |
| View payment verification queue | R | R | R | – | – | – | – | – | F | – |
| View financial ledger | R | R | – | – | – | – | – | – | F | – |

\* Accountant adjustments are restricted to finance corrections with reason; guest-service adjustments are manager-approved. Segregation of duties: a transfer submitter cannot verify the same transfer; a refund requester cannot be the sole approver.

### Restaurant, kitchen and bar

| Capability | O | M | R | B | K | W | L | H | A | G |
|---|---|---|---|---|---|---|---|---|---|---|
| Browse food/bar menus | R | F | R | R | R | R | R | – | – | R |
| Manage menus/categories/prices | – | F | – | – | – | – | – | – | – | – |
| Create food order | – | F | F | – | – | – | – | – | – | F |
| Create bar order | – | F | F | F | – | – | – | – | – | F |
| Update kitchen status | – | X | – | – | X | – | – | – | – | – |
| Update bar status | – | X | – | X | – | – | – | – | – | – |
| Mark order delivered | – | X | – | X | – | X | – | – | – | – |
| Cancel/void order | – | A | – | – | – | – | – | – | – | – |
| View order queue (department) | R | R | R | R | R | R | – | – | R | Own |
| Record recipe ingredient usage | – | X | – | – | X | – | – | – | – | – |
| Record bar stock usage/wastage | – | X | – | X | – | – | – | – | – | – |

### Laundry

| ID capability | O | M | R | B | K | W | L | H | A | G |
|---|---|---|---|---|---|---|---|---|---|---|
| View laundry menu/prices | R | F | R | – | – | – | R | – | – | R |
| Manage laundry services/prices | – | F | – | – | – | – | – | – | – | – |
| Create laundry request | – | F | F | – | – | – | F | – | – | F |
| Receive/record items | – | X | – | – | – | – | X | – | – | – |
| Update processing status | – | X | – | – | – | – | X | – | – | – |
| Record supply usage | – | X | – | – | – | – | X | – | – | – |
| Confirm delivery | – | X | – | – | – | – | X | – | – | – |
| View laundry history | R | F | R | – | – | – | R | – | R | Own |

### Inventory

| Capability | O | M | R | B | K | W | L | H | A | G |
|---|---|---|---|---|---|---|---|---|---|---|
| View stock levels (department) | R | F | – | R | R | – | R | R | R | – |
| View valuation/cost | R | F | – | – | – | – | – | – | R | – |
| Create/edit items/categories | – | F | – | – | – | – | – | – | – | – |
| Record purchases | – | F | – | – | – | – | – | – | F | – |
| Record usage/wastage | – | F | – | X | X | – | X | X | – | – |
| Adjust stock (reason required) | – | A | – | – | – | – | – | – | A | – |
| Transfer stock | – | F | – | – | – | – | – | – | – | – |
| Configure recipes/usage rules | – | F | – | – | – | – | – | – | – | – |
| View low-stock alerts | R | F | – | R | R | – | R | R | R | – |

### Shifts, attendance and handover

| Capability | O | M | R | B | K | W | L | H | A | G |
|---|---|---|---|---|---|---|---|---|---|---|
| View own schedule | R | R | R | R | R | R | R | R | R | – |
| Create/edit shifts | – | F | – | – | – | – | – | – | – | – |
| Assign staff to shifts | – | F | – | – | – | – | – | – | – | – |
| Clock in/out (self) | – | X | X | X | X | X | X | X | X | – |
| View own attendance | R | R | R | R | R | R | R | R | R | – |
| View department attendance | R | F | R* | – | – | – | – | – | R | – |
| Adjust attendance | – | A | – | – | – | – | – | – | – | – |
| Create shift handover | – | F | X | – | – | – | – | – | X | – |
| Acknowledge handover | – | F | X | – | – | – | – | – | X | – |
| View handover history | R | F | R | – | – | – | – | – | R | – |
| View staff performance | R | F | – | – | – | – | – | – | R | – |

\* Receptionist sees front-desk attendance only.

### Finance, settings and reports

| Capability | O | M | R | B | K | W | L | H | A | G |
|---|---|---|---|---|---|---|---|---|---|---|
| View revenue/expense dashboards | R | R | – | – | – | – | – | – | R | – |
| View own departmental sales | R | R | R | R | R | R | R | – | R | – |
| Record expense | – | F | – | – | – | – | – | – | F | – |
| Approve expense | – | A | – | – | – | – | – | – | A | – |
| Manage expense categories | – | F | – | – | – | – | – | – | F | – |
| View ledger/reconciliation | R | R | – | – | – | – | – | – | F | – |
| Generate daily operational report | R | F | F | – | – | – | – | – | R | – |
| Generate financial reports | R | F | – | – | – | – | – | – | F | – |
| Generate inventory reports | R | F | – | – | – | – | – | – | R | – |
| Generate staff reports | R | F | – | – | – | – | – | – | R | – |
| Manage hotel settings | A | F | – | – | – | – | – | – | – | – |
| Manage public content | – | F | – | – | – | – | – | – | – | – |
| Manage deposit/hold/cancellation policy | A | A | – | – | – | – | – | – | – | – |
| Export audit log | A | R | – | – | – | – | – | – | – | – |

## 3. Permission key catalogue (seed)

`profile.read_self`, `profile.update_self`, `staff.read`, `staff.read_hr`, `staff.manage`, `staff.assign_roles`, `roles.manage`, `audit.read`, `audit.read_finance`, `rooms.read`, `rooms.manage`, `rates.manage`, `room_status.manage`, `maintenance.report`, `housekeeping.read`, `housekeeping.assign`, `housekeeping.execute`, `housekeeping.inspect`, `availability.read`, `reservation.create`, `reservation.update`, `reservation.cancel`, `reservation.checkin`, `reservation.checkout`, `reservation.expire`, `guest.read`, `guest.manage`, `guest.merge`, `folio.read`, `folio.charge`, `folio.adjust`, `folio.void`, `payment.cash`, `payment.pos`, `payment.transfer.submit`, `payment.transfer.verify`, `payment.online`, `refund.request`, `refund.approve`, `receipt.read`, `ledger.read`, `order.read`, `order.create`, `order.kitchen.update`, `order.bar.update`, `order.deliver`, `order.cancel`, `menu.read`, `menu.manage`, `recipe.usage`, `bar_stock.usage`, `laundry.read`, `laundry.create`, `laundry.process`, `laundry.deliver`, `laundry.services.manage`, `inventory.read`, `inventory.read_cost`, `inventory.manage`, `inventory.purchase`, `inventory.usage`, `inventory.adjust`, `inventory.transfer`, `inventory.recipes.manage`, `shifts.read`, `shifts.manage`, `attendance.self`, `attendance.read`, `attendance.read_department`, `attendance.adjust`, `handover.create`, `handover.acknowledge`, `handover.read`, `performance.read`, `expense.create`, `expense.approve`, `expense.categories.manage`, `reports.operational`, `reports.financial`, `reports.inventory`, `reports.staff`, `settings.manage`, `content.manage`, `policy.manage`, `notifications.read`.

## 4. Segregation-of-duties rules

1. The staff member who submits a bank transfer may not verify it. Manager/accountant override requires a second approver and audit.
2. The staff member who requests a refund may not be the sole approver.
3. An expense above the configured threshold cannot be self-approved.
4. Owner cannot grant permissions; a manager grant is audited; owner role changes require owner confirmation.
5. Financial posted rows are immutable; corrections use append-only adjustments/refunds.
6. A deactivated staff user retains historical attribution but cannot authenticate or be assigned new work.

## 5. Implementation notes

- Permissions are seeded in a migration and cached per request; never hardcode role names in UI logic.
- A `permissions` key has a `scope` (`self`, `department`, `assigned`, `all`) and the server combines it with data ownership.
- RLS helper: `private.current_staff_id()`, `private.has_permission(key)`, `private.has_any_role(role_names)`, `private.current_guest_id()`.
- RLS tests must cover allow and deny for each role; see `docs/08-RLS-MATRIX.md` and `docs/11-TESTING.md`.
