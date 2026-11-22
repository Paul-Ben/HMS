# Aurelia HMS — Hotel Management System

A production-oriented hotel management, reservation, operations and financial system for a single hotel. Built with Next.js 16, TypeScript, Supabase (PostgreSQL, Auth, Storage, Realtime), Paystack and Vercel.

> **Phase status:** Phase 1 documentation is complete as a draft for approval; the Phase 2 interactive prototype is complete and awaiting G1 review. This is a prototype with sample data and local interaction state; authentication, persistence, payments and RLS are not active yet. See `docs/14-PROTOTYPE.md`.

## What the system covers

- Public hotel website, availability search, anonymous/registered booking, configurable deposits and online payment.
- Guest portal: stays, consolidated folio, payments, receipts, profile.
- Rooms, floors, categories, rates, housekeeping, maintenance and no-double-booking guarantees.
- Reception: check-in, check-out, consolidated guest billing, cash/POS/bank transfer and Paystack payments.
- Restaurant, kitchen, bar, waiter and laundry workflows with guest-folio posting and inventory deductions.
- Inventory, suppliers, purchases, recipes, movements, low-stock alerts and valuation.
- Staff, shifts, attendance and shift handover.
- Owner/manager/department dashboards, expenses, double-entry ledger, reports and exports.
- Role-based access, RLS, audit logs, backups and CI/CD.

## Quick start

```bash
npm install
npm run dev
```

Open `http://localhost:3000`. The dashboard prototype starts at `/dashboard/owner`; use the role switcher to move between roles. There is no sign-in in the prototype.

```bash
npm run lint
npm run typecheck
npm run build
```

## Documentation

| Document | Contents |
|---|---|
| [PRD](docs/01-PRD.md) | Product vision, personas, scope, risks, acceptance criteria |
| [FRS](docs/02-FUNCTIONAL-REQUIREMENTS.md) | Functional requirements with IDs and acceptance criteria |
| [NFR](docs/03-NON-FUNCTIONAL-REQUIREMENTS.md) | Security, performance, privacy, accessibility, operations |
| [RBAC](docs/04-RBAC-MATRIX.md) | Role permission matrix and permission catalogue |
| [Workflows](docs/05-WORKFLOWS.md) | Reservation, payment, folio, F&B, inventory, attendance, finance |
| [Architecture](docs/06-ARCHITECTURE.md) | System context, deployment, frontend/backend boundaries |
| [Database](docs/07-DATABASE.md) | ERDs, schema proposal, constraints, indexes, migrations, seed |
| [RLS](docs/08-RLS-MATRIX.md) | Policy matrix, storage policies, RLS tests |
| [UI inventory](docs/09-UI-INVENTORY.md) | Design system, routes, screens, states |
| [Roadmap](docs/10-ROADMAP.md) | Phases, gates, exit criteria |
| [Testing](docs/11-TESTING.md) | Test strategy, concurrency, webhooks, RLS, E2E, CI |
| [Deployment](docs/12-DEPLOYMENT.md) | Supabase/Vercel/GitHub CI/CD, secrets, backups, rollback |
| [Decisions](docs/13-DECISIONS.md) | ADRs and open business questions |
| [Prototype guide](docs/14-PROTOTYPE.md) | Review map, demo flows, limitations, approval checklist |
| [Tasks](TASKS.md) | Delivery tracker and acceptance evidence |

## Stack

Next.js 16 (App Router, Cache Components) · React 19 · TypeScript · Tailwind CSS v4 · shadcn/ui (Base UI) · Lucide · Recharts · TanStack Table · React Hook Form · Zod · Supabase · Paystack · Resend · GitHub Actions · Vercel.

## Status and safety

This repository is not yet connected to production credentials. Do not enter real guest data, payment keys or identity documents into the prototype. Secrets belong in environment variables, never in git. See `.env.example` and `docs/12-DEPLOYMENT.md`.

## License

Proprietary. All rights reserved until a license is agreed.
