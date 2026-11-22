# Functional Requirements Specification (FRS)

**Status:** Draft for approval · **Version:** 0.1 · **Date:** 20 November 2026
**Priority:** M = must (MVP), S = should, C = could.
**Rule:** A requirement is complete only when its business logic, persistence, authorisation, validation and tests exist. UI alone is not completion.

## 1. Identity, access and staff administration

| ID | Requirement | Priority | Acceptance criteria |
|---|---|---|---|
| AUTH-01 | Users sign in with email + password via Supabase Auth. | M | Invalid credentials show a generic error; session is httpOnly; sign-out clears session. |
| AUTH-02 | Password reset uses a single-use, expiring email link. | M | Expired token rejected; success does not disclose whether an email exists. |
| AUTH-03 | Staff accounts are created only by manager/owner-with-permission. | M | Public sign-up cannot create staff; DB constraint blocks staff role on self-registration. |
| AUTH-04 | Seed the roles: owner, manager, receptionist, bartender, cook, waiter, laundry, housekeeping, accountant, guest. | M | Role rows exist; permission mappings tested. |
| AUTH-05 | A user may hold more than one staff role; effective permissions are the union, except owner read-only default. | M | Test user with receptionist + accountant roles receives both scopes. |
| AUTH-06 | Manager can invite, activate, deactivate and edit staff. | M | Deactivation blocks new sessions; historical records remain. |
| AUTH-07 | Staff cannot assign roles to themselves or elevate another user beyond their own grant authority. | M | Attempt returns 403 and writes a security audit event. |
| AUTH-08 | Optional MFA for owner, manager and accountant. | S | TOTP enrolment and recovery codes; enforced for owner. |
| AUTH-09 | Guest accounts are optional and can be linked to an existing guest record by verified email. | M | Duplicate guest linking uses a controlled merge, never silent overwrite. |
| AUTH-10 | Session timeout after configurable inactivity (default 8h staff, 30 days guest "remember me" optional). | S | Re-auth enforced server-side. |

## 2. Public website and content

| ID | Requirement | Priority | Acceptance criteria |
|---|---|---|---|
| PUB-01 | Homepage with hero, availability search, featured rooms, facilities, dining, services, testimonials, gallery, contact, footer. | M | Responsive; content from settings/CMS tables; LCP budget met. |
| PUB-02 | Pages: About, Rooms, Room detail, Availability, Restaurant, Bar, Services, Gallery, Contact, FAQ, Privacy, Terms, Reservation Policy. | M | All routes reachable; published/draft state respected. |
| PUB-03 | Manager can edit public content, room copy, images, rate display and policies. | M | Changes versioned/audited; public site revalidates within 60s. |
| PUB-04 | Gallery supports ordered images with alt text. | S | Drag/reorder persisted; missing alt text blocks publish. |
| PUB-05 | SEO metadata, Open Graph image, sitemap and robots. | M | Valid metadata; sitemap lists public pages only. |
| PUB-06 | Contact form is rate-limited and stored/queued for follow-up. | S | Spam controls; no PII in logs; acknowledgement email. |
| PUB-07 | Menu pages reflect live availability/price from restaurant and bar products. | S | Unavailable items are not orderable and show "currently unavailable". |

## 3. Rooms, floors and housekeeping

| ID | Requirement | Priority | Acceptance criteria |
|---|---|---|---|
| RMS-01 | Manager creates/edits/deactivates floors. | M | Cannot deactivate a floor with active rooms unless reassigned. |
| RMS-02 | Manager manages room categories, base rates, occupancy limits, amenities and images. | M | Rate changes are audited and never rewrite historical reservation prices. |
| RMS-03 | Manager creates rooms with number, floor, category, rate override, description, max occupancy, status. | M | Unique room number per hotel; invalid floor/category rejected. |
| RMS-04 | Room operational states: available, maintenance, out_of_service. | M | Maintenance/out-of-service rooms excluded from availability. |
| RMS-05 | Housekeeping states: clean, dirty, cleaning, inspection, blocked. | M | Room cannot be offered as sellable until housekeeping is clean/inspected. |
| RMS-06 | Unified room status view combines occupancy (from stays), operational state and housekeeping. | M | Status consistent across reception, housekeeping and availability search. |
| RMS-07 | Manager records maintenance with reason, dates, cost, vendor, evidence. | S | Room blocked for overlapping dates; completion releases room after cleaning. |
| RMS-08 | Room images stored in Supabase Storage with alt text and sort order. | M | Public reads limited to published images; writes manager-only. |
| HSK-01 | Checkout automatically creates a departure cleaning task (idempotent). | M | Repeated checkout does not duplicate tasks. |
| HSK-02 | Stayover cleaning tasks can be generated daily for occupied rooms. | S | Duplicate task per room/date prevented. |
| HSK-03 | Manager/housekeeping supervisor assigns tasks and sees workload. | M | Assignment notifies assignee; reassignment audited. |
| HSK-04 | Attendant starts/completes cleaning and can report maintenance issues. | M | Status transitions validated; maintenance issue creates a linked record. |
| HSK-05 | Supervisor inspects and releases room to clean/available. | M | Room cannot be released without inspection when policy requires it. |
| HSK-06 | Cleaning history per room visible with staff, duration, notes and photos. | S | Photos private; signed URLs. |
| HSK-07 | Housekeeping dashboard shows dirty, in-progress, inspection and blocked rooms. | M | Board updates after staff actions. |

