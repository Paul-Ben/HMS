# Product Requirements Document (PRD)

**Product:** Aurelia Hotel Management System (working name)
**Property:** Single hotel, Victoria Island, Lagos, Nigeria (one physical location)
**Document status:** Draft for stakeholder approval
**Version:** 0.1
**Date:** 20 November 2026
**Owners:** Product / Engineering (agent-assisted delivery)

> "Aurelia" is a placeholder brand used for the prototype and documentation. The legal hotel name, logo, domain, contact details and public copy must be confirmed before Phase 10. Replacing the brand must not require database changes.

---

## 1. Executive summary

Aurelia HMS is a production web application that runs the complete commercial and operational lifecycle of a single hotel: a public booking website, reservations, front desk, housekeeping, food and beverage, laundry, inventory, staff scheduling and attendance, payments, accounting, reporting and executive oversight.

The system replaces disconnected spreadsheets, paper folios and ad-hoc messaging with one permissioned source of truth. Every naira that is quoted, charged, collected, refunded or spent must be traceable to a guest, a stay, a department and the staff member responsible. Every room movement must be protected against double booking and every stock movement must be auditable.

The deliverable is not a demo. It must survive real operational load, enforce least-privilege access, pass automated security and concurrency tests, and deploy repeatably from GitHub to Vercel and Supabase.

## 2. Problem statement

The hotel currently risks:

- Double bookings and conflicting room assignments when reservations are handled manually.
- Revenue leakage where restaurant, bar and laundry charges never reach the guest folio.
- Unverified bank transfers being treated as settled cash.
- Stock disappearing without a movement trail or departmental accountability.
- Deposit and refund decisions living in someone's head rather than in policy.
- Slow month-end reporting because revenue, expenses and receivables are reconciled by hand.
- Weak auditability: staff actions, rate overrides and billing adjustments cannot be reconstructed.
- Guests having no self-service way to book, view their bill or settle a balance.

## 3. Goals and success measures

| Goal | Measure of success |
|---|---|
| Increase direct bookings | Public booking flow completes in ≤ 4 steps; deposit or full payment available; confirmation delivered in under 60 seconds. |
| Eliminate double booking | Zero overlapping active reservations for a room, proven by a database exclusion constraint and concurrency tests. |
| One guest bill | Accommodation, restaurant, bar, laundry and other charges appear on one folio; balance is never calculated in the browser. |
| Trustworthy payments | Every successful online payment verified server-side; every webhook processed exactly once; every manual transfer independently verified. |
| Operational visibility | Owner and manager dashboards refresh to within 60 seconds of an operational event; daily report downloadable as PDF/XLSX/CSV. |
| Stock accountability | 100% of stock changes have an attributable inventory movement; no direct quantity edits in the app. |
| Staff governance | Every privileged action records actor, time, entity and before/after values in an append-only audit log. |
| Production readiness | CI passes lint, typecheck, unit, database/RLS and E2E suites; migrations deploy through CI; rollback documented and rehearsed. |

## 4. Users and jobs to be done

| Persona | Primary job | Key pain today | Success looks like |
|---|---|---|---|
| **Owner** | Understand profitability, occupancy and risk without running the floor. | Reports are late and inconsistent. | One dashboard, daily digest, drill-down to source transactions. |
| **Manager** | Keep rooms, people, service and cash moving correctly. | Too many manual controls and blind spots. | Live operational board, approvals inbox, exception alerts. |
| **Receptionist** | Move guests from booking to room and settlement quickly. | Re-keying data; unclear balances. | One screen for arrival, folio, payment and check-out. |
| **Bartender** | Fulfil drink orders and protect stock. | Orders arrive verbally; stock is guessed. | Queue with status buttons; automatic stock deduction. |
| **Cook** | Prepare food in the right order, with recipe visibility. | Ticket confusion and missed modifications. | Kitchen display with timers, notes and ready notifications. |
| **Waiter** | Deliver the right order to the right room/table. | Orders get lost between kitchen and floor. | Ready queue with destination and one-tap delivery. |
| **Laundry attendant** | Process guest laundry and account for supplies. | Paper tags and untracked detergent. | Itemised ticket, status workflow, usage recording. |
| **Housekeeping** | Turn rooms around to a consistent standard. | Rooms released before inspection. | Assigned board; room unavailable until inspection passes. |
| **Accountant** | Reconcile collections, expenses and receivables. | Cash, POS, transfers and online payments do not reconcile. | Verified transaction ledger and exportable reports. |
| **Guest** | Book confidently and settle bills without calling. | No visibility of balance or receipt. | Self-service portal with secure lookup and Paystack payment. |

