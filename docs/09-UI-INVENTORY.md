# UI/UX Inventory and Design System

**Status:** Draft for approval · **Version:** 0.1 · **Date:** 20 November 2026

## 1. Visual direction

A quiet, contemporary African luxury hotel: deep navy, brass/gold, warm ivory, natural textures. Public pages are editorial and image-led; staff dashboards are calm, dense and fast. Gold is an accent, never the primary action colour on data screens. Status is conveyed by label + tone, not colour alone.

| Token | Value | Use |
|---|---|---|
| Navy 950 | `#081826` | Public hero overlay, sidebar, footer |
| Navy 900 | `#0C2237` | Headings, primary buttons |
| Navy 700 | `#1D3A55` | Secondary text on light |
| Gold 500 | `#B08A4F` | Accents, active nav, eyebrow labels |
| Gold 200 | `#E8D7B8` | Borders/highlights on dark |
| Ivory | `#F7F3EC` | Page background |
| Sand | `#ECE4D7` | Section bands, muted cards |
| Sage | `#2F6B4F` | Success/paid/clean |
| Amber | `#B7791F` | Warning/pending/low stock |
| Brick | `#B42318` | Danger/overdue/blocked |
| Slate | `#5D6B78` | Muted text |
| White | `#FFFFFF` | Cards, forms |

**Typography:** Playfair Display (display/editorial headings), Manrope (body/UI). Tabular numerals for money and metrics. Minimum body 16px public, 14px dense staff tables. **Radius:** 10–16px public cards, 8px controls, 12px dashboard cards. **Spacing:** 4px base; 24/32/48px section rhythm. **Shadows:** soft, low-opacity; borders preferred on data surfaces. **Motion:** 150–250ms, respect `prefers-reduced-motion`.

## 2. Reusable components

- **Public:** SiteHeader (transparent over hero, solid on scroll), MobileNav, SiteFooter, AvailabilitySearch, RoomCard, RoomGallery, RateSummary, BookingWizard, GuestLookup, TestimonialCarousel, GalleryGrid, SectionHeading, PolicyContent.
- **Dashboard shell:** DashboardSidebar (role-scoped, collapsible), TopBar (search, notifications, role/demo switcher, profile), PageHeader, KPI card, TrendsChart, StatusBadge, DataTable (TanStack), FilterBar, EmptyState, ErrorState, ConfirmDialog, PermissionGate, ActivityFeed, CommandSearch.
- **Workflow:** ArrivalCard, FolioSummary, ChargeList, PaymentDrawer, TransferVerificationDialog, RefundDialog, OrderTicket, KitchenBoard, BarQueue, DeliveryBoard, LaundryTicket, HousekeepingCard, RoomStatusGrid, ShiftClock, HandoverForm, InventoryMovementForm, StockAlert, ExpenseForm, ReportCard.
- **States:** skeleton, loading, empty ("No arrivals today"), error with retry, permission denied, offline/degraded banner, success toast.
- **Print:** receipt (80mm and A4), folio A4, daily report pack, PDF header/footer with property details.

## 3. Route inventory (final application)

### 3.1 Public and booking

| Route | Contents | Priority |
|---|---|---|
| `/` | Hero, availability search, featured rooms, story, facilities, dining, services, testimonials, gallery, CTA, contact, footer. | M |
| `/about` | Story, values, team, location. | M |
| `/rooms` | Category filters, rates, availability entry. | M |
| `/rooms/[slug]` | Gallery, description, amenities, occupancy, rate, availability search CTA. | M |
| `/availability` | Date/occupancy search results with filters and room cards. | M |
| `/book` | 3-step wizard: stay/room → guest details → payment choice → confirmation. | M |
| `/booking/[reference]` | Secure booking summary/lookup, status, balance, pay, cancel request. Requires second factor for anonymous access. | M |
| `/restaurant` | Story, menu categories, sample menu, hours. | M |
| `/bar` | Story, drinks, hours, signature serves. | M |
| `/services` | Laundry, transfers, spa, events, concierge. | M |
| `/gallery` | Filterable image gallery. | M |
| `/contact` | Form, map, contacts, hours. | M |
| `/faq` | Accordion FAQs. | M |
| `/privacy` | NDPA-aligned privacy policy. | M |
| `/terms` | Terms and conditions. | M |
| `/reservation-policy` | Deposit, cancellation, refund, no-show, check-in/out. | M |
| `/lookup` | Anonymous secure booking/bill lookup. | S |

