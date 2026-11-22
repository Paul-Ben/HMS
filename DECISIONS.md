# Decisions

The decision log — accepted ADRs and the 30 open business questions — lives in [`docs/13-DECISIONS.md`](docs/13-DECISIONS.md).

## Snapshot

- Next.js 16 App Router + TypeScript on Vercel.
- Supabase-native PostgreSQL with SQL migrations, RLS and RPCs; no ORM.
- Role-based permissions enforced by RLS and server checks; owner read-only by default.
- Money stored as `numeric(14,2)`; NGN only for MVP; kobo at the Paystack boundary.
- Double booking prevented by a PostgreSQL exclusion constraint on room holds.
- One folio per stay; departmental bills roll up; derived balances.
- Double-entry operational ledger for collections, revenue, receivables, refunds and expenses.
- Paystack webhook signature verification and idempotent event processing.
- Append-only inventory movements with exactly-once order deductions.
- Guest accounts optional; anonymous booking requires secure lookup with a second factor.
- Single property with `hotel_id` scope, no branch UI.

Open questions that need stakeholder input include tax treatment, deposit basis, cancellation/refund thresholds, ID retention, shift/handover cash policy, inventory valuation, Supabase plan/backups, email/domain, and final brand/legal content. See the table in `docs/13-DECISIONS.md` before Phase 3.
