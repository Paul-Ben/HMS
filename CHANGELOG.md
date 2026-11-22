# Changelog

All notable changes to this project are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow Semantic Versioning.

## [Unreleased]

### Added
- Phase 1 documentation: PRD, FRS, NFR, RBAC matrix, business workflows, architecture, database/ERD, RLS matrix, UI inventory, roadmap, testing and deployment strategy, decisions/open questions.
- Phase 2 interactive prototype scaffold: Next.js 16, TypeScript, Tailwind v4, shadcn/ui, Recharts, TanStack Table, RHF/Zod.
- Complete public site, booking wizard, guest portal and ten dashboard personas with local sample-data workflows.
- Dashboard interactions for check-in/out, payment recording and verification, expense approvals, service-order progression, stock deduction and stock adjustment.
- Delivery tracker and acceptance criteria map.
- Supabase dev project, linked CLI setup, and initial identity/hotel plus rooms/housekeeping migrations.
- Guests, reservations, room holds with overlap exclusion constraint, cancellation policies and rate plans schema.
- Folios, bills, payments, refunds, receipts, exceptions, number sequences and double-entry financial ledger schema.
- Combined F&B, laundry and inventory schema with service-order transitions, stock movement stock sync and low-stock alerts.
- Staff shifts, assignments, attendance, handovers and append-only activity log schema.
- Read-only reporting views with security invoker enabled for rooms, folios, reservations, occupancy, revenue, stock and staff metrics.
- Baseline dev seed for hotel, departments, 10 roles, 85 permissions, role grants, settings, accounts, room catalog and shifts.
- Role/permission RLS helpers, grants and row policies across identity, rooms, reservations, billing, F&B, laundry, inventory and staff tables.
- GitHub Actions CI for lint, typecheck, build and local Supabase migration validation.
- pgTAP RLS suite with 32 assertions for anon, guest, staff, owner, duty segregation and service-only access.
- `npm run test:db` script and CI database test step.

### Changed
- Initial project setup.
- Phase 2 prototype marked complete and pending stakeholder review; sample-data counts reconciled with the seed data.
- Permission-based RLS checks now require an active staff profile so guest-role permission keys cannot grant staff-level row access.

### Known limitations
- Prototype uses mocked data and local state; no authentication, persistence, Paystack, email or exports.
- Open business questions in `docs/13-DECISIONS.md` require stakeholder decisions.

## [0.1.0] - 2026-11-20
- Project inception and specification.