## 4. Availability and reservations

| ID | Requirement | Priority | Acceptance criteria |
|---|---|---|---|
| RES-01 | Search availability by check-in, check-out, adults, children and optional room type. | M | Returns only rooms not held by active reservations and not blocked for maintenance/OOS. |
| RES-02 | Stay interval is `[check_in, check_out)`; same-day turnover is allowed. | M | One-night stay does not block the next arrival date. |
| RES-03 | Server recalculates nights, rate, taxes, fees, discount, total, required deposit and balance. | M | Client-submitted totals are ignored/rejected on mismatch. |
| RES-04 | Create reservation for registered or anonymous guest. | M | Reference is non-predictable; duplicate active holds for same room/dates rejected. |
| RES-05 | Deposit percentage and mandatory/optional deposit are manager settings. | M | Changing setting does not alter existing reservations. |
| RES-06 | Guest may pay required deposit or full accommodation amount. | M | Both options reconcile to the same folio; balance updates after verified payment. |
| RES-07 | Pending unpaid online reservations expire after configured hold; inventory released. | M | Expired reservation cannot be paid into confirmed state; job is idempotent. |
| RES-08 | Statuses: pending, confirmed, checked_in, checked_out, cancelled, no_show, expired. | M | Transitions validated by a state machine; status history recorded. |
| RES-09 | Payment status is separate from reservation status. | M | A confirmed reservation can have partial payment; a paid reservation can be cancelled. |
| RES-10 | Front desk can modify dates, room and occupancy with availability and reprice validation. | M | Modification audited; price delta visible; conflict blocked. |
| RES-11 | Manager can create and manage rate plans/discounts with reason and expiry. | S | No negative totals; discount cannot exceed configured maximum. |
| RES-12 | Overlapping active reservation is impossible at the database level. | M | Postgres exclusion constraint; concurrency test with two parallel bookings yields one success and one clean conflict. |
| RES-13 | Reservations linked to a folio and guest; multiple guests per room supported. | M | Primary guest required; additional guests optional. |
| RES-14 | Booking source recorded (web, phone, walk-in, OTA, staff). | M | Reporting by source available. |
| RES-15 | No-show workflow releases room and applies approved fee. | S | Fee posts to folio/ledger with reason; room released. |
| RES-16 | Reservation status history is append-only. | M | User, timestamp, from, to, reason. |
| RES-17 | Staff can view today's arrivals/departures and search by reference/guest/phone. | M | Search results permission-scoped; recent searches not leaked. |

## 5. Guests

| ID | Requirement | Priority | Acceptance criteria |
|---|---|---|---|
| GST-01 | Central guest profile with name, email, phone, address, optional ID, emergency contact, notes, consent. | M | Duplicate detection on normalized email/phone before creation. |
| GST-02 | Guest history: reservations, stays, folios, payments, receipts. | M | Visible only to permitted staff and the guest themselves. |
| GST-03 | Guest account links to exactly one guest record; multiple emails not allowed. | M | Link by verified auth email; merge request audited. |
| GST-04 | Staff can merge duplicates with field selection and audit. | S | Surviving profile retains history; merged profile archived. |
| GST-05 | Anonymous guest booking lookup requires reference + email or phone verification and rate limiting. | M | Wrong factor generic failure; lockout/backoff after repeated attempts. |
| GST-06 | Guest can update allowed profile fields; legal identity fields require staff verification. | M | Changes audited; email change requires re-verification. |
| GST-07 | Guest can request data export/delete; staff fulfil per retention policy. | S | Request tracked; accounting records retained as required. |