## 5. Scope

### 5.1 In scope (MVP)

- Public marketing site, room discovery, availability search and reservation checkout with optional account creation.
- Configurable deposit percentage, full-payment option, reservation hold expiry, cancellation and refund policy text.
- Guest accounts and secure lookup for unregistered guests.
- Room, floor, category, rate, amenity and image management.
- Reception, check-in, check-out, consolidated guest folio and balance settlement.
- Paystack online payments with server-side verification and idempotent webhooks; cash, POS and bank transfer recording with verification.
- Restaurant, kitchen, bar and waiter order workflows.
- Laundry request, processing and billing workflow.
- Housekeeping task assignment, cleaning and inspection workflow.
- Central inventory with movements, purchases, adjustments, recipes, low-stock alerts and valuation.
- Staff accounts, roles, departments, shifts, attendance, handover and performance indicators.
- Expenses, approvals, double-entry financial ledger and reconciliation views.
- Role dashboards, reports and PDF/XLSX/CSV downloads.
- In-app and transactional email notifications.
- Audit logging, RLS, backups, monitoring and CI/CD.
- Documentation, seed data, test suites and handover.

### 5.2 Out of scope for MVP

- Multiple hotel branches or a franchise/tenant console. The schema keeps a hotel identifier on core records to avoid a future rewrite, but no branch UI or branch switching is built.
- Channel-manager integrations (Booking.com, Expedia, Airbnb).
- Physical door-lock or key-card integration.
- Full POS terminal SDK integration; POS references and terminal metadata are recorded manually.
- Payroll, pension, tax filing and statutory remittance.
- Loyalty points, gift cards and dynamic yield pricing.
- Native mobile apps. The web app is responsive and installable-ready.
- Full double-entry statutory accounting with trial balance/tax filing. The ledger is operational and auditable, not a replacement for a licensed accountant.
- Offline-first operation.

## 6. Confirmed business decisions

1. **Single property.** One hotel, one location, one set of settings.
2. **Configurable deposits.** The manager sets a deposit percentage (default 30%). The guest may pay the required deposit or the full accommodation amount. Remaining balance is calculated by the server.
3. **Pay anytime.** Guests and staff can settle outstanding balances before arrival, at check-in, during the stay, at check-out and after check-out where an authorised outstanding balance exists.
4. **Optional guest accounts.** Unregistered guests can book and later look up their booking using a non-predictable reference plus a second verification factor (email or phone match + rate limiting).
5. **Restaurant and bar are first-class.** Both have menus, categories, orders, preparation, fulfilment, guest billing and stock deduction.
6. **Every stock change is a movement.** Stock is never silently overwritten.
7. **Financial records are immutable in normal operation.** Corrections use reversals, refunds and adjustments with audit evidence.
8. **Bank transfers are not cash.** A submitted transfer remains pending until an authorised verifier confirms it against the bank.
9. **Roles are never self-assigned.** Public registration can only create a guest account.
10. **Owner is read-only by default.** Sensitive writes require an explicitly granted permission and are audited.

## 7. Default operational settings (configurable)

| Setting | Default | Notes |
|---|---|---|
| Currency | NGN (₦) | Paystack settlement currency must match. |
| Hotel timezone | Africa/Lagos | Store UTC; display in hotel timezone. |
| Tax | 7.5% VAT | Confirm whether a separate state consumption tax applies. |
| Deposit | 30% of accommodation | Manager-configurable 0–100%. |
| Pending reservation hold | 30 minutes | Unpaid online reservations expire and release inventory. |
| Check-in | 14:00 | Early check-in is an operational exception, not a new rate. |
| Check-out | 12:00 | Late check-out may attract a charge. |
| Cancellation | Free until 48h before arrival | Policy text must be approved; charges post to the folio/ledger. |
| Refund approval | Manager or accountant | Refunds never delete the original payment. |
| Low-stock threshold | Per item | Alert when `current_stock <= reorder_level`. |
| Late grace | 10 minutes | Attendance marks late after grace. |

## 8. Core journeys

### 8.1 Direct guest booking
Search dates and occupancy → compare available rooms → select room → enter guest details → choose deposit or full payment → create reservation → pay via Paystack (or hold with an approved pay-later flow) → receive reference, receipt and arrival instructions → manage booking in guest portal.

