# Architecture Decisions and Open Questions

**Status:** Draft for approval · **Version:** 0.1 · **Date:** 20 November 2026

## Part A — Accepted decisions (proposed)

### ADR-001: Next.js 16 App Router with TypeScript
**Decision:** Use the current stable Next.js App Router, React Server Components, Server Actions, route handlers, Tailwind v4 and shadcn/ui.
**Why:** Server-first rendering keeps secrets and business logic off the client; App Router provides streaming dashboards and straightforward Vercel deployment.
**Consequences:** New Next.js 16 conventions (Cache Components, `proxy.ts`, async `params`) must be followed; server/client boundaries need discipline.

### ADR-002: Supabase-native backend, no ORM
**Decision:** Use Supabase Postgres with SQL migrations, generated TypeScript types, RLS and RPCs; no Prisma/Drizzle in the MVP.
**Why:** Native RLS, constraints and security-definer functions are the core of correctness; an ORM would duplicate schema authority and complicate migrations.
**Consequences:** SQL review and generated types are mandatory; queries live in feature query modules.

### ADR-003: RBAC + RLS + server checks
**Decision:** Role permissions stored in tables, enforced by RLS and repeated in server actions; owner read-only by default.
**Why:** Defence in depth; UI hiding is not security.
**Consequences:** Every new table needs a policy and tests; permission keys are seeded and versioned.

### ADR-004: Money as `numeric(14,2)`
**Decision:** Store money as exact decimal; convert to kobo only at the Paystack boundary; round half-up to 2 decimals at line/total boundaries.
**Why:** Avoid floating-point drift in folios and reconciliation.
**Consequences:** Formatting helpers; no arithmetic on floats; tests for rounding.

### ADR-005: Database exclusion constraint for room holds
**Decision:** Maintain `room_allocation_holds` with `btree_gist` exclusion on `(room_id, daterange)`, created/released in the same transaction as the reservation.
**Why:** UI checks race; the database is the only reliable arbiter.
**Consequences:** 409 conflict mapping; hold release on cancel/expire/checkout; concurrency tests mandatory.

### ADR-006: Folio-centric billing
**Decision:** One master folio per stay (or walk-in) with departmental bills; all charges and payments attach to the folio; totals are derived server-side.
**Why:** The guest sees one bill; departmental revenue remains separable.
**Consequences:** Departmental orders must resolve an active folio; closed-folio guards; receipt/ledger links.

### ADR-007: Double-entry operational ledger
**Decision:** Record a balanced journal for every payment, charge, refund, adjustment and approved expense, linked to source records.
**Why:** Cash collected ≠ revenue recognised; auditability and reporting require debits/credits.
**Consequences:** Chart of accounts seed, balanced-journal trigger, no deletions, accountant reconciliation UI.

### ADR-008: Paystack webhook + server verification
**Decision:** Treat the signed webhook and server-side verify as authoritative; never trust the browser callback; idempotent event table.
**Why:** Prevent forged/failed payments and duplicate credits.
**Consequences:** Raw-body signature verification, unique event/payment references, exception queue, tests.

### ADR-009: Append-only inventory movement ledger
**Decision:** Stock changes only through `inventory_movements`; current stock is derived/maintained from movements; no direct edits.
**Why:** Accountability for shrinkage and recipe usage.
**Consequences:** Movement idempotency keys, valuation logic, low-stock alerts, no negative stock by default.

### ADR-010: Exactly-once order stock deductions
**Decision:** Deduct at the department-specific transition inside the same transaction as the status change, guarded by `stock_deducted_at` and movement idempotency keys.
**Why:** Retries and Realtime events must not double-deduct.
**Consequences:** Cancellation after deduction uses wastage/reversal; transition functions are idempotent.

### ADR-011: Server-generated reports
**Decision:** All reports and exports are authorised server-side; PDF/XLSX/CSV generated with a shared report definition layer.
**Why:** Prevent data leakage and inconsistent metrics; no client-side totals.
**Consequences:** Report views/functions first; export jobs for large ranges.

### ADR-012: Transactional email via Resend (configurable)
**Decision:** Use Resend behind an email adapter and outbox.
**Why:** Reliable delivery, simple domain verification, swappable provider.
**Consequences:** Templates in code, retries, no PII in logs, email preference table.

### ADR-013: Single property, hotel-scoped schema
**Decision:** Seed one hotel and carry `hotel_id` on operational roots; build no branch UI.
**Why:** Meet the current business while avoiding a painful multi-property rewrite.
**Consequences:** All queries include hotel scope; a future branch feature can add properties without renaming tables.

### ADR-014: Guest accounts optional
**Decision:** Anonymous booking is first-class; auth is optional; secure lookup uses non-predictable reference + email/phone verification and rate limiting.
**Why:** Reduce booking friction.
**Consequences:** Guest linking/merge; no anonymous direct table access; all public operations through server endpoints.