## 6. Front desk, folio and billing

| ID | Requirement | Priority | Acceptance criteria |
|---|---|---|---|
| FNT-01 | Check-in retrieves reservation, verifies guest/room, shows balance and accepts payment. | M | Cannot check in cancelled/expired/no-show/already checked-in reservation. |
| FNT-02 | Check-in records actual time and staff, changes reservation to checked_in and room to occupied. | M | Transition atomic; audit written; room status visible to housekeeping. |
| FNT-03 | Check-out produces consolidated folio across all departments. | M | Accommodation, F&B, laundry, services, taxes, discounts, payments, refunds, adjustments and balance shown. |
| FNT-04 | Checkout blocked by outstanding balance unless authorised outstanding settlement is recorded. | M | Authoriser, reason and threshold captured; audit and accounts receivable updated. |
| FNT-05 | Checkout records time, closes folio (unless post-stay balance approved), queues housekeeping. | M | Repeated checkout is idempotent; room cannot be marked available before cleaning. |
| FNT-06 | Departmental charges post to the correct open folio by stay/room. | M | Charging to a checked-out/closed folio is blocked. |
| FNT-07 | Split charges or move charge between folios requires manager permission and reason. | S | Original item voided with trail; new item created; totals reconcile. |
| FNT-08 | Adjustments (discount, correction, write-off) require reason and permission. | M | Cannot delete charges; append adjustment; audit and ledger posting. |
| FNT-09 | Receipts are numbered, printable and downloadable as PDF. | M | Number unique; reprints watermarked "duplicate". |
| FNT-10 | Front desk can search and open a guest bill at any time. | M | Includes checked-out guests with post-stay balances. |
| FNT-11 | Walk-in F&B/laundry can be billed without a reservation by creating a walk-in folio. | M | Guest optional for walk-in; guest details captured when supplied. |
| FNT-12 | Folio totals and balance are calculated server-side and read from a single view. | M | No client arithmetic trusted; tests cover rounding. |

## 7. Payments, refunds and reconciliation

| ID | Requirement | Priority | Acceptance criteria |
|---|---|---|---|
| PAY-01 | Paystack initialisation creates a unique reference tied to folio/reservation and amount. | M | Amount in kobo; reference unique; pending payment recorded before redirect. |
| PAY-02 | Server verifies Paystack transaction before marking successful. | M | Never trust callback/frontend; failed verification leaves pending/failed. |
| PAY-03 | Webhook verifies HMAC SHA-512 signature over raw body. | M | Invalid signature rejected 401 and logged. |
| PAY-04 | Webhook processing is idempotent by provider event ID and reference. | M | Replaying same event creates no duplicate payment/ledger entry. |
| PAY-05 | Cash payment recorded by authorised staff with amount, date, folio, notes. | M | Requires open/permitted folio; receipt issued; cashier recorded. |
| PAY-06 | POS payment records POS reference, terminal, amount, date, staff. | M | POS reference uniqueness policy enforced for duplicate detection. |
| PAY-07 | Bank transfer is submitted pending verification with reference/date/evidence. | M | Balance unchanged until approval; evidence optional and not proof. |
| PAY-08 | Authorised manager/accountant approves/rejects transfer with notes. | M | Checker cannot approve own submission; both identities recorded. |
| PAY-09 | Payments can be made before arrival, at any point in stay, at checkout and after checkout. | M | Guest portal and desk flows both supported; folio status permits post-stay. |
| PAY-10 | Partial payments supported with accurate outstanding balance. | M | Overpayment is rejected or explicitly held as credit with approval. |
| PAY-11 | Refunds are new records linked to original payment; approvals by manager/accountant. | M | Original payment remains; status becomes partially_refunded/refunded; ledger reversal. |
| PAY-12 | Duplicate payment references and double submissions blocked. | M | Unique constraints and idempotency keys; user receives clear message. |
| PAY-13 | Payment statuses: pending, pending_verification, successful, failed, rejected, partially_refunded, refunded. | M | State machine enforced; timestamps and actors recorded. |
| PAY-14 | Financial records are never deleted to fix errors. | M | Reversal/adjustment only; DB trigger blocks deletes for posted records. |
| PAY-15 | Paystack refunds reconciled via API/webhook. | S | Refund status updated; failure alerts accountant. |
| PAY-16 | Daily reconciliation view groups by method and verifier. | M | Totals match ledger; unmatched items listed. |
| PAY-17 | Payment webhooks and retries observable with replay action. | S | Admin can view event status and requeue safe events. |

