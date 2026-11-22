"use client";

import Link from "next/link";
import {
  ArrowRight,
  Banknote,
  BedDouble,
  CalendarCheck,
  CircleAlert,
  CreditCard,
  Eye,
  Landmark,
  PackageOpen,
  ReceiptText,
  TrendingUp,
  Users,
  Wallet,
} from "lucide-react";
import { formatNaira } from "@/lib/format";
import {
  CATEGORY_BY_SLUG,
  DEMO_TODAY,
  type PaymentMethod,
} from "@/lib/prototype-data";
import {
  Avatar,
  DetailRow,
  PageHeader,
  ProgressBar,
  SectionCard,
  StatCard,
  StatusPill,
  type Tone,
} from "@/components/dashboard/dashboard-ui";
import { usePrototype } from "@/components/dashboard/prototype-provider";
import { CollectionsChart } from "@/components/dashboard/owner-charts";

const METHOD_COLORS: Record<PaymentMethod, string> = {
  Paystack: "bg-gold",
  Cash: "bg-emerald-500",
  POS: "bg-sky-500",
  "Bank transfer": "bg-clay",
};

const ACTIVITY_TONE: Record<string, Tone> = {
  green: "green",
  gold: "gold",
  red: "red",
  blue: "blue",
};

export function OwnerDashboard() {
  const {
    rooms,
    reservations,
    payments,
    activity,
    inventory,
    expenses,
    orders,
  } = usePrototype();

  const completed = payments.filter((payment) => payment.status === "Completed");
  const collected = completed.reduce((sum, payment) => sum + payment.amount, 0);
  const pendingTransfers = payments.filter((payment) => payment.status === "Pending");
  const pendingTransferValue = pendingTransfers.reduce(
    (sum, payment) => sum + payment.amount,
    0,
  );
  const outstanding = reservations
    .filter((reservation) => reservation.status !== "departed")
    .reduce((sum, reservation) => sum + reservation.balance, 0);
  const occupiedRooms = rooms.filter((room) => room.status === "occupied");
  const arrivals = reservations.filter((reservation) => reservation.status === "arriving");
  const inHouse = reservations.filter((reservation) => reservation.status === "in-house");
  const departures = inHouse.filter(
    (reservation) => reservation.checkOut === DEMO_TODAY,
  );
  const occupancy = rooms.length
    ? Math.round((occupiedRooms.length / rooms.length) * 100)
    : 0;
  const adr = occupiedRooms.length
    ? Math.round(
        occupiedRooms.reduce(
          (sum, room) =>
            sum + (CATEGORY_BY_SLUG[room.categorySlug]?.rate ?? 0),
          0,
        ) / occupiedRooms.length,
      )
    : 0;
  const revpar = Math.round((adr * occupancy) / 100);
  const lowStock = inventory.filter((item) => item.stock < item.reorder);
  const pendingExpenses = expenses.filter((expense) => expense.status === "Pending");
  const deliveredOrders = orders.filter((order) => order.status === "delivered");

  const methodTotals = completed.reduce<Record<string, number>>((accumulator, payment) => {
    accumulator[payment.method] = (accumulator[payment.method] ?? 0) + payment.amount;
    return accumulator;
  }, {});

  return (
    <div className="space-y-6">
      <PageHeader
        eyebrow="Executive overview"
        title="Good morning, Adebayo."
        description="A calm view of the hotel: revenue, occupancy and the exceptions that need a manager's attention."
        badge={
          <StatusPill label="Owner · read-only" tone="gold" className="gap-1" />
        }
        actions={
          <>
            <Link
              href="/dashboard/manager"
              className="inline-flex h-9 items-center gap-2 rounded-full bg-navy px-4 text-[11px] font-semibold text-white transition-colors hover:bg-navy-800"
            >
              Operations desk
              <ArrowRight className="size-3.5" />
            </Link>
            <span className="inline-flex h-9 items-center gap-2 rounded-full border border-border bg-white px-4 text-[11px] font-semibold text-muted-foreground">
              <Eye className="size-3.5 text-gold" />
              View only
            </span>
          </>
        }
      />

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard
          label="Collected to date"
          value={formatNaira(collected)}
          detail={`${completed.length} settled payments`}
          icon={Wallet}
          tone="navy"
        />
        <StatCard
          label="Outstanding balances"
          value={formatNaira(outstanding)}
          detail={`${reservations.filter((item) => item.balance > 0 && item.status !== "departed").length} folios open`}
          icon={ReceiptText}
          tone="gold"
        />
        <StatCard
          label="Occupancy tonight"
          value={`${occupancy}%`}
          detail={`${occupiedRooms.length} of ${rooms.length} rooms occupied`}
          icon={BedDouble}
          tone="green"
        />
        <StatCard
          label="ADR / RevPAR"
          value={formatNaira(adr)}
          detail={`RevPAR ${formatNaira(revpar)}`}
          icon={TrendingUp}
          tone="blue"
        />
      </div>

      <div className="grid gap-5 xl:grid-cols-[1.65fr_0.85fr]">
        <SectionCard
          title="Collections, last 14 days"
          description="Settled payments by department. Sample trend for the prototype."
          action={
            <div className="flex items-center gap-3 text-[10px] text-muted-foreground">
              <span className="flex items-center gap-1.5">
                <span className="size-2 rounded-full bg-gold" />
                Rooms
              </span>
              <span className="flex items-center gap-1.5">
                <span className="size-2 rounded-full bg-navy-800" />
                F&amp;B &amp; other
              </span>
            </div>
          }
          bodyClassName="px-3 pt-5 pb-3"
        >
          <CollectionsChart />
        </SectionCard>

        <div className="space-y-5">
          <SectionCard title="Today at a glance">
            <div className="grid grid-cols-3 gap-2 text-center">
              {[
                { label: "Arrivals", value: arrivals.length, icon: CalendarCheck, tone: "text-emerald-600" },
                { label: "In house", value: inHouse.length, icon: Users, tone: "text-navy" },
                { label: "Departures", value: departures.length, icon: BedDouble, tone: "text-clay" },
              ].map((item) => (
                <div key={item.label} className="rounded-xl bg-ivory/70 px-2 py-3">
                  <item.icon className={`mx-auto size-4 ${item.tone}`} />
                  <p className="mt-2 font-heading text-2xl text-navy">{item.value}</p>
                  <p className="text-[9px] font-semibold tracking-[0.08em] text-muted-foreground uppercase">
                    {item.label}
                  </p>
                </div>
              ))}
            </div>
            <div className="mt-5">
              <div className="flex items-center justify-between text-[11px]">
                <span className="text-muted-foreground">Room occupancy</span>
                <span className="font-bold text-navy">{occupancy}%</span>
              </div>
              <ProgressBar value={occupancy} className="mt-2" />
              <div className="mt-4 flex items-center justify-between text-[11px]">
                <span className="text-muted-foreground">Rooms ready to sell</span>
                <span className="font-bold text-navy">
                  {rooms.filter((room) => room.status === "available").length}
                </span>
              </div>
              <div className="mt-4 flex items-center justify-between text-[11px]">
                <span className="text-muted-foreground">Out of order</span>
                <span className="font-bold text-navy">
                  {rooms.filter((room) => room.status === "maintenance").length}
                </span>
              </div>
            </div>
          </SectionCard>

          <SectionCard title="Owner notes" description="Read-only in this prototype.">
            <p className="text-xs leading-6 text-muted-foreground">
              Financial records cannot be edited from the owner view. Approvals
              and corrections are made by the manager or accounts desk, keeping a
              visible audit trail.
            </p>
            <div className="mt-4 flex items-center gap-2 rounded-lg bg-gold/10 px-3 py-2.5 text-[10px] leading-5 text-[#8a6b32]">
              <Eye className="size-3.5 shrink-0" />
              Every action in the prototype is labelled by role and recorded in
              the activity feed.
            </div>
          </SectionCard>
        </div>
      </div>

      <div className="grid gap-5 xl:grid-cols-[1.25fr_0.9fr_0.85fr]">
        <SectionCard
          title="Arrivals today"
          description={`${arrivals.length} expected · ${arrivals.filter((item) => item.vip).length} VIP`}
          action={
            <Link
              href="/dashboard/receptionist"
              className="text-[10px] font-bold tracking-[0.08em] text-gold uppercase hover:text-navy"
            >
              Front desk
            </Link>
          }
          bodyClassName="p-0"
        >
          <div className="divide-y divide-border/70">
            {arrivals.map((reservation) => {
              const category = CATEGORY_BY_SLUG[reservation.categorySlug];
              return (
                <div
                  key={reservation.id}
                  className="flex items-center gap-3 px-5 py-3.5"
                >
                  <Avatar name={reservation.guest} />
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2">
                      <p className="truncate text-xs font-semibold text-navy">
                        {reservation.guest}
                      </p>
                      {reservation.vip && (
                        <span className="rounded bg-gold/15 px-1.5 py-0.5 text-[8px] font-bold tracking-[0.08em] text-[#8a6b32] uppercase">
                          VIP
                        </span>
                      )}
                    </div>
                    <p className="mt-0.5 truncate text-[10px] text-muted-foreground">
                      Room {reservation.roomNumber} · {category?.shortName} ·{" "}
                      {reservation.nights} nights
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="text-[10px] font-semibold text-navy">
                      {reservation.eta}
                    </p>
                    <p className="text-[9px] text-muted-foreground">
                      {reservation.balance > 0
                        ? `${formatNaira(reservation.balance)} due`
                        : "Paid"}
                    </p>
                  </div>
                </div>
              );
            })}
          </div>
        </SectionCard>

        <SectionCard
          title="Payment mix"
          description={`${formatNaira(collected)} settled`}
        >
          <div className="space-y-4">
            {(Object.keys(METHOD_COLORS) as PaymentMethod[]).map((method) => {
              const amount = methodTotals[method] ?? 0;
              const share = collected ? Math.round((amount / collected) * 100) : 0;
              return (
                <div key={method}>
                  <div className="flex items-center justify-between text-[11px]">
                    <span className="flex items-center gap-2 text-muted-foreground">
                      <span className={`size-2 rounded-full ${METHOD_COLORS[method]}`} />
                      {method}
                    </span>
                    <span className="font-semibold text-navy">{formatNaira(amount)}</span>
                  </div>
                  <div className="mt-1.5 h-1.5 overflow-hidden rounded-full bg-navy/8">
                    <div
                      className={`h-full rounded-full ${METHOD_COLORS[method]}`}
                      style={{ width: `${share}%` }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
          <div className="mt-5 border-t border-border/70 pt-4">
            <DetailRow
              label="Pending transfers"
              value={`${pendingTransfers.length} · ${formatNaira(pendingTransferValue)}`}
              strong
            />
            <DetailRow
              label="Pending expenses"
              value={`${pendingExpenses.length} · ${formatNaira(pendingExpenses.reduce((sum, expense) => sum + expense.amount, 0))}`}
            />
          </div>
        </SectionCard>

        <SectionCard
          title="Needs attention"
          description="Exceptions raised today"
          action={
            <Link
              href="/dashboard/accountant"
              className="text-[10px] font-bold tracking-[0.08em] text-gold uppercase hover:text-navy"
            >
              Accounts
            </Link>
          }
        >
          <div className="space-y-3">
            <div className="flex items-start gap-3 rounded-xl bg-gold/10 p-3">
              <Landmark className="mt-0.5 size-4 shrink-0 text-gold" />
              <div>
                <p className="text-xs font-semibold text-navy">
                  {pendingTransfers.length} transfers awaiting verification
                </p>
                <p className="mt-0.5 text-[10px] leading-4 text-muted-foreground">
                  {formatNaira(pendingTransferValue)} not yet applied to folios.
                </p>
              </div>
            </div>
            <div className="flex items-start gap-3 rounded-xl bg-red-50 p-3">
              <CircleAlert className="mt-0.5 size-4 shrink-0 text-red-500" />
              <div>
                <p className="text-xs font-semibold text-navy">
                  {lowStock.length} items below reorder
                </p>
                <p className="mt-0.5 text-[10px] leading-4 text-muted-foreground">
                  {lowStock
                    .slice(0, 3)
                    .map((item) => item.name)
                    .join(", ")}
                  .
                </p>
              </div>
            </div>
            <div className="flex items-start gap-3 rounded-xl bg-sky-50 p-3">
              <PackageOpen className="mt-0.5 size-4 shrink-0 text-sky-600" />
              <div>
                <p className="text-xs font-semibold text-navy">
                  {deliveredOrders.length} delivered orders today
                </p>
                <p className="mt-0.5 text-[10px] leading-4 text-muted-foreground">
                  {formatNaira(deliveredOrders.reduce((sum, order) => sum + order.total, 0))}{" "}
                  charged to rooms and tables.
                </p>
              </div>
            </div>
            <div className="flex items-start gap-3 rounded-xl bg-emerald-50 p-3">
              <Banknote className="mt-0.5 size-4 shrink-0 text-emerald-600" />
              <div>
                <p className="text-xs font-semibold text-navy">
                  {departures.filter((item) => item.balance > 0).length} departures with a balance
                </p>
                <p className="mt-0.5 text-[10px] leading-4 text-muted-foreground">
                  Front desk will settle or invoice before checkout.
                </p>
              </div>
            </div>
          </div>
        </SectionCard>
      </div>

      <div className="grid gap-5 lg:grid-cols-[1.35fr_1fr]">
        <SectionCard
          title="Activity feed"
          description="Recorded actions from the review day"
          action={
            <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-50 px-2.5 py-1 text-[9px] font-bold tracking-[0.08em] text-emerald-700 uppercase ring-1 ring-emerald-200">
              <span className="size-1.5 rounded-full bg-emerald-500" />
              Live prototype
            </span>
          }
        >
          <div className="space-y-4">
            {activity.slice(0, 7).map((item) => (
              <div key={item.id} className="flex items-start gap-3">
                <span className="mt-1.5 size-1.5 shrink-0 rounded-full bg-gold" />
                <div className="min-w-0 flex-1">
                  <p className="text-xs leading-5 text-navy">{item.text}</p>
                  <p className="mt-0.5 text-[9px] text-muted-foreground">{item.time}</p>
                </div>
                <StatusPill
                  label={item.tone === "gold" ? "Finance" : item.tone === "red" ? "Alert" : item.tone === "green" ? "Payment" : "Ops"}
                  tone={ACTIVITY_TONE[item.tone] ?? "neutral"}
                  className="hidden sm:inline-flex"
                />
              </div>
            ))}
          </div>
        </SectionCard>

        <SectionCard
          title="Stock watch"
          description="Items at or below reorder point"
          action={
            <Link
              href="/dashboard/inventory"
              className="text-[10px] font-bold tracking-[0.08em] text-gold uppercase hover:text-navy"
            >
              Inventory
            </Link>
          }
        >
          <div className="space-y-4">
            {lowStock.slice(0, 5).map((item) => (
              <div key={item.id}>
                <div className="flex items-center justify-between text-[11px]">
                  <span className="font-medium text-navy">{item.name}</span>
                  <span className="text-muted-foreground">
                    {item.stock} / {item.reorder} {item.unit}
                  </span>
                </div>
                <ProgressBar
                  value={(item.stock / Math.max(item.reorder, 1)) * 100}
                  tone="red"
                  className="mt-1.5"
                />
              </div>
            ))}
            {lowStock.length === 0 && (
              <p className="text-xs text-muted-foreground">All stock above reorder point.</p>
            )}
            <div className="flex items-center gap-2 border-t border-border/70 pt-3 text-[10px] text-muted-foreground">
              <CreditCard className="size-3.5 text-gold" />
              Stock is valued at latest unit cost.
            </div>
          </div>
        </SectionCard>
      </div>
    </div>
  );
}