### ADR-015: Owner read-only by default
**Decision:** Owner selects are broad; writes require explicit grants. Owner cannot grant permissions.
**Why:** Executive oversight without accidental operational changes.
**Consequences:** Owner UI labels read-only; audit of any grant; tests.

### ADR-016: Cache Components and streaming dashboards
**Decision:** Keep Next.js 16 Cache Components/Partial Prefetching enabled; public content cached and tagged; authenticated dashboards stream.
**Why:** Fast public pages and instant navigation without caching guest-specific data.
**Consequences:** Suspense boundaries around runtime data; no PII in cached shared content; revalidate on mutations.

## Part B — Open questions requiring stakeholder decisions

| # | Question | Recommendation / default | Owner | Needed by |
|---|---|---|---|---|
| Q1 | Final hotel name, logo, domain, address, phone, email and social handles. | Use "Aurelia" placeholder; make content configurable. | Owner | Phase 2 review |
| Q2 | Is VAT 7.5% the only tax, or is a Lagos State consumption tax/service charge also required? How is it displayed? | Store tax lines; default 7.5% VAT plus a configurable service charge of 0%. Confirm with accountant. | Owner / Accountant | Phase 3 |
| Q3 | Deposit computed before or after tax and discount? | After discount and tax on accommodation. | Owner / Accountant | Phase 3 |
| Q4 | Default deposit %, hold duration, cancellation window, no-show fee, refund policy. | 30%, 30 min, free until 48h, first night no-show, refunds per policy. | Owner | Phase 2/3 |
| Q5 | Are deposits refundable? What are the approval thresholds for refunds and write-offs? | Policy-based; manager/accountant approval; threshold ₦100,000 requires owner visibility. | Owner | Phase 6 |
| Q6 | Must a reservation be fully paid before check-in, or can an approved balance be carried? | Allow check-in with a documented balance only by manager approval. | Owner / Manager | Phase 5 |
| Q7 | Is ID capture mandatory at check-in? Which document types and retention period? | Optional capture; store private; retention 24 months unless legal requires longer. | Owner / Legal | Phase 3 |
| Q8 | Which staff roles can combine? (e.g. receptionist + accountant) | Allow multiple roles; enforce segregation for transfer verification/refunds. | Manager | Phase 4 |
| Q9 | Should housekeeping require supervisor inspection before a room is sellable? | Yes, for departure cleans; optional for stayover. | Manager | Phase 5 |
| Q10 | Can staff edit/cancel orders after payment? Who approves voids/refunds? | Manager approval after preparing; full audit. | Manager | Phase 7 |
| Q11 | Is a service charge or gratuity distributed to staff? | Out of scope for MVP; record as revenue only if confirmed. | Owner / Accountant | Phase 9 |
| Q12 | Cash drawer model: per cashier, per shift, or per front desk? | Per shift handover with counted cash and variance explanation. | Manager / Accountant | Phase 8 |
| Q13 | Do kitchen recipes exist for every menu item, or can stock be deducted manually initially? | Support both; recipes preferred; manual authorised usage with reason. | Manager / Chef | Phase 7 |
| Q14 | Bar stock deduction at delivery or at payment? | At `ready → delivered` (stock leaves the bar). | Manager / Bartender | Phase 7 |
| Q15 | Should low stock also block ordering, or only alert? | Alert by default; optionally 86 items manually; no hard block except recipe shortage. | Manager | Phase 7 |
| Q16 | Inventory valuation method: moving weighted average or FIFO? | Moving weighted average for MVP. | Accountant | Phase 3 |
| Q17 | Payment methods accepted at the property and their settlement accounts. | Paystack, cash, POS, bank transfer. | Owner / Accountant | Phase 6 |
| Q18 | Paystack account country/currency and settlement timing. | NGN; confirm account is live and compliant. | Owner | Phase 6 |
| Q19 | Email provider/sender domain and whether SMS/WhatsApp is required at launch. | Resend email; SMS/WhatsApp post-MVP. | Owner | Phase 10 |
| Q20 | Should guests see food/bar charges in real time? | Yes for room charges; walk-in receipts only. | Owner / Manager | Phase 6 |
| Q21 | Receipt/folio numbering format and legal requirements. | `AUR-YYYY-NNNNNN`, `RCP-YYYY-NNNNNN`. | Accountant | Phase 3 |
| Q22 | Night audit / daily close time and who performs it. | 02:00 Africa/Lagos; accountant or manager on duty. | Accountant | Phase 9 |
| Q23 | Data retention for reservations, folios, CCTV (if integrated) and marketing consent. | Finance/audit ≥ 7 years; guest marketing purge after 24 months of inactivity. | Owner / Legal | Phase 3 |
| Q24 | Public content workflow: manager publishes directly or requires owner review? | Manager can draft/publish; owner can unpublish. | Owner | Phase 10 |
| Q25 | Do we need multi-currency or international cards? | NGN only for MVP; Paystack handles card FX as configured. | Owner | Phase 6 |
| Q26 | Are OTA/channel integrations required at launch? | Out of scope; record source manually. | Owner | Post-MVP |
| Q27 | Which Supabase plan (backup/PITR, compute) and budget? | Verify backup/PITR before G5. | Owner | Phase 12 |
| Q28 | Who is the on-call/operations owner after handover? | Named manager + developer retainer. | Owner | Phase 12 |
| Q29 | Should the owner be able to make any writes? If so, which? | None by default; explicit grants only. | Owner | Phase 2 |
| Q30 | Brand photography and room images licensing. | Owner supplies licensed assets; prototype uses placeholders. | Owner | Phase 10 |