## 8. Restaurant and kitchen

| ID | Requirement | Priority | Acceptance criteria |
|---|---|---|---|
| FNB-01 | Manager manages food categories, menu items, prices, photos, availability, prep time, recipes. | M | Historical order prices unchanged after edits. |
| FNB-02 | Guests/staff create restaurant orders for room, table or walk-in. | M | Room orders require active stay; table orders require valid table. |
| FNB-03 | Order items capture quantity, unit price snapshot, modifiers/notes and tax. | M | Server recalculates totals; discounts permissioned. |
| FNB-04 | Kitchen workflow: pending → accepted → preparing → ready → delivered. | M | Invalid transitions rejected; actor and timestamp per transition. |
| FNB-05 | Cook dashboard receives new orders, shows age/timer, notes and recipe/ingredient info. | M | New order visible within 5s (realtime or polling); sound/visual cue configurable. |
| FNB-06 | Waiter receives ready notifications and marks delivery with destination. | M | Cannot deliver order not ready; delivery recorded. |
| FNB-07 | Room-service charges post automatically to the guest folio on order placement/fulfilment per policy. | M | No duplicate posting on retries; void/cancel reverses before close. |
| FNB-08 | Restaurant orders can be paid by folio charge, Paystack, cash, POS or transfer. | M | Payment method recorded; mixed payment not allowed without split-payment workflow. |
| FNB-09 | Kitchen stock deducts recipe ingredients exactly once when preparation starts. | M | Idempotent movement key; cancellation after deduction records wastage/reversal. |
| FNB-10 | Menu item availability is separate from stock availability; 86'ing an item hides ordering. | S | Staff can mark item unavailable with reason and auto-recover option. |
| FNB-11 | Order cancellation/void requires permission once preparing. | M | Reason captured; stock/charge impacts explicit. |

## 9. Bar

| ID | Requirement | Priority | Acceptance criteria |
|---|---|---|---|
| BAR-01 | Manager manages bar categories, products, prices, photos, stock link and availability. | M | Product may map to inventory item and pour/unit quantity. |
| BAR-02 | Bartender creates and updates bar orders and sees assigned queue. | M | Only bar staff/permitted roles can change bar order status. |
| BAR-03 | Order lifecycle: pending → accepted → preparing → ready → delivered; served/closed. | M | Transition validation and timestamps. |
| BAR-04 | Bar order fulfilment reduces linked inventory exactly once. | M | Deduction occurs on configured transition; retry safe; movement recorded. |
| BAR-05 | Room/table/walk-in destination supported; guest folio posting works. | M | Room charge appears on consolidated folio. |
| BAR-06 | Bartender records authorised stock usage/wastage through inventory workflow. | M | No free-text stock adjustment outside permission. |
| BAR-07 | Age-restricted items can be flagged and require staff confirmation. | C | Sale blocked without attestation where enabled. |

## 10. Laundry

| ID | Requirement | Priority | Acceptance criteria |
|---|---|---|---|
| LND-01 | Manager manages laundry service categories, items, prices and turnaround. | M | Edits do not change historical orders. |
| LND-02 | Staff creates laundry request linked to guest/room with itemised quantities and instructions. | M | Requires active stay or walk-in folio; quantities > 0. |
| LND-03 | Statuses: received → processing → ready → delivered; cancelled. | M | Transitions audited; cancel reason required after processing. |
| LND-04 | Charges post automatically to guest folio. | M | Amount server-calculated; duplicate prevention. |
| LND-05 | Inventory deduction for detergents/consumables via configured usage rules. | S | Deduction idempotent and traceable to order. |
| LND-06 | Attendant records received items, discrepancies and delivery confirmation. | M | Discrepancy note required if delivered quantity differs. |
| LND-07 | Laundry activity history and daily totals visible. | M | Filter by date/status/attendant. |

## 11. Inventory

