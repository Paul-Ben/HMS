# Testing Strategy

**Status:** Draft for approval · **Version:** 0.2 · **Date:** 22 November 2026

## 1. Objectives

- Prove the money, inventory and room-allocation invariants under concurrency and retries.
- Prove authorisation at both the application and database layers.
- Prove the guest journey works without an account and with one.
- Prevent regressions in payment, folio and stock logic through automated CI.
- Produce evidence for the 30 acceptance criteria.

## 2. Tooling and layers

| Layer | Tool | Scope |
|---|---|---|
| Unit | Vitest | Pricing, deposit, tax, balance, date/nights, reference, permission mapping, formatting, Zod schemas. |
| Component | Vitest + React Testing Library + user-event | Forms, dialogs, status badges, tables, booking wizard, payment sheet. |
| Database | pgTAP (Supabase) | Constraints, state machines, RLS allow/deny, triggers, ledger balance, idempotency. |
| Integration | Vitest + Supabase local | Server actions/RPCs against a real local Postgres; webhook handler with signed fixtures. |
| E2E | Playwright | Public booking, guest portal, reception, kitchen/bar/laundry, housekeeping, manager, accountant, owner. |
| API/security | Playwright request + custom scripts | Direct anon/authenticated access attempts, storage URLs, origin/CSRF checks, rate limiting. |
| Accessibility | axe-core + manual keyboard | Public and dashboard key pages. |
| Performance | Lighthouse CI + k6 (or Artillery) | Public pages, availability search, booking, dashboard. |
| Static | ESLint, TypeScript, `npm audit`, secret scan | Every PR. |

## 3. Test data and environments

- **Fixtures:** deterministic seed UUIDs and dates; one hotel, 5 categories, 30 rooms, 10 staff, 5 guests, reservations across all statuses, paid/partial/unpaid folios, all payment methods, kitchen/bar/laundry orders, inventory at/above/below reorder, attendance exceptions, open handover.
- **Test clock:** injectable clock for expiry, late attendance and date-dependent reports; never rely on the machine date in unit tests.
- **Local Supabase:** `supabase start`; migrations + seed in CI; tests use the service role only for setup and the real anon/authenticated clients for assertions.
- **Isolation:** each test file uses a transaction or unique tenant-scoped fixture; no ordering dependency. Playwright uses a reset endpoint guarded to non-production.
- **Production:** no test data. Smoke tests only, read-only or test-mode Paystack.

## 4. Unit tests (minimum)

### Money and stay
- Nights across DST-free hotel timezone; same-day check-out invalid; one-night stay.
- Rate snapshot and room override; multi-night sum; tax per line rounding; discount cap; no negative totals.
- Deposit percentage 0/30/100; deposit after discount/tax; full payment; partial; overpayment policy.
- Folio balance with charges, payments, refunds, adjustments; post-stay balance; rounding half-up.
- Currency formatting NGN; kobo conversion.

### Reservations
- Allowed state transitions; invalid transitions rejected.
- Hold expiry boundary; expired cannot confirm; late payment exception.
- Cancellation policy charge; no-show fee; release on cancel.
- Reference uniqueness/non-predictability.
- Permission resolution: union of roles, owner read-only, deactivated staff, department scope.

### Orders, inventory, attendance
- Allowed order transitions; stock deduction event mapping (kitchen accepted→preparing, bar ready→delivered, laundry received→processing).
- Recipe multiplication in base units; insufficient stock; wastage reversal.
- Weighted average cost and valuation.
- Low-stock alert crossing/re-arm.
- Late/early minutes; overnight shift; duplicate clock-in/out.
- Handover transitions and lock after acknowledgement.

## 5. Database and concurrency tests

1. **Double booking:** two parallel `create_reservation` calls for the last room/date; exactly one success, one 409; one hold row.
2. **Modify race:** two staff modify the same reservation into conflicting rooms; one commits.
3. **Hold release:** cancel/expire/checkout releases hold in the same transaction; a new booking succeeds immediately.
4. **Payment idempotency:** same webhook event twice → one successful payment, one ledger journal, one receipt.
5. **Amount tampering:** webhook amount differs from expected → no credit, exception row.
6. **Stock idempotency:** repeated `transition_service_order` to preparing/ready/delivered creates one movement set.
7. **Partial failure:** any line failure in a multi-line deduction rolls back the status change.
8. **Ledger balance:** unbalanced journal rejected; posted line update/delete rejected.
9. **Folio guard:** charge to closed-paid folio rejected; post-stay payment allowed only on closed-with-balance.
10. **Attendance:** second open record blocked; clock-out before clock-in rejected.
11. **RLS:** every table × role allow/deny; guest cross-tenant; deactivated staff; submitter ≠ verifier; housekeeping can't read contacts; kitchen can't read payments; owner cannot write without grant.
12. **Storage:** guest cannot read another guest's receipt/evidence; signed URL expiry.

