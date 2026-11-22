# Delivery Tracker

**Last updated:** 22 November 2026
**Rules:** A task is complete only with working logic, persistence, authorisation, validation and tests. Statuses: Not Started · In Progress · Under Review · Testing · Completed · Blocked.

## Phase summary

| Phase | Status | Notes |
|---|---|---|
| 1. Requirements and analysis | Completed (draft for approval) | Docs 01–14 produced; G0 pending stakeholder sign-off. |
| 2. Interactive prototype | Complete · pending G1 | Public, guest and all role dashboards implemented; lint, typecheck and build pass. |
| 3. Database and backend foundation | Under Review (G2 evidence complete) | Migrations `0001`–`0017` replayed cleanly on a fresh project; RLS, storage and concurrency suites green; stakeholder G2 approval pending. |
| 4–12 | Not Started | Gated by prototype approval (G1) and remaining credentials. |

## Phase 1 — Requirements

| Task | Status | Evidence |
|---|---|---|
| PRD (vision, personas, scope, risks, acceptance) | Completed | `docs/01-PRD.md` |
| Functional requirements with IDs | Completed | `docs/02-FUNCTIONAL-REQUIREMENTS.md` |
| Non-functional requirements | Completed | `docs/03-NON-FUNCTIONAL-REQUIREMENTS.md` |
| Role and permission matrix | Completed | `docs/04-RBAC-MATRIX.md` |
| Business workflows and state machines | Completed | `docs/05-WORKFLOWS.md` |
| System architecture | Completed | `docs/06-ARCHITECTURE.md` |
| ERD, schema, indexes, migration plan | Completed | `docs/07-DATABASE.md` |
| RLS policy matrix | Completed | `docs/08-RLS-MATRIX.md` |
| UI page/component inventory | Completed | `docs/09-UI-INVENTORY.md` |
| Roadmap and gates | Completed | `docs/10-ROADMAP.md` |
| Test strategy | Completed | `docs/11-TESTING.md` |
| Deployment strategy | Completed | `docs/12-DEPLOYMENT.md` |
| Decisions and open questions | Completed | `docs/13-DECISIONS.md` |
| Stakeholder sign-off (G0) | Blocked | Awaiting owner/manager review of open questions. |

## Phase 2 — Prototype

| Task | Status | Evidence |
|---|---|---|
| Design tokens, typography and base layout | Completed | `app/globals.css`, `app/layout.tsx` |
| Public site shell, header, footer | Completed | `components/site/*` |
| Home page | Completed | `app/(public)/page.tsx` |
| Rooms listing and detail | Completed | `app/(public)/rooms/*` |
| Booking wizard with deposit/full choice | Completed | `app/(public)/book/*` |
| Dining and contact pages | Completed | `app/(public)/dining/*`, `app/(public)/contact/*` |
| Guest portal | Completed | `app/account/*` |
| Dashboard shell and role switcher | Completed | `components/dashboard/dashboard-shell.tsx`, `components/dashboard/dashboard-router.tsx` |
| Owner dashboard | Completed | `components/dashboard/pages/owner-dashboard.tsx` |
| Manager dashboard | Completed | `components/dashboard/pages/manager-dashboard.tsx` |
| Receptionist dashboard and flows | Completed | `components/dashboard/pages/reception-dashboard.tsx` |
| Housekeeping dashboard | Completed | `components/dashboard/pages/housekeeping-dashboard.tsx` |
| Laundry dashboard | Completed | `components/dashboard/pages/laundry-dashboard.tsx` |
| Kitchen dashboard | Completed | `components/dashboard/pages/kitchen-dashboard.tsx` |
| Bar dashboard | Completed | `components/dashboard/pages/bar-dashboard.tsx` |
| Waiter dashboard | Completed | `components/dashboard/pages/waiter-dashboard.tsx` |
| Accountant dashboard | Completed | `components/dashboard/pages/accounts-dashboard.tsx` |
| Inventory view | Completed | `components/dashboard/pages/inventory-dashboard.tsx` |
| Lint/build verification | Completed | `npm run lint`, `npm run typecheck`, `npm run build` |
| Prototype review and G1 | Blocked | Awaiting stakeholder review. |