| ID | Requirement | Priority | Acceptance criteria |
|---|---|---|---|
| INV-01 | Manager creates categories, items, units, storage locations, suppliers, reorder levels, opening stock. | M | Opening stock creates a movement; no direct quantity edit. |
| INV-02 | Record purchases/receipts with supplier, invoice, unit cost, tax and evidence. | M | Purchase lines create movements; totals reconcile. |
| INV-03 | Record usage, wastage, expiry and adjustments with reason and department. | M | Every change is append-only with before/after quantity. |
| INV-04 | Transfer stock between locations with in/out movements. | S | Both sides atomic; quantity conserved. |
| INV-05 | Automatic deductions for bar fulfilment, kitchen recipes and laundry usage. | M | Exactly-once via idempotency key; transactional with order state. |
| INV-06 | Low-stock alerts when at/below reorder level. | M | Alert appears on manager/owner dashboards and notifications. |
| INV-07 | Inventory valuation using moving weighted average cost. | M | Formula documented and covered by tests; valuation report reconciles. |
| INV-08 | Stock movement history filterable by item, department, type, date, staff. | M | Exportable CSV/XLSX. |
| INV-09 | Expiry tracking and expired-stock report where expiry is supplied. | S | Items past expiry flagged, not auto-deducted. |
| INV-10 | Negative stock blocked unless an authorised override with reason. | M | Default policy: block; override permissioned and audited. |
| INV-11 | Physical count workflow with variance approval. | S | Count sheet, variance, approval, adjustment movements. |

## 12. Staff, attendance and shifts

| ID | Requirement | Priority | Acceptance criteria |
|---|---|---|---|
| STF-01 | Staff profile includes staff ID, department, role, contacts, employment status, hire date. | M | Staff ID unique; deactivation preserves history. |
| STF-02 | Manager creates/configures shift templates (name, start/end, department, grace). | M | Overnight shifts handled correctly across midnight. |
| STF-03 | Manager assigns staff to shifts by date; coverage view by department. | M | Overlapping assignment warns/blocks per policy; changes audited. |
| ATT-01 | Staff clock in/out for an assigned shift. | M | One open attendance record per staff; duplicate clock-in blocked. |
| ATT-02 | System records late arrival/early departure against shift and grace. | M | Status computed server-side in hotel timezone. |
| ATT-03 | Staff can add a note; manager can adjust with mandatory reason. | M | Adjustments audited; original values retained. |
| ATT-04 | Manager views daily, weekly, monthly attendance and exceptions. | M | Filter by department/staff; export. |
| ATT-05 | Absence/no-show recorded via explicit workflow, not inferred only. | S | Manager marks absent with reason; notification. |
| HND-01 | Formal shift handover with checklist: guests, arrivals, departures, balances, pending transfers, issues, maintenance, orders, cash, notes. | M | Outgoing creates; incoming acknowledges; timestamps/users recorded. |
| HND-02 | Handover cannot be edited after acknowledgement; corrections are addenda. | M | Append-only; discrepancies flagged. |
| HND-03 | Cash collected vs expected is part of handover. | S | Variance requires explanation; manager review. |
| PRF-01 | Staff performance indicators derived from completed orders/tasks, attendance, punctuality. | S | Metric definitions documented; no punitive automation. |
| PRF-02 | Manager can view department and individual performance for a date range. | S | Exportable; based on immutable activity data. |

## 13. Expenses and accounting

| ID | Requirement | Priority | Acceptance criteria |
|---|---|---|---|
| EXP-01 | Manager/accountant creates expense categories and expenses with amount, department, date, vendor, evidence. | M | Negative amounts rejected; category active required. |
| EXP-02 | Expenses have approval workflow where configured. | M | Submitter cannot self-approve above threshold; approver + timestamp recorded. |
| EXP-03 | Approved expense posts to the ledger and appears in reports. | M | No ledger posting for draft/rejected; reversal for corrections. |
| FIN-01 | Chart of accounts supports cash, bank, card/Paystack clearing, receivables, revenue by department, tax payable, expenses, refunds. | M | Accounts seeded; IDs stable. |
| FIN-02 | Every successful payment, refund, adjustment and approved expense posts a balanced journal. | M | Debits = credits enforced by trigger; test coverage. |
| FIN-03 | Distinguish cash collected, revenue recognised, receivables, pending payments, verified payments, expenses, refunds. | M | Dashboard labels and definitions documented. |
| FIN-04 | Revenue by department and payment method. | M | Derived from ledger, not duplicated totals. |
| FIN-05 | Outstanding guest balances (including post-stay) report. | M | Ageing buckets; drill-down to folio. |
| FIN-06 | Refunds and adjustments report with approvers and reasons. | M | Full traceability. |
| FIN-07 | Daily financial close summary with method totals and exceptions. | M | Printable/downloadable; matches ledger. |
| FIN-08 | No claim of "profit" unless expenses, refunds and recognised revenue are included and defined. | M | UI uses "net operating result" with tooltip/methodology. |