### 8.2 Walk-in arrival
Receptionist searches/creates guest → checks availability → creates same-day reservation → confirms identity and rate → records payment → checks in → assigns room and key → activates folio.

### 8.3 Stay with incidentals
Guest orders food, drinks and laundry to the room → departmental staff fulfil orders → charges post automatically to the open folio → guest sees balance in portal and can pay at any time → housekeeping and front desk see updated state.

### 8.4 Departure
Receptionist reviews consolidated folio → applies authorised adjustments → collects balance or approves a documented outstanding balance → checks out → room becomes dirty → housekeeping cleans → supervisor inspects → room returns to available.

### 8.5 Transfer reconciliation
Receptionist records a transfer with reference, date and optional evidence → payment is pending verification → accountant/manager checks the bank statement → approve or reject with notes → folio balance updates only on approval → audit trail records both parties.

### 8.6 Owner review
Owner signs in read-only → reviews daily revenue, collections by method, departmental contribution, occupancy, receivables, expenses and stock exposure → drills into transactions → downloads a daily pack → flags an item to the manager (notification only; owner does not edit records by default).

## 9. Functional release acceptance criteria

The release is accepted only when all 30 criteria in the master specification are demonstrably met, including:

- Anonymous and registered booking, configurable deposits and post-checkout payments.
- Database-enforced no-double-booking; check-in/check-out and folio correctness.
- Secure Paystack verification and idempotent webhooks; cash, POS and verified transfers.
- Restaurant, bar, laundry, housekeeping and inventory workflows with automatic, non-duplicating deductions.
- Attendance, shifts and handovers with auditable adjustments.
- RLS and role permissions tested with authorised and unauthorised users.
- Auditable financial records; downloadable daily reports.
- Automated tests green; GitHub, Vercel and Supabase production deployments verified.
- Documentation and handover complete.

## 10. Risks and mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Paystack webhook replay or spoofing | Duplicate credit / revenue loss | HMAC SHA-512 signature, unique provider event ID, idempotent state transition, server verification before credit. |
| Double booking under concurrency | Guest displacement, reputational damage | PostgreSQL exclusion constraint on room stay ranges, transactional booking RPC, conflict retry UX. |
| Staff sharing accounts | Weak accountability | Unique staff accounts, session expiry, audit log, device/IP metadata, manager discipline. |
| Transfer fraud | Cash loss | Segregation of duties, mandatory bank confirmation, evidence is supporting only, approval thresholds. |
| Stock deduction repeated on retry | Inventory corruption | Immutable movement ledger with unique idempotency key per source event; deductions happen once on a guarded status transition. |
| Silent financial edits | Audit failure / fraud | Append-only ledger, reversal workflow, DB triggers blocking updates/deletes to posted records. |
| Report inconsistency | Bad decisions | All reports use server-side SQL views over the ledger with one definition per metric; no client-computed KPIs. |
| RLS misconfiguration | Data breach | Deny-by-default policies, helper functions, pgTAP tests per role, service-role only on server. |
| Single-owner bus factor | Operational failure | Documented runbooks, seeded backups, restore drills, handover sessions. |
| Paystack/email outage | Failed notifications/payments | Retry queues, clear pending states, manual fallback procedures, no false confirmation. |

## 11. Assumptions and constraints

- The hotel has reliable broadband; a brief outage is handled by documented manual fallback, not offline sync.
- Paystack merchant account, settlement bank account and webhook secret are available before Phase 6.
- Supabase plan supports daily backups and point-in-time recovery if required; this must be verified before production.
- Transactional email domain and sender identity are verified before Phase 10.
- Government-issued ID capture is optional and, where enabled, stored in a private bucket with short-lived signed URLs.
- The hotel operates a single currency (NGN). Multi-currency is out of scope, but amounts store currency explicitly.
- Legal review of privacy, cancellation and refund policies is required before launch.
- Branding assets and final room photography are supplied before public launch; placeholders are used in the prototype.

## 12. Approval gate

Phase 1 is approved when the owner/manager signs off on this PRD, the role matrix, workflows, architecture and the open-decisions list. Phase 2 (interactive prototype) is approved when the public site, guest portal and every staff dashboard have been reviewed on desktop and mobile, and the review notes in `docs/14-PROTOTYPE.md` are resolved or accepted.

Implementation of the production backend must not begin until prototype approval is recorded.
