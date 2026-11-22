# Non-Functional Requirements (NFR)

**Status:** Draft for approval · **Version:** 0.1 · **Date:** 20 November 2026

These requirements apply to every module. Each is testable and will be verified in Phase 11 unless marked otherwise.

## 1. Availability and reliability

| ID | Requirement | Target / verification |
|---|---|---|
| NFR-AVL-01 | Production availability for booking and front-desk flows. | 99.9% monthly target; uptime monitor with alerting. |
| NFR-AVL-02 | A failed payment, webhook or email must never confirm a booking or credit a folio incorrectly. | Fault-injection tests; states remain pending; manual replay supported. |
| NFR-AVL-03 | The system must recover from a crashed request mid-transaction without partial writes. | All multi-table writes inside PostgreSQL transactions/RPCs. |
| NFR-AVL-04 | Backups and restore procedures are documented and tested before launch. | Restore drill evidence in `docs/12-DEPLOYMENT.md` appendix. |
| NFR-AVL-05 | Degraded mode: if Paystack is unavailable, staff can still operate cash/POS/transfer flows and mark online payment retryable. | Playwright/manual test with network blocked. |

## 2. Performance

| ID | Requirement | Target |
|---|---|---|
| NFR-PERF-01 | Public page LCP on a mid-range phone over 4G. | ≤ 2.5s (p75), Lighthouse ≥ 90 for performance/accessibility on key pages. |
| NFR-PERF-02 | Availability search response (server, 100 rooms, 365-day window). | p95 ≤ 800ms. |
| NFR-PERF-03 | Reservation creation transaction. | p95 ≤ 1.5s excluding payment redirect. |
| NFR-PERF-04 | Dashboard initial data (cached aggregates). | p95 ≤ 2s; refresh without full page reload. |
| NFR-PERF-05 | Report generation, 30-day range. | ≤ 10s synchronous; longer exports run as a job with download notification. |
| NFR-PERF-06 | Database queries must be indexed for all list and report filters. | No sequential scans over >10k rows on hot paths; EXPLAIN evidence for top 20 queries. |
| NFR-PERF-07 | Client bundle for public pages. | First-load JS ≤ 180kB gzipped per route where practical; charts lazy-loaded. |

## 3. Security

| ID | Requirement |
|---|---|
| NFR-SEC-01 | Supabase Auth for all identities; httpOnly, secure, sameSite cookies via the SSR client. |
| NFR-SEC-02 | Deny-by-default RLS on every table in exposed schemas. |
| NFR-SEC-03 | Authorisation enforced server-side for every mutation; UI hiding is not authorisation. |
| NFR-SEC-04 | Service-role and Paystack secret keys exist only in server environments; never `NEXT_PUBLIC_*`. |
| NFR-SEC-05 | All input validated with Zod at the server boundary; database constraints are the final authority. |
| NFR-SEC-06 | Paystack webhook signature verified with HMAC SHA-512 and raw body; events idempotent and replay-safe. |
| NFR-SEC-07 | Rate limiting on login, booking lookup, payment initiation, webhook, and public forms. |
| NFR-SEC-08 | Uploads restricted by MIME, size and extension; stored in private buckets; served through short-lived signed URLs. |
| NFR-SEC-09 | No secrets, tokens, full card data or identity documents in logs. |
| NFR-SEC-10 | Audit log append-only; financial posted records cannot be updated/deleted by application roles. |
| NFR-SEC-11 | Dependency and secret scanning in CI; critical vulnerabilities block release. |
| NFR-SEC-12 | CSRF-safe mutations (same-site cookies + origin checks for non-GET routes); no state change on GET. |
| NFR-SEC-13 | Guest users can read only their own guest, reservation, folio, payment and receipt records. |
| NFR-SEC-14 | Staff access is limited to role permissions and department scope; staff cannot self-assign roles. |
| NFR-SEC-15 | Security headers: CSP, HSTS, X-Content-Type-Options, Referrer-Policy, frame-ancestors. |

## 4. Privacy and compliance (NDPA)

