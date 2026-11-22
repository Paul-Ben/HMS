# Deployment, CI/CD and Operations

**Status:** Draft for approval · **Version:** 0.1 · **Date:** 20 November 2026

## 1. Environments

| Environment | Branch | Next.js | Supabase | Payments | Data |
|---|---|---|---|---|---|
| Local | feature/fix | `next dev` | Local Supabase (`supabase start`) | Paystack test | Seeds + dev fixtures |
| Preview | pull request | Vercel preview | Staging project (or Supabase branch) | Paystack test | Anonymised seed |
| Staging/UAT | `develop` | Vercel preview/production alias | Staging project | Paystack test | UAT seed |
| Production | `main` | Vercel production | Production project | Paystack live | Real |

Never share production database credentials with previews. Never run destructive test scripts against staging or production.

## 2. Required configuration

### 2.1 Application environment variables

```bash
# Public (safe for the browser)
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
NEXT_PUBLIC_APP_URL=https://app.example.com
NEXT_PUBLIC_HOTEL_NAME=Aurelia Hotel & Suites
NEXT_PUBLIC_PAYSTACK_PUBLIC_KEY=

# Server-only
SUPABASE_SERVICE_ROLE_KEY=
PAYSTACK_SECRET_KEY=
PAYSTACK_WEBHOOK_TOLERANCE_SECONDS=300
RESEND_API_KEY=
EMAIL_FROM="Aurelia Hotel <reservations@example.com>"
EMAIL_REPLY_TO=reservations@example.com
CRON_SECRET=
SENTRY_DSN=
LOG_LEVEL=info
REPORT_SIGNING_SECRET=
```

Rules:
- `NEXT_PUBLIC_*` values are public by definition. Never put secrets there.
- Vercel: separate values for Preview, Development and Production. Production is a protected environment.
- Supabase: secrets configured with `supabase secrets set` for Edge Functions; never committed.
- Rotate keys after any suspected exposure; update Vercel and Supabase, redeploy.

### 2.2 Paystack

1. Create/verify merchant account; complete compliance.
2. Development: test keys; production: live keys.
3. Webhook URL: `https://<production-domain>/api/webhooks/paystack` (and staging equivalent).
4. Subscribe to `charge.success`, `refund.processed`/`refund.failed` (as supported), transfer events if used.
5. Confirm Paystack signs with HMAC SHA-512 of the raw body using the secret key.
6. Test with test cards and the Paystack CLI/dashboard event replay.
7. Settlement bank account and currency (NGN) verified by the owner.

### 2.3 Email

- Verify the sending domain (SPF, DKIM, DMARC) with Resend.
- Use separate subdomains for transactional and marketing if marketing is added.
- Templates: booking confirmation, payment receipt, payment rejected, arrival reminder, departure folio, low stock, shift handover, password reset, staff invite.
- Bounce/complaint handling and retry policy documented.

### 2.4 Supabase

- Two projects: `aurelia-hms-dev`, `aurelia-hms-prod` (plus a preview project or branching if the plan supports it).
- Enable RLS; verify exposed schemas; disable unnecessary extensions.
- Auth: email/password enabled, email confirmation per policy, secure site URL, allowed redirect URLs, SMTP provider configured for production.
- Storage: `public-media` (public), `guest-evidence`, `receipts`, `report-exports`, `staff-documents` (private).
- Backups: daily automated backups; PITR if the plan supports it and the risk assessment requires it.
- Cron: expiry job every 5 minutes; daily close snapshot; low-stock sweep; email retry.
- Network restrictions / SSL enforcement for database access where available.

## 3. GitHub

- Repository: private, `main` default; branches `develop`, `feature/*`, `fix/*`.
- Protect `main` and `develop`: require PR, green checks, at least one review, no force push, linear history preferred.
- GitHub Environments: `development`, `staging`, `production` with required reviewers and environment-scoped secrets.
- Files: `README.md`, `CHANGELOG.md`, `TASKS.md`, `ARCHITECTURE.md`, `DECISIONS.md`, `.env.example`, `docs/`.
- No secrets in git history. Enable push protection and secret scanning.

Suggested labels: `phase/1` … `phase/12`, `type/feature`, `type/bug`, `type/security`, `area/payments`, `area/database`, `priority/critical`.

## 4. CI/CD pipeline

### 4.1 Pull request checks

```yaml
# .github/workflows/ci.yml (outline)
name: ci
on:
  pull_request:
    branches: [develop, main]
jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 22, cache: npm }
      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck
      - run: npm run test
      - run: npm run build
  database:
    runs-on: ubuntu-latest
    services: {}
    steps:
      - uses: actions/checkout@v4
      - uses: supabase/setup-cli@v1
      - run: supabase start
      - run: supabase db reset
      - run: supabase test db
      - run: supabase db lint
  e2e:
    needs: [quality, database]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 22, cache: npm }
      - run: npm ci
      - run: npx playwright install --with-deps chromium
      - run: npm run test:e2e -- --project=chromium
        env:
          NEXT_PUBLIC_SUPABASE_URL: ${{ secrets.E2E_SUPABASE_URL }}
          NEXT_PUBLIC_SUPABASE_ANON_KEY: ${{ secrets.E2E_SUPABASE_ANON_KEY }}
```

### 4.2 Migration deployment (production)

