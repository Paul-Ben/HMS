# Interactive Prototype Guide (Phase 2)

**Status:** Complete · pending G1 review · **Version:** 0.1 · **Date:** 20 November 2026
**Brand:** Aurelia Hotel & Suites (placeholder) · **Currency:** NGN · **Timezone:** Africa/Lagos

## 1. Purpose

This prototype exists to align on visual direction, information architecture, role-specific dashboards and the shape of the critical workflows **before** production backend work. It uses realistic sample data and local interaction state. Nothing here is a production security or persistence implementation.

## 2. Run locally

```bash
npm install
npm run dev
```

Open `http://localhost:3000`. Recommended review widths: 1440px desktop, 768px tablet, 390px mobile. Use a modern browser.

## 3. Review map

| Area | Route | What to review |
|---|---|---|
| Public home | `/` | Brand, hero, availability search, featured rooms, facilities, dining, services, gallery, footer. |
| Rooms | `/rooms` | Category filters, room cards, rates, availability cues. |
| Room detail | `/rooms/deluxe-king` | Gallery, amenities, rate, booking CTA. |
| Booking wizard | `/book` | Dates/guests, room selection, deposit vs full payment, guest form validation, confirmation. |
| Dining | `/dining` | Restaurant/bar positioning, menus, hours, service style. |
| Contact | `/contact` | Contact details, form layout, map placeholder. |
| Guest portal | `/account` | Upcoming stay, folio, charges, payment history, pay dialog, receipts. |
| Owner | `/dashboard/owner` | Executive KPIs, revenue trend, department/payment mix, occupancy, staff and stock alerts. |
| Manager | `/dashboard/manager` | Room state, arrivals/departures, pending payments, duty staff, exceptions, live departments. |
| Receptionist | `/dashboard/receptionist` | Arrival/in-house/departure queues, check-in, payment recording, transfer verification. |
| Housekeeping | `/dashboard/housekeeping` | Dirty → cleaning → inspection → clean board, assignment, room grid. |
| Laundry | `/dashboard/laundry` | Request queue, item counts, status progression, delivery. |
| Kitchen | `/dashboard/kitchen` | Ticket board, accept/prep/ready transitions, modifiers, timers. |
| Bar | `/dashboard/bar` | Bar queue, create order, stock cues, status transitions. |
| Waiter | `/dashboard/waiter` | Ready orders, destination, delivery confirmation. |
| Accountant | `/dashboard/accountant` | Reconciliation, payment methods, pending verification, expenses, receivables. |
| Inventory | `/dashboard/inventory` | Stock levels, low-stock alerts, movements and valuation. |

A role switcher is available in the dashboard top bar so all dashboards can be reviewed quickly. The sidebar adapts to the current role.

## 4. Flows to exercise

1. **Booking:** Home → set dates/guests → check availability → choose a room → continue → choose 30% deposit or full payment → fill guest details → confirm. Observe server-style deposit/balance calculation in the summary (prototype logic is local but deterministic).
2. **Payment at reception:** Receptionist → Arrivals → open a guest → "Record payment" → choose Cash/POS/Transfer → submit. Try a transfer and observe the pending-verification state.
3. **Transfer verification:** Accountant or Manager → pending verification → approve/reject with notes. Note the submitter/verifier separation intent.
4. **Kitchen:** Kitchen → accept a pending ticket → start preparing → mark ready. Then open Waiter and deliver the same order; stock deduction is represented by a toast and the inventory state.
5. **Bar:** Bar → create a quick order to a room → advance the ticket → see stock deducted once on delivery.
6. **Housekeeping:** Receptionist → check out an in-house guest → Housekeeping sees a dirty room → start → complete → inspect → clean. Try rejecting an inspection.
7. **Laundry:** Laundry → advance a request → ready → delivered; observe the folio charge.
8. **Ownership and audit:** Owner dashboard is labelled read-only. Notice that destructive/financial actions expose a reason/approval intent rather than silently editing history.
9. **Mobile:** Repeat booking, check-in and kitchen flows at 390px.

## 5. Sample data

- Hotel: Aurelia Hotel & Suites, Victoria Island, Lagos.
- Dates: review week of 20–25 November 2026.
- 25 rooms, 5 categories, 10 role personas, 13 reservations (6 arriving, 7 in-house), 13 payments (10 completed, 3 pending; Paystack 5, bank transfer 3, cash 3, POS 2), 16 service orders (6 kitchen, 5 bar, 5 laundry), 4 housekeeping tasks, 12 inventory items, 4 expenses.
- All names, emails, phone numbers, references and amounts are fictional.

## 6. What is intentionally mocked

- Authentication and sessions (role switcher instead of sign-in).
- Persistence (browser state resets on refresh).
- Paystack (simulated redirect/confirmation; no money moves).
- Email/SMS (toasts and sample notifications).
- PDF/XLSX/CSV download actions (buttons show the intended artefact but files are not generated yet).
- File upload and evidence capture.
- RLS/database validation (final implementation enforces these server-side).
- Real-time updates (local state and simulated queues).
- Remaining legal/content pages, full settings, staff CRUD and report builders.

## 7. Approval checklist

Please review and respond to:

- [ ] Brand direction, typography, colour and photography style.
- [ ] Public homepage hierarchy and booking entry points.
- [ ] Room card/detail content and pricing presentation.
- [ ] Booking step order, deposit wording and payment choice.
- [ ] Guest portal scope and bill clarity.
- [ ] Sidebar navigation and role scoping for each dashboard.
- [ ] Owner metric set, definitions and read-only treatment.
- [ ] Manager actionability and exception visibility.
- [ ] Reception check-in/out and payment interactions.
- [ ] Kitchen/bar/waiter queue ergonomics at peak load.
- [ ] Housekeeping/laundry board clarity.
- [ ] Accountant reconciliation and pending-verification flow.
- [ ] Mobile usability.
- [ ] Any modules or screens missing before Phase 3.

Record decisions in `docs/13-DECISIONS.md`; prototype feedback can be added below with date and reviewer.

## 8. Feedback log

| Date | Reviewer | Screen/flow | Feedback | Decision |
|---|---|---|---|---|
|  |  |  |  |  |
