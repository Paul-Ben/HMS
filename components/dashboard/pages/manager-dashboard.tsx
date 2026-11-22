"use client";

import Link from "next/link";
import { useState } from "react";
import { toast } from "sonner";
import {
  ArrowRight,
  CalendarCheck,
  Check,
  CircleAlert,
  ClipboardCheck,
  CookingPot,
  Landmark,
  PackageOpen,
  Shirt,
  SprayCan,
  UtensilsCrossed,
  Users,
} from "lucide-react";
import { formatNaira } from "@/lib/format";
import {
  CATEGORY_BY_SLUG,
  DEMO_TODAY,
  ROOM_STATUS_META,
  type Payment,
} from "@/lib/prototype-data";
import {
  Avatar,
  PageHeader,
  ProgressBar,
  SectionCard,
  StatCard,
  StatusPill,
  type Tone,
} from "@/components/dashboard/dashboard-ui";
import { usePrototype } from "@/components/dashboard/prototype-provider";
import { TransferReviewDialog } from "@/components/dashboard/transfer-review-dialog";

const ACTIVITY_TONE: Record<string, Tone> = {
  green: "green",
  gold: "gold",
  red: "red",
  blue: "blue",
};

const DUTY = [
  { name: "Ifeoma Nwankwo", role: "Front desk", shift: "07:00–19:00", status: "On duty" },
  { name: "Chef Tobi Adebayo", role: "Kitchen", shift: "06:00–16:00", status: "On duty" },
  { name: "Kunle Martins", role: "Bar", shift: "12:00–00:00", status: "On duty" },
  { name: "Mercy Adeyemi", role: "Housekeeping", shift: "08:00–17:00", status: "On duty" },
  { name: "Esther Bello", role: "Laundry", shift: "08:00–17:00", status: "Break" },
  { name: "Bola Ajayi", role: "Accounts", shift: "09:00–18:00", status: "On duty" },
];