```yaml
# .github/workflows/deploy-supabase.yml (outline)
name: deploy-supabase
on:
  push:
    branches: [main]
    paths: ["supabase/**"]
  workflow_dispatch:
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      - uses: supabase/setup-cli@v1
      - run: supabase link --project-ref ${{ secrets.SUPABASE_PROJECT_REF }}
        env: { SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}, SUPABASE_DB_PASSWORD: ${{ secrets.SUPABASE_DB_PASSWORD }} }
      - run: supabase db push --include-all
      - run: supabase functions deploy --project-ref ${{ secrets.SUPABASE_PROJECT_REF }}
        env: { SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }} }
```

**Rules**
- Migrations are reviewed and applied to staging first.
- Destructive migrations require explicit approval, a verified backup and a rollback plan.
- `supabase db push` is production-only from `main`; previews never migrate production.
- Vercel deploys independently via Git integration. Database deployment and frontend deployment are separate; the release checklist verifies both.

### 4.3 Vercel

1. Import the GitHub repository.
2. Framework preset: Next.js; Node 22; build `npm run build`; install `npm ci`.
3. Production branch `main`; preview deployments for all PRs.
4. Environment variables per environment; mark sensitive values as encrypted.
5. Custom domain + automatic HTTPS; redirect `www` decision recorded.
6. Enable deployment protection for previews if guests should not see unreleased work.
7. Configure Vercel Cron for jobs that are not run in Supabase (with `CRON_SECRET`).
8. Verify `/api/health`, security headers, and that no secret is present in client bundles.

### 4.4 Vercel login workaround

- Vercel CLI authentication is not required for application development, Supabase migrations or local verification.
- Continue with `npx supabase`, GitHub auth and GitHub Actions checks; deployment remains a Phase 12 activity.
- When deployment is required, import the GitHub repository into the Vercel dashboard using the existing GitHub login. Git integration builds and deploys without a Vercel CLI token in this environment.
- If CLI deployment is needed later, install/authenticate with `npm i -g vercel` and `vercel login`, or use `npx vercel login`.
- Store any Vercel token only in GitHub Actions secrets or the local CLI credential store; never paste it into chat or `.env.local`.

## 5. Release procedure

1. Merge approved PR to `develop`; full CI + E2E green.
2. Deploy migrations to staging; run smoke + UAT flows.
3. Tag release candidate; update CHANGELOG and TASKS.
4. Approve production environment; deploy migrations first (backward-compatible), then application.
5. Run production smoke: sign-in, availability, booking test (Paystack test mode not allowed in production unless sandbox), dashboard, receipt, report.
6. Verify webhook delivery and queue health.
7. Announce to staff; update runbook.

## 6. Backups and disaster recovery

| Asset | Protection | Recovery |
|---|---|---|
| Postgres | Daily automated backup; PITR if plan supports; pre-migration manual snapshot | Restore to new project, point app to restored project after validation. |
| Storage | Supabase storage backups per plan; periodic export of critical private files | Restore objects and re-link paths; verify signed URLs. |
| Migrations | Git history + migration table | Replay forward; forward-fix for failures. |
| Secrets | Password manager + environment records | Rotate and redeploy. |
| Reports | Regenerable from source data | Re-run export. |

**Restore drill:** quarterly, restore a backup into a non-production project, run verification queries (counts, ledger balance, recent reservations) and record evidence. RPO/RTO targets must be agreed with the owner; do not assume PITR is included in the selected plan.

## 7. Monitoring and alerting

- Error monitoring (Sentry or equivalent) for server/client exceptions with release SHA.
- Uptime check on `/`, `/api/health`, `/availability` and the webhook endpoint.
- Alerts: 5xx rate, webhook signature failures, unprocessed gateway events > 5 min, expiry job failure, ledger imbalance, negative stock attempt, payment exception created, email failure rate, report job failure, backup failure.
- Dashboards: bookings/hour, payment success rate, average check-in time, occupancy, low stock, pending verifications.
- Log retention per plan; no PII in application logs.

## 8. Rollback

- **Frontend:** promote the previous Vercel deployment; verify health and build SHA.
- **Database:** forward-fix migration preferred. If a migration is destructive and breaks the app, restore the pre-migration snapshot to a new instance, validate, then repoint environment variables after approval.
- **Payments:** disable Paystack online initiation via feature flag while keeping manual methods available; webhook continues to record events for reconciliation.
- **Email/realtime:** degrade gracefully with in-app notifications and visible status.

## 9. Launch checklist

- [ ] G0–G4 approvals recorded.
- [ ] Production Supabase project created, RLS enabled, seed applied.
- [ ] All migrations applied; `supabase test db` green on production snapshot.
- [ ] Vercel production deployment green; domain and HTTPS verified.
- [ ] Paystack live keys, webhook URL, signature verification and test transaction verified.
- [ ] Email domain verified; test receipt/confirmation delivered.
- [ ] Storage buckets/private policies verified.
- [ ] Backups enabled and restore drill completed.
- [ ] Monitoring/alerts to on-call.
- [ ] Staff accounts invited; owner read-only confirmed; role matrix verified.
- [ ] Legal pages, rates, taxes, cancellation/refund policy approved.
- [ ] Daily report PDF/XLSX/CSV verified.
- [ ] Runbook and training delivered; G5/G6 signed.

## 10. Current deployment blockers

- GitHub repository and owner approval for creation/push.
- Supabase project URLs, anon/service keys and access token.
- Paystack merchant test/live keys and webhook configuration.
- Transactional email provider account and verified domain.
- Final domain, hotel legal details and brand assets.
- Confirmation of backup plan/PITR on the selected Supabase plan.