Current remote pgTAP evidence: `supabase/tests/rls.sql` passes 32 assertions, `supabase/tests/storage.sql` passes 15 assertions, and `supabase/tests/concurrency.sql` passes 14 assertions for contested-room exclusion, bill-item/payment/stock replay, overpayment rejection and negative-stock override. Migrations `0001`–`0017` were also replayed from scratch on a temporary Supabase project and all three suites passed there. Local pgTAP execution requires Docker/Podman; remote verification uses `npx supabase db query --remote --yes --file supabase/tests/<suite>.sql`.

## 6. Integration tests

- Server action create reservation reprices and rejects client-total mismatch.
- Paystack init records pending payment with unique reference before redirect.
- Webhook handler: valid signature, invalid signature, duplicate, replay, amount mismatch, unknown reference, late payment for expired reservation.
- Cash/POS payment and receipt sequence; concurrent receipt number allocation.
- Transfer submit/verify/reject; cannot self-verify; rejection preserves folio.
- Refund partial/full; cap enforcement; ledger reversal; provider call failure leaves state retryable.
- Housekeeping checkout integration; room not sellable until inspection.
- Email outbox retry and status; no duplicate sends on retry.
- Report query totals equal ledger/movement fixtures.

## 7. E2E acceptance flows

| ID | Flow |
|---|---|
| E2E-01 | Anonymous guest searches, books with deposit, pays (Paystack test), receives confirmation, looks up booking, pays balance. |
| E2E-02 | Registered guest books, views stay/folio/payments/receipt, updates profile, requests cancellation. |
| E2E-03 | Receptionist checks in arrival with outstanding balance, records cash/POS, checks out, prints folio/receipt. |
| E2E-04 | Transfer submission → accountant approve/reject → balances update, submitter notified. |
| E2E-05 | Restaurant room-service order → kitchen status → waiter delivery → folio charge → stock deduction. |
| E2E-06 | Bar order → stock deduction at delivery → folio charge. |
| E2E-07 | Laundry request → processing → ready → delivered → charge and supply usage. |
| E2E-08 | Checkout creates cleaning task → attendant cleans → supervisor inspects → room available. |
| E2E-09 | Manager configures deposit and room rate; changes do not alter history. |
| E2E-10 | Staff clock in/out, late exception, manager adjustment with reason, shift handover acknowledgement. |
| E2E-11 | Accountant records/approves expense, ledger and reports update; refund approved with audit. |
| E2E-12 | Owner views read-only dashboard, downloads daily PDF/XLSX/CSV, cannot edit. |
| E2E-13 | Unauthorised role direct-URL access is denied; RLS blocks direct API calls. |
| E2E-14 | Duplicate webhook replay has no side effects; late payment goes to exception queue. |

## 8. Security tests

- IDOR: change IDs in URLs/API bodies; all denied across guests/staff scopes.
- Role escalation: self-assign owner/manager; grant permissions; edit `user_roles` directly.
- XSS: guest names, notes, special requests, menu copy, content pages; CSP blocks inline script.
- CSRF: cross-origin POST to server actions and route handlers.
- Upload abuse: MIME mismatch, oversized file, path traversal, executable content.
- Rate limiting: login, lookup, booking, payment initiation, webhook.
- Webhook forgery/replay, amount/currency mismatch, unknown reference.
- CSV formula injection in exports (`=`, `+`, `-`, `@` prefix).
- Secrets scan; ensure no service-role/Paystack secret in client bundle.
- Prompt/HTML injection in generated PDFs and emails.

## 9. Accessibility and visual checks

- Playwright + axe on `/`, `/rooms`, `/book`, `/account`, `/dashboard/manager`, `/dashboard/receptionist`.
- Keyboard-only booking, check-in and payment flows.
- Dialog focus management, table navigation, chart alternatives.
- Mobile viewport snapshots at 360/390/768/1024.
- Reduced motion and forced-colours smoke check.

## 10. Performance checks

- Lighthouse CI budgets: performance ≥ 90 public, accessibility ≥ 95, best practices ≥ 95, SEO ≥ 95.
- Availability search p95 with 100 rooms / 365-day window.
- Dashboard p95 with 100k reservation/payment rows; verify indexes with EXPLAIN.
- Report 30-day generation ≤ 10s; larger exports asynchronous.
- Concurrent booking load: 50 simultaneous attempts for one room → exactly one success.

## 11. CI gates

Every pull request:

1. `npm ci`
2. `npm run lint`
3. `npm run typecheck`
4. `npm run test` (unit/component)
5. `supabase db lint` / migration apply on ephemeral DB
6. `npm run test:db` (pgTAP)
7. `npm run build`
8. Playwright smoke suite
9. Secret/dependency scan

`develop`: full integration + E2E. `main`: full suite + production migration plan approval + Vercel production verification. Nightly: full E2E, RLS suite, performance smoke, backup restore check (non-prod).

## 12. Release acceptance evidence

For each of the 30 master acceptance criteria, record: test ID, environment, date, build SHA, pass/fail, screenshot or log link, reviewer. No criterion is marked complete by manual inspection alone where an automated test is feasible.