## Phase 3 — Database and backend foundation

| Task | Dependencies | Status |
|---|---|---|
| Create Supabase dev project, install CLI, link | G1 | Completed |
| Extensions, enums, identity/hotel schema | G1 | Completed |
| Rooms and housekeeping schema | Identity | Completed |
| Guests, reservations, holds, exclusion constraint | Rooms | Completed (provisional) |
| Billing, payments, ledger schema | Identity + reservations | Completed (provisional) |
| F&B, laundry, inventory schema | Billing | Completed (provisional) |
| Staff, attendance, handover schema | Identity | Completed (provisional) |
| Views, RPCs, triggers, guards | Schema | Completed (`0013`–`0016` applied; synthetic operational smoke passed) |
| Seed roles, permissions, settings, catalogs | Identity | Completed (provisional) |
| RLS policies, staff-permission hardening and pgTAP suite | Schema + roles | Completed (32 assertions passing) |
| Storage buckets and policies | Identity | Completed (`0017`; 15 assertions passing) |
| Concurrency and idempotency tests | Holds, payments, stock | Completed (14 assertions passing) |

## Phase 4 — Application foundation

| Task | Dependencies | Status |
|---|---|---|
| Supabase SSR client and session refresh | Phase 3 | Not Started |
| Auth pages, reset, staff invitations | Phase 3 | Not Started |
| `requirePermission` and route guards | Auth | Not Started |
| Design system integration and dashboard shell | Prototype approval | Not Started |
| Error/loading/empty patterns, health endpoint | Foundation | Not Started |
| Logging and error monitoring | Foundation | Not Started |

## Phase 5 — Hotel core

| Task | Dependencies | Status |
|---|---|---|
| Staff CRUD and role assignment | Phase 4 | Not Started |
| Floors, categories, rooms, rates, images | Phase 4 | Not Started |
| Room status grid and housekeeping | Rooms | Not Started |
| Guest profiles, duplicate detection, merge | Phase 4 | Not Started |
| Reservation create/modify/cancel/search | Holds RPC | Not Started |
| Check-in and check-out | Reservation + folio | Not Started |
| Maintenance and room release workflow | Rooms + housekeeping | Not Started |

## Phase 6 — Billing and payments

| Task | Dependencies | Status |
|---|---|---|
| Consolidated folio API/UI | Phase 5 | Not Started |
| Charge posting and adjustments | Folio | Not Started |
| Paystack init/verify/webhook/receipts | Folio + ledger | Not Started |
| Cash, POS, bank transfer | Folio | Not Started |
| Transfer verification and segregation | Manual payments | Not Started |
| Refunds and reversals | Payments + ledger | Not Started |
| Guest portal and secure lookup | Folio | Not Started |
| Post-stay balances | Folio | Not Started |
| Ledger reconciliation views | All payment sources | Not Started |

## Phase 7 — Departments and inventory

| Task | Dependencies | Status |
|---|---|---|
| Menus, recipes, dining tables | Phase 3 | Not Started |
| Restaurant orders and kitchen board | Menus + folio | Not Started |
| Bar orders and stock deduction | Menus + inventory | Not Started |
| Waiter delivery | Orders | Not Started |
| Laundry services/orders/status | Folio + inventory | Not Started |
| Inventory items, locations, purchases | Phase 3 | Not Started |
| Movements, adjustments, transfers, valuation | Inventory | Not Started |
| Automatic deductions and alerts | Orders + inventory | Not Started |

## Phase 8 — Staff operations

| Task | Dependencies | Status |
|---|---|---|
| Shift templates and assignments | Phase 5 | Not Started |
| Clock-in/out and attendance | Shifts | Not Started |
| Manager adjustments | Attendance | Not Started |
| Shift handover and acknowledgement | Staff + payments | Not Started |
| Attendance/performance reports | Attendance + orders | Not Started |

## Phase 9 — Accounting, analytics, reports

| Task | Dependencies | Status |
|---|---|---|
| Expenses and approvals | Ledger | Not Started |
| Ledger posting for all sources | Payments, expenses | Not Started |
| Owner/manager/department dashboards | Ledger + operations | Not Started |
| Daily operational/financial reports | Dashboards | Not Started |
| Inventory and staff reports | Inventory + attendance | Not Started |
| PDF/XLSX/CSV exports | Reports | Not Started |
| Scheduled daily summaries | Email | Not Started |