## Part C — Decision log process

- Any change to an accepted ADR requires a new ADR entry with date, context, decision and consequences; do not rewrite history.
- Open questions block the dependent phase; defaults are used in the prototype only and must be labelled.
- Record stakeholder approval (name, date, channel) at the bottom of this file when resolved.

## Part D — Phase 3 provisional implementation assumptions

These are implementation defaults for local/dev work only. They are not stakeholder decisions and must be reconfirmed at G0/G1.

- Supabase dev project: `aurelia-hms-dev`, region `eu-west-1`, free plan, DB password stored only in `.env.local`.
- Enum values are provisional: `employment_status` = active/on_leave/suspended/terminated; `permission_scope` = self/department/assigned/all; `room_operational_status` = available/occupied/blocked/maintenance; `room_housekeeping_status` = clean/dirty/cleaning/inspection; task status/priority values follow the documented workflow.
- `housekeeping_tasks.reservation_id` now references `reservations(id)`; the reservations migration has been applied.
- Reservation/payment/folio enums were added in `0005`/`0006` because `0002` was already applied; all enum values remain provisional.
- Reservation references use the format `AUR-YYYY-NNNNNN`; folios, payments and receipts use `FOL`/`PAY`/`RCP` prefixes via `public.allocate_reference`.
- Guest email/phone are indexed for dedupe but not unique because family-shared contacts are unresolved.
- Booking, payment, ledger and views/RPCs remain schema-only until the dedicated RPC/guard migrations; do not run live booking or payment flows yet.
- F&B and laundry/inventory were combined into one migration because recipes and bar products reference inventory items.
- Service order references use `SORD-YYYY-NNNNNN` and laundry references use `LND-YYYY-NNNNNN`; these differ from the workflow example and are provisional.
- Inventory stock is constrained non-negative; authorised negative-stock overrides are not supported until the conflict is resolved.
- Service order, laundry order, status history and inventory movement tables have basic transition/append-only guards; full RPCs and stock deduction rules are still deferred.
- Staff ops migration is numbered `0008` after the combined F&B/laundry/inventory `0007`; status enums and inferred columns (`early_minutes`, `acknowledged_by`, handover `shift_id`) are provisional.
- Acknowledged handovers are immutable; addenda are not modelled until the addenda design is confirmed.
- Reporting views use `security_invoker = true`; `v_notification_feed` is deferred because no notifications table exists yet.
- Materialized daily revenue/occupancy views and report metadata are deferred until refresh scheduling is decided.
- Baseline seed is dev-only: hotel code `AUR`, 10 canonical roles, 85 permission keys, `STANDARD_48H` cancellation policy, 25 prototype rooms, chart-of-account codes and shift times are provisional.
- `owner.write` and `roles.manage` grants are intentionally omitted; owner remains read-only and role-management approval flow is unresolved.
- Raw gateway payload expiry is set by trigger to 180 days and still needs the retention job decision.
- `0011_rls.sql` is applied: helper functions, grants and per-table policies are active; RLS is not forced so migration-owned seed operations continue to work.
- Broad `select` grant to `anon` and `select, insert, update, delete` grant to `authenticated` are intentional; access is restricted by RLS policies rather than table-level revokes.
- `number_sequences` and `payment_gateway_events` intentionally have no policies and remain service-role-only.
- Owner read access is implemented through `owner` role checks; owner remains read-only because `owner.write` is not seeded.
- `roles.manage` policies exist but remain unusable until the owner-approved role-management flow is decided.
- `supabase/tests/rls.sql` passes 32 pgTAP assertions; RLS policy validation is complete.
- `0012_rls_staff_permission_fix.sql` requires an active staff profile for permission-based RLS checks; guest-role permission keys no longer grant staff-level row access.
