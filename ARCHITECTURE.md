# Architecture

The full architecture is documented in [`docs/06-ARCHITECTURE.md`](docs/06-ARCHITECTURE.md), with the database in [`docs/07-DATABASE.md`](docs/07-DATABASE.md) and security policies in [`docs/08-RLS-MATRIX.md`](docs/08-RLS-MATRIX.md).

## Summary

- **Frontend:** Next.js 16 App Router on Vercel. Server Components for reads, Server Actions/Route Handlers for mutations, shadcn/ui + Tailwind for the design system, Recharts for analytics, TanStack Table for data grids.
- **Backend:** Supabase Auth, PostgreSQL, Storage, Realtime and Edge Functions. RLS on every exposed table. Business invariants enforced by SQL constraints and RPCs; no ORM.
- **Payments:** Paystack with server-side verification, HMAC SHA-512 webhooks, idempotent event processing and an exception queue. Cash, POS and verified bank transfers are first-class methods.
- **Billing:** one master folio per stay; departmental bills roll up; double-entry ledger records cash movements, revenue recognition, receivables, refunds and expenses.
- **Inventory:** append-only movement ledger; exactly-once automatic deductions from order transitions; weighted-average valuation; low-stock alerts.
- **Rooms:** PostgreSQL exclusion constraint on active room holds prevents double booking under concurrency.
- **Security:** deny-by-default RLS, permission checks in server code, private uploads, append-only audit logs, secret isolation.
- **CI/CD:** GitHub Actions validates lint/typecheck/tests/migrations; Supabase migrations deploy from `main`; Vercel deploys independently from the same commit.

## Key boundaries

1. The browser never receives the service-role key, Paystack secret, database credentials or other guests' data.
2. The client never calculates authoritative prices, balances, deposits, stock or permissions.
3. Payment success is never accepted from a frontend callback; only signed webhooks/server verification count.
4. Posted financial records are never updated or deleted; corrections are reversals and adjustments.
5. Room availability is decided by the database, not by a UI check.