## Phase 10 — Public site completion

| Task | Dependencies | Status |
|---|---|---|
| All public pages and legal copy | Brand/legal input | Not Started |
| Content management | Auth | Not Started |
| SEO, sitemap, OG images | Public pages | Not Started |
| Email templates and notifications | Phase 6/8 | Not Started |
| Real photography and copy | Owner assets | Not Started |
| Accessibility and Lighthouse pass | Public pages | Not Started |

## Phase 11 — Testing and security

| Task | Dependencies | Status |
|---|---|---|
| Unit/component coverage targets | All features | Not Started |
| pgTAP RLS/constraint suite | Phase 3 | In Progress (RLS 32, storage 15, concurrency 14 green; full constraint matrix pending) |
| E2E acceptance flows | All features | Not Started |
| Payment replay/tamper tests | Phase 6 | Not Started |
| Concurrency tests | Holds, stock, receipts | In Progress (contested room, payments, bill items and stock idempotency passing) |
| Accessibility audit | Phase 10 | Not Started |
| Performance/load tests | Phase 9 | Not Started |
| Secret/dependency scans | CI | Not Started |

## Phase 12 — Deployment and handover

| Task | Dependencies | Status |
|---|---|---|
| GitHub repo, branches, protection | G1 | Not Started |
| Vercel project and environments | GitHub | Not Started |
| Supabase production project and migrations | G2 | Not Started |
| Paystack live and webhook | G3 | Not Started |
| Email domain | Phase 10 | Not Started |
| Custom domain and HTTPS | Vercel | Not Started |
| Backups and restore drill | Production | Not Started |
| Monitoring and alerts | Production | Not Started |
| Runbooks, training, handover | All | Not Started |

## Acceptance criteria tracker

| # | Criterion | Test evidence | Status |
|---|---|---|---|
| 1 | Anonymous reservations | E2E-01 | Not Started |
| 2 | Registered guest management | E2E-02 | Not Started |
| 3 | Configurable deposits | Unit + E2E-01/09 | Not Started |
| 4 | Pay outstanding bills anytime | E2E-01/03 | Not Started |
| 5 | No double booking | DB concurrency test | Completed (one hold; second attempt rejected) |
| 6 | Check-in/out | E2E-03 | Not Started |
| 7 | Manage rooms/floors/staff | E2E-09 | Not Started |
| 8 | Owner executive reports | E2E-12 | Not Started |
| 9 | Secure Paystack verification | Integration + webhook tests | Not Started |
| 10 | Cash/POS/transfer | E2E-03/04 | Not Started |
| 11 | Transfer verification | E2E-04 | Not Started |
| 12 | Consolidated guest bills | E2E-03 | Not Started |
| 13 | Restaurant orders | E2E-05 | Not Started |
| 14 | Bar orders | E2E-06 | Not Started |
| 15 | Laundry orders | E2E-07 | Not Started |
| 16 | Inventory deductions | Idempotency tests | In Progress (stock movement replay passing) |
| 17 | Housekeeping workflow | E2E-08 | Not Started |
| 18 | Staff attendance | E2E-10 | Not Started |
| 19 | Shift scheduling | E2E-10 | Not Started |
| 20 | Shift handovers | E2E-10 | Not Started |
| 21 | Auditable financial records | Ledger/RLS tests | Not Started |
| 22 | Downloadable daily reports | E2E-12 | Not Started |
| 23 | Staff permissions enforced | RLS matrix suite | Completed (32 assertions passing) |
| 24 | RLS tested | pgTAP suite | Completed (32 assertions) |
| 25 | Automated tests pass | CI | In Progress (remote pgTAP green; local/CI Docker run pending) |
| 26 | GitHub source available | Repo verification | Not Started |
| 27 | Vercel production works | Production smoke | Not Started |
| 28 | Supabase production works | Production smoke | Not Started |
| 29 | Migrations via CI/CD | Deployment log | Not Started |
| 30 | Documentation and handover | G6 sign-off | Not Started |