| ID | Requirement |
|---|---|
| NFR-PRI-01 | Collect only data needed for the stay and legal obligations; mark optional fields. |
| NFR-PRI-02 | Publish privacy policy, lawful basis, retention periods and data-subject request contact. |
| NFR-PRI-03 | Guest data is never sold or shared except with processors required to deliver the service (Paystack, email). |
| NFR-PRI-04 | Identity documents stored encrypted at rest, access-logged, and deleted per retention policy. |
| NFR-PRI-05 | Export and deletion requests are executable by an authorised administrator with audit evidence. |
| NFR-PRI-06 | Audit/accounting records required by law are retained even if marketing consent is withdrawn. |
| NFR-PRI-07 | Email consent is separate from transactional messages. |
| NFR-PRI-08 | Data processing agreements are in place with Supabase, Vercel, Paystack and the email provider. |

## 5. Usability and accessibility

| ID | Requirement |
|---|---|
| NFR-UX-01 | WCAG 2.2 AA for public pages and staff dashboards: keyboard navigation, focus states, labels, contrast ≥ 4.5:1 for body text. |
| NFR-UX-02 | All critical workflows work at 360px width without horizontal scrolling. |
| NFR-UX-03 | Destructive actions require confirmation and, where financial, a reason. |
| NFR-UX-04 | Every list has loading, empty and error states. |
| NFR-UX-05 | Front-desk actions reachable in ≤ 3 interactions from the dashboard. |
| NFR-UX-06 | Status is never conveyed by colour alone; use label + icon. |
| NFR-UX-07 | Forms preserve entered data on validation failure. |
| NFR-UX-08 | Times displayed in hotel timezone with a clear label; money always with currency symbol. |

## 6. Compatibility

- Evergreen Chrome, Edge, Firefox and Safari (last two major versions).
- iOS Safari and Android Chrome, 360px–1440px.
- No IE support. Print stylesheet for receipts, folios and reports.
- Reduced-motion preference respected.

## 7. Observability and operations

| ID | Requirement |
|---|---|
| NFR-OBS-01 | Structured JSON logs with request ID, user ID (hashed where appropriate), route, duration, status; no PII payloads. |
| NFR-OBS-02 | Error monitoring with alert routing (Sentry or equivalent) on production and preview. |
| NFR-OBS-03 | Health endpoint for database connectivity and build version. |
| NFR-OBS-04 | Metrics: booking attempts/success, payment success/failure, webhook lag, double-booking conflicts, stock deduction failures, report duration. |
| NFR-OBS-05 | Failed background jobs (expiry, emails, webhook retries) are visible and replayable. |
| NFR-OBS-06 | Audit trail retention ≥ 7 years or as advised by counsel. |

## 8. Maintainability and quality

| ID | Requirement |
|---|---|
| NFR-MNT-01 | TypeScript strict mode; no `any` in application code without documented justification. |
| NFR-MNT-02 | Feature-modular structure; no cross-feature deep imports except through public module interfaces. |
| NFR-MNT-03 | All money and inventory calculations live in tested server-side functions. |
| NFR-MNT-04 | Database changes exclusively through versioned migrations; no dashboard-only schema edits in production. |
| NFR-MNT-05 | Every environment reproducible from documented setup; seed data deterministic. |
| NFR-MNT-06 | Minimum automated coverage: 80% statements for financial/booking logic; 100% of acceptance-critical E2E flows. |
| NFR-MNT-07 | Lint, typecheck, tests, migration lint and build must pass before merge to `develop` and `main`. |

## 9. Scalability

- Design for 100 rooms, 50 staff, 10k guests, 100k reservations, 1M ledger rows without redesign.
- Use pagination and indexed filters on all large lists.
- Reports use pre-aggregated views/materialised views refreshed on a schedule; owner dashboards query aggregates, not raw tables.
- Stateless Next.js instances; no in-memory business state.
- Background work is idempotent and safe to run concurrently.

## 10. Deployment and environment quality

- Separate Supabase projects for development and production; preview deployments use a dedicated preview project/branch where feasible.
- Production migrations require a reviewed pull request, green CI and environment approval.
- No destructive production migration without a tested backup and explicit approval.
- Vercel production promotion only from `main`; rollback via deployment promotion and database restore plan.