### 3.2 Authentication and guest portal

| Route | Contents | Priority |
|---|---|---|
| `/sign-in`, `/register`, `/forgot-password`, `/reset-password` | Auth flows; register creates guest only. | M |
| `/account` | Overview: upcoming stay, balance, quick pay, notifications. | M |
| `/account/stays` | Upcoming/past/cancelled reservations. | M |
| `/account/stays/[reference]` | Stay detail, guests, room, status, actions. | M |
| `/account/folio` | Consolidated bill, charges by department, payments, balance. | M |
| `/account/payments` | Payment history, receipts, pay outstanding. | M |
| `/account/profile` | Personal details, security, communication preferences. | M |

### 3.3 Staff dashboards

| Route | Contents | Roles |
|---|---|---|
| `/dashboard/owner` | Revenue trend, department/method mix, expenses, net operating result, occupancy, reservations, guests, staff, attendance, performance, inventory, alerts, activity. | Owner (read-only) |
| `/dashboard/manager` | Room status, arrivals/departures, in-house, pending payments/transfers, receipts, balances, duty staff, exceptions, orders, low stock, activity. | Manager |
| `/dashboard/receptionist` | Arrivals, in-house, departures, walk-in, payments, transfer submissions, receipts, handover. | Receptionist, Manager |
| `/dashboard/reservations` | Calendar/list, create/modify/cancel, room assignment, availability. | Receptionist, Manager |
| `/dashboard/front-desk` | Check-in/out, folio, payments, guest search. | Receptionist, Manager |
| `/dashboard/housekeeping` | Board by status, room grid, assignment, inspection, maintenance reports, history. | Housekeeping supervisor/Manager |
| `/dashboard/laundry` | Request queue, item counts, processing, ready, delivery, usage. | Laundry, Manager |
| `/dashboard/kitchen` | Ticket board, accept/prepare/ready, recipe/ingredients, timers. | Cook, Manager |
| `/dashboard/bar` | Order queue, create order, status, stock, wastage. | Bartender, Manager |
| `/dashboard/waiter` | Ready orders, assigned tables/rooms, delivered confirmation, history. | Waiter, Manager |
| `/dashboard/accountant` | Verified transactions, reconciliation, pending verification, expenses, refunds, receivables, reports. | Accountant, Manager |
| `/dashboard/inventory` | Items, stock, purchases, movements, adjustments, alerts, valuation, recipes. | Manager, Accountant (read/cost), authorised departments (limited) |
| `/dashboard/staff` | Staff list, invitations, departments, roles, schedules, attendance, performance. | Manager |
| `/dashboard/staff/[id]` | Profile, shifts, attendance, activity, permissions. | Manager |
| `/dashboard/reports` | Report catalogue, filters, exports, scheduled reports. | Owner, Manager, Accountant (scope) |
| `/dashboard/settings` | Hotel settings, booking/deposit policy, tax, receipt prefix, public content, roles. | Manager; owner approval for policy |
| `/dashboard/audit` | Immutable audit search and export. | Manager, Accountant (finance scope), Owner |
| `/dashboard/notifications` | Notification feed and preferences. | All staff, guest equivalent in account |

## 4. Dashboard layout