## 14. Dashboards and reporting

| ID | Requirement | Priority | Acceptance criteria |
|---|---|---|---|
| DSH-01 | Owner executive dashboard with revenue, departments, methods, expenses, net operating result, occupancy, reservations, guests, staff, attendance, performance, inventory, alerts, activities. | M | All figures server-computed; date range filter; read-only. |
| DSH-02 | Manager operations dashboard with room states, arrivals, departures, in-house, pending items, receipts, balances, duty staff, exceptions, orders, low stock. | M | Live-ish refresh; actionable links. |
| DSH-03 | Department dashboards for reception, restaurant, kitchen, bar, laundry, housekeeping, accounting. | M | Each shows role-relevant queues and KPIs only. |
| DSH-04 | Guest dashboard with stays, folio, charges, payments, receipts, profile. | M | Guest sees only own data; mobile-friendly. |
| RPT-01 | Daily operational report. | M | Date filter; PDF/XLSX/CSV; server-generated. |
| RPT-02 | Daily financial report. | M | Includes all methods, pending verification, refunds, expenses, receivables. |
| RPT-03 | Staff performance report. | S | Attendance, shifts, completed activities, department metrics. |
| RPT-04 | Inventory report: opening, additions, consumption, adjustments, wastage, closing, valuation. | M | Reconciles to movements. |
| RPT-05 | Reservation/occupancy report. | M | Occupancy formula documented; excludes OOS rooms consistently. |
| RPT-06 | Custom date filters and department filters. | M | Timezone-aware boundaries (hotel timezone). |
| RPT-07 | Export files branded, include generated-by/time and applied filters. | M | Download logged; access controlled. |
| RPT-08 | Scheduled daily email summary to owner/manager. | S | Opt-in; failure visible and retryable. |

## 15. Notifications and settings

| ID | Requirement | Priority | Acceptance criteria |
|---|---|---|---|
| NTF-01 | In-app notifications for reservation, payment, arrival/departure, new orders, ready orders, housekeeping, low stock, attendance, shift, handover and management events. | M | Unread count; mark read; role-scoped. |
| NTF-02 | Transactional email via configurable provider (default Resend). | M | Templates versioned; retries; bounce handling. |
| NTF-03 | Notification preferences per user for non-critical categories. | S | Critical security/financial notices cannot be disabled. |
| NTF-04 | Low-stock alerts deduplicated (not spammed every minute). | M | Alert once per crossing; re-arm after restock. |
| SET-01 | Hotel settings: name, contact, address, timezone, currency, tax, check-in/out, deposit %, hold duration, cancellation/refund policy, booking terms, receipt prefix. | M | Validated; changes audited; no hardcoded values in code. |
| SET-02 | Role and permission management UI for owner/manager. | M | Cannot remove own last admin path; changes audited. |
| SET-03 | Public content management for site copy, images and policies. | M | Draft/publish; audit. |
| SET-04 | Payment provider keys managed via environment secrets, not database/UI. | M | Key presence health check; rotation procedure documented. |

## 16. Audit and administration

| ID | Requirement | Priority | Acceptance criteria |
|---|---|---|---|
| AUD-01 | Append-only audit log for auth, role, settings, rate, reservation, folio, payment, refund, inventory, expense, attendance adjustments and public-content changes. | M | Actor, action, entity, before/after (redacted), IP/UA, request ID, timestamp. |
| AUD-02 | Audit log readable by owner/manager (and accountant for financial scope) with filters. | M | No update/delete policy; export permissioned. |
| AUD-03 | Security events (failed logins, permission denials, webhook signature failures) recorded. | M | Alert thresholds configured. |
| AUD-04 | Staff activity log for operational events (clock-in, order transitions, task completion). | S | Feeds performance reports. |
| AUD-05 | Data retention and purge jobs documented and tested. | S | Audit/finance retained per policy; guest marketing data purgeable. |