export function ManagerDashboard() {
  const {
    rooms,
    reservations,
    payments,
    orders,
    housekeeping,
    inventory,
    expenses,
    activity,
    checkIn,
  } = usePrototype();
  const [reviewPayment, setReviewPayment] = useState<Payment | null>(null);

  const arrivals = reservations.filter((reservation) => reservation.status === "arriving");
  const inHouse = reservations.filter((reservation) => reservation.status === "in-house");
  const departures = inHouse.filter(
    (reservation) => reservation.checkOut === DEMO_TODAY,
  );
  const openTickets = orders.filter(
    (order) => order.status === "new" || order.status === "preparing",
  );
  const pendingTransfers = payments.filter((payment) => payment.status === "Pending");
  const pendingTransferValue = pendingTransfers.reduce(
    (sum, payment) => sum + payment.amount,
    0,
  );
  const pendingExpenses = expenses.filter((expense) => expense.status === "Pending");
  const lowStock = inventory.filter((item) => item.stock < item.reorder);
  const openHousekeeping = housekeeping.filter((task) => task.status !== "clean");
  const floors = Array.from(new Set(rooms.map((room) => room.floor)));

  function handleCheckIn(reservationId: string, roomNumber: string) {
    const room = rooms.find((item) => item.number === roomNumber);
    if (room?.status !== "available") {
      toast.error(`Room ${roomNumber} is not ready for check-in.`);
      return;
    }
    checkIn(reservationId, roomNumber);
    toast.success(`Checked in to Room ${roomNumber}.`);
  }

  return (
    <div className="space-y-6">
      <PageHeader
        eyebrow="Operations desk"
        title="The day, in one place."
        description="Arrivals, departures, open tickets and the exceptions that need a decision before service gets busy."
        badge={
          <StatusPill
            label={`${openTickets.length} open tickets`}
            tone={openTickets.length > 5 ? "gold" : "green"}
          />
        }
        actions={
          <>
            <Link
              href="/dashboard/receptionist"
              className="inline-flex h-9 items-center gap-2 rounded-full bg-navy px-4 text-[11px] font-semibold text-white transition-colors hover:bg-navy-800"
            >
              Front desk
              <ArrowRight className="size-3.5" />
            </Link>
            <Link
              href="/dashboard/housekeeping"
              className="inline-flex h-9 items-center gap-2 rounded-full border border-border bg-white px-4 text-[11px] font-semibold text-navy transition-colors hover:border-gold"
            >
              <SprayCan className="size-3.5 text-gold" />
              Room care
            </Link>
          </>
        }
      />

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard
          label="Arrivals expected"
          value={String(arrivals.length)}
          detail={`${arrivals.filter((item) => item.vip).length} VIP · ${arrivals.filter((item) => item.balance > 0).length} with balance`}
          icon={CalendarCheck}
          tone="navy"
        />
        <StatCard
          label="In house"
          value={String(inHouse.length)}
          detail={`${departures.length} departing today`}
          icon={Users}
          tone="green"
        />
        <StatCard
          label="Open service tickets"
          value={String(openTickets.length)}
          detail={`${orders.filter((order) => order.status === "ready").length} ready for delivery`}
          icon={UtensilsCrossed}
          tone="gold"
        />
        <StatCard
          label="Pending transfers"
          value={String(pendingTransfers.length)}
          detail={formatNaira(pendingTransferValue)}
          icon={Landmark}
          tone="red"
        />
      </div>

      <div className="grid gap-5 xl:grid-cols-[1.4fr_0.85fr]">
        <SectionCard
          title="Arrivals to action"
          description="Check in when the room is ready and identity is confirmed."
          action={
            <span className="text-[10px] font-semibold text-muted-foreground">
              {arrivals.length} remaining
            </span>
          }
          bodyClassName="p-0"
        >
          <div className="overflow-x-auto">
            <table className="table-clean w-full min-w-[680px]">
              <thead>
                <tr className="border-b border-border/70 text-left">
                  <th className="px-5 py-2.5 text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                    Guest
                  </th>
                  <th className="px-3 py-2.5 text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                    Room
                  </th>
                  <th className="px-3 py-2.5 text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                    ETA
                  </th>
                  <th className="px-3 py-2.5 text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                    Balance
                  </th>
                  <th className="px-5 py-2.5 text-right text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                    Action
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border/60">
                {arrivals.map((reservation) => {
                  const category = CATEGORY_BY_SLUG[reservation.categorySlug];
                  const room = rooms.find(
                    (item) => item.number === reservation.roomNumber,
                  );
                  const ready = room?.status === "available";
                  return (
                    <tr key={reservation.id} className="hover:bg-ivory/40">
                      <td className="px-5 py-3">
                        <div className="flex items-center gap-2.5">
                          <Avatar name={reservation.guest} />
                          <div>
                            <div className="flex items-center gap-1.5">
                              <p className="text-xs font-semibold text-navy">
                                {reservation.guest}
                              </p>
                              {reservation.vip && (
                                <span className="rounded bg-gold/15 px-1 py-0.5 text-[7px] font-bold tracking-[0.08em] text-[#8a6b32] uppercase">
                                  VIP
                                </span>
                              )}
                            </div>
                            <p className="text-[10px] text-muted-foreground">
                              {category?.shortName} · {reservation.nights} nights ·{" "}
                              {reservation.guests} guests
                            </p>
                          </div>
                        </div>
                      </td>
                      <td className="px-3 py-3">
                        <p className="text-xs font-semibold text-navy">
                          {reservation.roomNumber}
                        </p>
                        <p className="text-[9px] text-muted-foreground">
                          {room ? ROOM_STATUS_META[room.status].label : "Unassigned"}
                        </p>
                      </td>
                      <td className="px-3 py-3 text-xs text-navy">{reservation.eta}</td>
                      <td className="px-3 py-3">
                        <p className="text-xs font-semibold text-navy">
                          {formatNaira(reservation.balance)}
                        </p>
                        <p className="text-[9px] text-muted-foreground">
                          {reservation.balance === 0 ? "Settled" : "Due"}
                        </p>
                      </td>
                      <td className="px-5 py-3 text-right">
                        <button
                          type="button"
                          onClick={() =>
                            handleCheckIn(reservation.id, reservation.roomNumber)
                          }
                          disabled={!ready}
                          className="inline-flex h-8 items-center gap-1.5 rounded-full bg-navy px-3.5 text-[10px] font-semibold text-white transition-colors hover:bg-navy-800 disabled:cursor-not-allowed disabled:opacity-40"
                        >
                          <Check className="size-3" />
                          Check in
                        </button>
                      </td>
                    </tr>
                  );
                })}
                {arrivals.length === 0 && (
                  <tr>
                    <td colSpan={5} className="px-5 py-10 text-center text-xs text-muted-foreground">
                      All expected arrivals are checked in.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </SectionCard>

        <SectionCard
          title="Exceptions"
          description="Items that need a decision"
          action={
            <CircleAlert className="size-4 text-clay" />
          }
        >
          <div className="space-y-3">
            {pendingTransfers.map((payment) => (
              <div
                key={payment.id}
                className="rounded-xl border border-gold/25 bg-gold/8 p-3"
              >
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <p className="text-xs font-semibold text-navy">
                      {payment.guest}
                    </p>
                    <p className="mt-0.5 text-[10px] text-muted-foreground">
                      {payment.reference} · {payment.receivedBy}
                    </p>
                  </div>
                  <StatusPill label={formatNaira(payment.amount)} tone="gold" />
                </div>
                <button
                  type="button"
                  onClick={() => setReviewPayment(payment)}
                  className="mt-2.5 inline-flex items-center gap-1 text-[10px] font-bold tracking-[0.08em] text-[#8a6b32] uppercase hover:text-navy"
                >
                  Review transfer
                  <ArrowRight className="size-3" />
                </button>
              </div>
            ))}

            {departures
              .filter((reservation) => reservation.balance > 0)
              .map((reservation) => (
                <div key={reservation.id} className="flex items-start gap-3 rounded-xl bg-red-50 p-3">
                  <CircleAlert className="mt-0.5 size-4 shrink-0 text-red-500" />
                  <div>
                    <p className="text-xs font-semibold text-navy">
                      {reservation.guest} departs with a balance
                    </p>
                    <p className="mt-0.5 text-[10px] text-muted-foreground">
                      Room {reservation.roomNumber} ·{" "}
                      {formatNaira(reservation.balance)} outstanding
                    </p>
                  </div>
                </div>
              ))}

            <div className="flex items-start gap-3 rounded-xl bg-sky-50 p-3">
              <PackageOpen className="mt-0.5 size-4 shrink-0 text-sky-600" />
              <div>
                <p className="text-xs font-semibold text-navy">
                  {lowStock.length} stock items below reorder
                </p>
                <p className="mt-0.5 text-[10px] leading-4 text-muted-foreground">
                  {lowStock.map((item) => item.name).join(", ")}.
                </p>
              </div>
            </div>

            <div className="flex items-start gap-3 rounded-xl bg-ivory p-3">
              <ClipboardCheck className="mt-0.5 size-4 shrink-0 text-gold" />
              <div>
                <p className="text-xs font-semibold text-navy">
                  {pendingExpenses.length} expenses awaiting approval
                </p>
                <p className="mt-0.5 text-[10px] text-muted-foreground">
                  {formatNaira(pendingExpenses.reduce((sum, expense) => sum + expense.amount, 0))}{" "}
                  submitted for review.
                </p>
              </div>
            </div>
          </div>
        </SectionCard>
      </div>

      <div className="grid gap-5 sm:grid-cols-2 xl:grid-cols-4">
        {[
          {
            label: "Kitchen",
            href: "/dashboard/kitchen",
            icon: CookingPot,
            open: orders.filter((order) => order.kind === "kitchen" && order.status !== "delivered").length,
            ready: orders.filter((order) => order.kind === "kitchen" && order.status === "ready").length,
            accent: "bg-clay/10 text-clay",
          },
          {
            label: "Bar",
            href: "/dashboard/bar",
            icon: UtensilsCrossed,
            open: orders.filter((order) => order.kind === "bar" && order.status !== "delivered").length,
            ready: orders.filter((order) => order.kind === "bar" && order.status === "ready").length,
            accent: "bg-gold/15 text-[#8a6b32]",
          },
          {
            label: "Laundry",
            href: "/dashboard/laundry",
            icon: Shirt,
            open: orders.filter((order) => order.kind === "laundry" && order.status !== "delivered").length,
            ready: orders.filter((order) => order.kind === "laundry" && order.status === "ready").length,
            accent: "bg-sky-50 text-sky-700",
          },
          {
            label: "Housekeeping",
            href: "/dashboard/housekeeping",
            icon: SprayCan,
            open: openHousekeeping.length,
            ready: housekeeping.filter((task) => task.status === "inspection").length,
            accent: "bg-emerald-50 text-emerald-700",
          },
        ].map((department) => (
          <Link
            key={department.label}
            href={department.href}
            className="surface-card group p-5 transition-colors hover:border-gold/50"
          >
            <div className="flex items-start justify-between">
              <span className={`flex size-9 items-center justify-center rounded-xl ${department.accent}`}>
                <department.icon className="size-4" />
              </span>
              <ArrowRight className="size-4 text-muted-foreground transition-transform group-hover:translate-x-0.5 group-hover:text-gold" />
            </div>
            <p className="mt-3 text-xs font-semibold text-navy">{department.label}</p>
            <div className="mt-1 flex items-end gap-2">
              <p className="font-heading text-3xl text-navy">{department.open}</p>
              <p className="mb-1 text-[10px] text-muted-foreground">open</p>
            </div>
            <p className="mt-1 text-[10px] text-muted-foreground">
              {department.ready} ready for next step
            </p>
          </Link>
        ))}
      </div>

      <div className="grid gap-5 lg:grid-cols-[0.9fr_1fr_1fr]">
        <SectionCard title="Occupancy by floor" description="Live room state">
          <div className="space-y-4">
            {floors.map((floor) => {
              const floorRooms = rooms.filter((room) => room.floor === floor);
              const occupied = floorRooms.filter((room) => room.status === "occupied").length;
              const available = floorRooms.filter((room) => room.status === "available").length;
              const percent = Math.round((occupied / floorRooms.length) * 100);
              return (
                <div key={floor}>
                  <div className="flex items-center justify-between text-[11px]">
                    <span className="font-medium text-navy">{floor}</span>
                    <span className="text-muted-foreground">
                      {occupied}/{floorRooms.length} · {available} ready
                    </span>
                  </div>
                  <ProgressBar
                    value={percent}
                    tone={percent > 70 ? "gold" : "navy"}
                    className="mt-1.5"
                  />
                </div>
              );
            })}
          </div>
        </SectionCard>

        <SectionCard title="On duty" description="Today's shift board">
          <div className="space-y-3.5">
            {DUTY.map((person) => (
              <div key={person.name} className="flex items-center gap-3">
                <Avatar name={person.name} />
                <div className="min-w-0 flex-1">
                  <p className="truncate text-xs font-semibold text-navy">
                    {person.name}
                  </p>
                  <p className="text-[10px] text-muted-foreground">
                    {person.role} · {person.shift}
                  </p>
                </div>
                <StatusPill
                  label={person.status}
                  tone={person.status === "On duty" ? "green" : "gold"}
                />
              </div>
            ))}
          </div>
        </SectionCard>

        <SectionCard
          title="Activity"
          description="Latest recorded actions"
          action={
            <Link
              href="/dashboard/owner"
              className="text-[10px] font-bold tracking-[0.08em] text-gold uppercase hover:text-navy"
            >
              Owner view
            </Link>
          }
        >
          <div className="space-y-3.5">
            {activity.slice(0, 6).map((item) => (
              <div key={item.id} className="flex items-start gap-3">
                <span className="mt-1.5 size-1.5 shrink-0 rounded-full bg-gold" />
                <div className="min-w-0 flex-1">
                  <p className="text-[11px] leading-5 text-navy">{item.text}</p>
                  <div className="mt-0.5 flex items-center gap-2">
                    <p className="text-[9px] text-muted-foreground">{item.time}</p>
                    <StatusPill
                      label={item.tone === "gold" ? "Finance" : item.tone === "red" ? "Alert" : item.tone === "green" ? "Payment" : "Ops"}
                      tone={ACTIVITY_TONE[item.tone] ?? "neutral"}
                    />
                  </div>
                </div>
              </div>
            ))}
          </div>
        </SectionCard>
      </div>

      <TransferReviewDialog
        payment={reviewPayment}
        onClose={() => setReviewPayment(null)}
      />
    </div>
  );
}
