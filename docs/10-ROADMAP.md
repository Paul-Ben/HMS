# Development Roadmap

**Status:** Draft for approval · **Version:** 0.1 · **Date:** 20 November 2026
**Approach:** phase-gated delivery. A phase is complete only when its exit criteria are evidenced in `TASKS.md`.

## 0. Gates

| Gate | Decision | Evidence |
|---|---|---|
| G0 | Requirements and architecture approved | This documentation set + owner/manager sign-off |
| G1 | Prototype approved | `docs/14-PROTOTYPE.md` review notes resolved |
| G2 | Backend and RLS approved | Seed database, passing pgTAP suite, schema review |
| G3 | Payments approved | Paystack test transactions, webhook replay tests, reconciliation |
| G4 | UAT approved | End-to-end hotel scenario passes with seeded staff accounts |
| G5 | Production launch | Deployment checklist signed, backups verified, monitoring live |
| G6 | Handover | Runbooks, credentials handover, training completed |

## Phase 1 — Requirements and analysis (current)

**Deliverables:** PRD, FRS, NFR, role/permission matrix, workflows, architecture, ERD/schema, RLS matrix, UI inventory, roadmap, test strategy, deployment strategy, open decisions.

**Exit criteria:** Documents reviewed; no unresolved blocker in the role matrix or booking/payment semantics; G0 recorded.

## Phase 2 — Interactive prototype

**Deliverables:** Next.js prototype with public site, booking wizard, guest portal and all staff dashboards; realistic sample data; responsive layouts; clickable critical workflows.

**Dependencies:** Phase 1 decisions for deposit display, brand placeholders, role navigation.

**Exit criteria:** Stakeholders review every dashboard on desktop and mobile; feedback collected; G1 recorded. No production backend work starts before G1.

## Phase 3 — Database and backend foundation

**Deliverables:**

- Supabase projects (dev + prod), CLI setup, extension and enum migrations.
- Identity, hotel, staff, roles/permissions, RLS helpers.
- Rooms, guests, reservations, holds and exclusion constraint.
- Billing, payments, receipts, ledger schema.
- F&B, laundry, inventory, attendance, finance schema.
- Views, RPCs, triggers, seed data (non-demo and dev demo).
- Storage buckets and policies.
- pgTAP suites for constraints and RLS.

**Exit criteria:** Migrations apply cleanly from scratch; seed succeeds; concurrency test proves one winner for a contested room; RLS allow/deny suite green; G2 recorded.

## Phase 4 — Application foundation

**Deliverables:** Supabase SSR client, session refresh, auth pages, password reset, invitations, protected route groups, `requirePermission`, design system integration, dashboard shell, error/empty/loading patterns, `/api/health`, logging.

**Exit criteria:** Sign-in/out and session refresh work; unauthorised routes return 403; staff invite flow tested in dev; CI lint/typecheck/build green.

## Phase 5 — Hotel core

**Deliverables:** Staff management UI, floors/rooms/categories/rates, room status grid, guest profiles and merge, reservation calendar/list, create/modify/cancel, check-in/out, housekeeping board and inspection, maintenance.

**Exit criteria:** Complete seeded scenario: booking → arrival → check-in → cleaning task → check-out → clean → sellable; no double booking under parallel requests.

## Phase 6 — Guest billing and payments

**Deliverables:** Consolidated folio UI/API, charges and adjustments, Paystack init/verify/webhook, receipts, cash/POS, transfer submission/verification, refunds, ledger posting, guest portal, secure lookup, post-stay balances.

**Exit criteria:** Deposit and full payment paths pass; duplicate webhook is a no-op; transfer cannot be self-verified; refunds reverse correctly; receipt PDFs match folio totals; owner/accountant reports reconcile.

## Phase 7 — Departmental operations

**Deliverables:** Restaurant menus/orders, kitchen display, waiter delivery, bar orders and stock, laundry services/orders, inventory items/purchases/movements/adjustments/recipes/alerts/valuation, automatic deductions.

**Exit criteria:** Order placed → prepared → delivered → charged to folio → stock deducted exactly once. Concurrent retries do not duplicate stock or charges. Low-stock alert fires once.

## Phase 8 — Staff operations

**Deliverables:** Shift templates, assignment calendar, clock-in/out, attendance exceptions, manager adjustments, handover checklist/snapshot/acknowledgement, attendance and performance reports.

**Exit criteria:** Overnight shift handled correctly; one open attendance; handover locks after acknowledgement; cash variance explanation enforced.

## Phase 9 — Accounting, analytics and reports

**Deliverables:** Expense categories/expenses/approvals, chart of accounts, ledger posting for all sources, owner/manager/department dashboards, daily operational/financial reports, staff performance, inventory reports, PDF/XLSX/CSV exports, date filters.

**Exit criteria:** Reports reconcile to ledger and movement data; exports authorised and branded; metric definitions documented; light-load performance targets met.

## Phase 10 — Public website completion

**Deliverables:** All public pages and policies, content management, gallery, menu display, contact form, SEO, real photography and copy, guest account polish, email templates, notifications.

**Exit criteria:** Public acceptance checklist passes; Lighthouse targets met; legal pages approved; anonymous booking and lookup work with rate limiting; G4 recorded for the public/guest scope.

## Phase 11 — Testing and security hardening

**Deliverables:** Complete unit/integration/E2E/pgTAP suites, payment and concurrency fault tests, accessibility audit, performance tests, dependency/secret scans, penetration-test checklist, fixed critical/high issues.

**Exit criteria:** CI green; no critical/high findings open; RLS suite covers all roles; webhook replay and amount-tampering tests pass; backups restore successfully.

## Phase 12 — Deployment and handover

**Deliverables:** GitHub repository and branch protection, Vercel production + previews, Supabase production migrations/functions, Paystack live configuration, email domain, custom domain/HTTPS, monitoring/alerts, backup policy, runbooks, admin guide, staff quick-reference, training, final acceptance evidence.

**Exit criteria:** All 30 master acceptance criteria verified against production; G5 and G6 signed; owner/manager can operate a day without developer intervention.

## Critical path and dependencies

```mermaid
flowchart LR
  P1[1 Requirements] --> P2[2 Prototype]
  P2 --> P3[3 Database]
  P3 --> P4[4 App foundation]
  P4 --> P5[5 Hotel core]
  P5 --> P6[6 Billing/payments]
  P6 --> P7[7 Departments]
  P7 --> P8[8 Staff ops]
  P8 --> P9[9 Accounting/reports]
  P9 --> P10[10 Public site]
  P10 --> P11[11 Testing/security]
  P11 --> P12[12 Deploy/handover]
```

- Payments (Phase 6) depend on the ledger schema (Phase 3) and reservation/folio flows (Phase 5).
- Departmental stock (Phase 7) depends on inventory schema and order state machine (Phase 3), and on folio posting (Phase 6).
- Owner analytics (Phase 9) depends on ledger and stock movements, not on UI-only aggregation.
- Public site completion (Phase 10) depends on room availability and booking APIs (Phase 5/6).
- Deployment (Phase 12) needs Paystack live keys, email domain, final domain and legal copy.

## Working agreement

- Trunk-based with short-lived `feature/*` and `fix/*` branches; `develop` integration, `main` production.
- Every task has acceptance criteria, tests and evidence. "Frontend exists" is never complete.
- Schema changes are migrations; no dashboard edits in production.
- Weekly demo of working software; blockers escalated immediately.
- Open decisions must be resolved before the phase that depends on them; see `docs/13-DECISIONS.md`.