- Fixed 264px navy sidebar on ≥1024px; sheet navigation on mobile; content max-width 1600px.
- Sidebar: brand, role label, grouped nav, "on duty" indicator, user card.
- Top bar: page title/breadcrumb, global search (Ctrl/Cmd+K), notification bell, role/demo switcher in prototype, profile menu.
- Page header: title, context ("Friday, 20 November 2026 · 34 rooms occupied"), primary action, secondary actions.
- KPI grid: 2 columns mobile, 4 desktop; label, value, delta, footnote and period. Never show a metric without its definition/period.
- Boards: horizontal columns on desktop, stacked tabs on mobile. Cards have a clear next action and ownership.
- Tables: sticky header, sort, filter, pagination, row action menu, bulk actions only where safe. Financial rows link to source.
- Dialogs: right-side sheet for payment/check-in on desktop; full-screen on mobile. Destructive confirmation includes the exact amount/entity.
- Colour semantics: navy/gold for brand, sage for success, amber for pending, brick for danger, slate for neutral.
- Empty states propose the next action ("Create a walk-in reservation").
- Degraded banner when realtime/paystack/email is unavailable; business actions that remain safe stay enabled.

## 5. Key screen behaviour

### Booking wizard
Stepper (Stay → Details → Payment → Confirmed). Sticky price summary. Server-calculated nights, taxes, deposit and balance. Clear deposit-vs-full choice with radio cards. Validation inline; preserve values; explicit cancellation policy link before payment. Paystack redirect with pending state; confirmation never shown until server verification.

### Receptionist
Three queues (Arrivals, In-house, Departures) with counts. Arrival row shows guest, room, balance, special requests, and one primary "Check in" action. Payment sheet shows folio summary, method tabs, amount, reference/terminal/evidence as relevant, and "print receipt" after success. Transfer submissions show "pending verification" and cannot be edited after submission. Checkout shows consolidated folio and blocks completion with an outstanding balance unless an authorised approval is recorded.

### Kitchen/Bar
Ticket cards with reference, destination, items, modifiers, age timer, and one next-status button. No prices or guest contact details beyond room/table. Ready orders disappear from kitchen and appear for waiter/bartender. Cancellation requires manager permission and a reason. Stock warnings appear before a transition that would fail.

### Housekeeping
Board columns Dirty → Cleaning → Inspection → Clean, with room number, type, assigned attendant, checkout time, priority. Attendant view is a personal task list with start/complete and notes. Supervisor can inspect/pass/reject and see history. Maintenance issue opens a report.

### Accountant
Reconciliation tabs: Pending verification, Verified today, Exceptions, Refunds, Expenses, Receivables. Summary cards reconcile to ledger. Nothing is edited in place: approve/reject/refund flows open a dialog with reason and audit notice.

### Owner
Read-only banner is explicit when no write grant exists. Trends use 7/30/90-day ranges. "Net operating result" includes a methodology popover. Low-stock and exceptions are actionable links but owner cannot mutate; they can notify the manager.

## 6. Responsive and accessibility requirements

- Breakpoints: 360, 640, 768, 1024, 1280, 1536.
- Tap targets ≥ 44px on touch; tables switch to card lists or horizontal scroll with sticky first column.
- Focus visible, skip link, semantic landmarks, labelled form controls, `aria-live` for status toasts.
- Dialog focus trap and escape close; no keyboard trap in date pickers.
- Contrast ≥ 4.5:1; gold text on ivory only for large/decorative labels; use navy for body.
- Charts have accessible tables or summaries; colour-blind-safe palette with patterns/labels.
- Date inputs have text alternatives; currency has `aria-label` including NGN.
- Print styles for receipts at 80mm and A4.

## 7. Prototype scope (Phase 2)

Implemented in this repository for review:

- Public home, rooms listing, room detail, booking wizard, dining, contact (representative content pages).
- Guest portal overview with stay, folio, payment history and pay dialog.
- Owner, manager, receptionist, housekeeping, laundry, kitchen, bar, waiter and accountant dashboards.
- Interactive demos: booking/deposit calculation, check-in and payment dialogs, transfer verification, kitchen/bar ticket progression, waiter delivery, housekeeping board, laundry progression, inventory alerts, owner charts.
- Shared design system, responsive shell and realistic sample data.

Not yet implemented in the prototype: real authentication, persistence, Paystack, email, file upload, PDF/XLSX generation, full public policy pages, and every settings screen. These are Phase 3+ and are explicitly gated by prototype approval.
