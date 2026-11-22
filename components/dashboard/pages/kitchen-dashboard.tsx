"use client";

import { toast } from "sonner";
import {
  Check,
  ChefHat,
  CircleAlert,
  Clock,
  CookingPot,
  Flame,
  Timer,
  UtensilsCrossed,
} from "lucide-react";
import {
  ORDER_STATUS_LABEL,
  type OrderStatus,
} from "@/lib/prototype-data";
import { formatNaira } from "@/lib/format";
import {
  EmptyState,
  PageHeader,
  ProgressBar,
  SectionCard,
  StatCard,
  StatusPill,
  type Tone,
} from "@/components/dashboard/dashboard-ui";
import { usePrototype } from "@/components/dashboard/prototype-provider";

const COLUMNS: { key: OrderStatus; label: string; hint: string; tone: Tone }[] = [
  { key: "new", label: "New", hint: "Accept ticket", tone: "gold" },
  { key: "preparing", label: "Preparing", hint: "On the pass", tone: "blue" },
  { key: "ready", label: "Ready", hint: "Awaiting pickup", tone: "green" },
  { key: "delivered", label: "Delivered", hint: "Service complete", tone: "neutral" },
];

export function KitchenDashboard() {
  const { orders, inventory, advanceOrder } = usePrototype();

  const tickets = orders.filter((order) => order.kind === "kitchen");
  const byStatus = (status: OrderStatus) =>
    tickets.filter((order) => order.status === status);
  const active = tickets.filter((order) => order.status !== "delivered");
  const lowStock = inventory.filter(
    (item) => item.category === "Kitchen" && item.stock < item.reorder,
  );

  function handleAdvance(ticketId: string, status: OrderStatus) {
    advanceOrder(ticketId);
    if (status === "new") {
      toast.success(`Ticket ${ticketId} accepted. Start preparing.`);
    } else {
      toast.success(`Ticket ${ticketId} is ready for the waiter.`);
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        eyebrow="Kitchen pass"
        title="Tickets, pace and the pass."
        description="Accept tickets, move them through the pass and hand ready plates to the floor. Waiter delivery closes the ticket."
        badge={<StatusPill label="Kitchen · Chef Tobi" tone="green" />}
        actions={
          <div className="inline-flex items-center gap-2 rounded-full border border-border bg-white px-4 py-2 text-[11px] font-semibold text-navy">
            <Timer className="size-3.5 text-gold" />
            Target · 18 min per ticket
          </div>
        }
      />

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard
          label="New tickets"
          value={String(byStatus("new").length)}
          detail="Awaiting acceptance"
          icon={CookingPot}
          tone="gold"
        />
        <StatCard
          label="On the pass"
          value={String(byStatus("preparing").length)}
          detail={`${active.length} active tickets`}
          icon={Flame}
          tone="red"
        />
        <StatCard
          label="Ready for pickup"
          value={String(byStatus("ready").length)}
          detail="Waiter will deliver"
          icon={UtensilsCrossed}
          tone="green"
        />
        <StatCard
          label="Completed today"
          value={String(byStatus("delivered").length)}
          detail="Closed by the floor"
          icon={Check}
          tone="navy"
        />
      </div>

      <SectionCard
        title="Kitchen board"
        description="Accept → prepare → ready. The waiter confirms delivery and stock is deducted once."
        action={
          <span className="hidden items-center gap-1.5 text-[10px] text-muted-foreground sm:flex">
            <span className="size-1.5 rounded-full bg-emerald-500" />
            Live queue
          </span>
        }
        bodyClassName="p-4"
      >
        <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
          {COLUMNS.map((column) => {
            const columnTickets = byStatus(column.key);
            return (
              <div
                key={column.key}
                className="rounded-xl bg-ivory/60 p-2.5 ring-1 ring-border/60"
              >
                <div className="flex items-center justify-between px-1.5 py-1">
                  <div className="flex items-center gap-2">
                    <StatusPill label={column.label} tone={column.tone} />
                    <span className="text-[10px] font-semibold text-muted-foreground">
                      {columnTickets.length}
                    </span>
                  </div>
                  <span className="text-[8px] text-muted-foreground">{column.hint}</span>
                </div>

                <div className="mt-2 space-y-2">
                  {columnTickets.map((ticket) => (
                    <div
                      key={ticket.id}
                      className="rounded-lg border border-border/70 bg-white p-3 shadow-sm"
                    >
                      <div className="flex items-start justify-between gap-2">
                        <div>
                          <p className="font-heading text-xl leading-none text-navy">
                            {ticket.id}
                          </p>
                          <p className="mt-1 text-[10px] text-muted-foreground">
                            {ticket.source}
                            {ticket.guest ? ` · ${ticket.guest}` : ""}
                          </p>
                        </div>
                        <span className="inline-flex items-center gap-1 text-[9px] text-muted-foreground">
                          <Clock className="size-2.5" />
                          {ticket.placedAt}
                        </span>
                      </div>

                      <div className="mt-2.5 space-y-1">
                        {ticket.items.map((item) => (
                          <div
                            key={`${ticket.id}-${item.name}`}
                            className="flex items-center justify-between text-[10px]"
                          >
                            <span className="text-navy">
                              {item.qty} × {item.name}
                            </span>
                            <span className="text-muted-foreground">
                              {formatNaira(item.price * item.qty)}
                            </span>
                          </div>
                        ))}
                      </div>

                      {ticket.note && (
                        <p className="mt-2 rounded-md bg-clay/8 px-2 py-1.5 text-[9px] leading-4 text-clay">
                          {ticket.note}
                        </p>
                      )}

                      <div className="mt-2 flex items-center justify-between text-[9px]">
                        <span className="text-muted-foreground">
                          {ORDER_STATUS_LABEL[ticket.status]}
                        </span>
                        <span className="font-semibold text-navy">
                          {formatNaira(ticket.total)}
                        </span>
                      </div>

                      <div className="mt-2.5">
                        {ticket.status === "new" && (
                          <button
                            type="button"
                            onClick={() => handleAdvance(ticket.id, "new")}
                            className="inline-flex h-7 w-full items-center justify-center gap-1 rounded-full bg-navy text-[9px] font-semibold text-white hover:bg-navy-800"
                          >
                            <ChefHat className="size-3" />
                            Accept ticket
                          </button>
                        )}
                        {ticket.status === "preparing" && (
                          <button
                            type="button"
                            onClick={() => handleAdvance(ticket.id, "preparing")}
                            className="inline-flex h-7 w-full items-center justify-center gap-1 rounded-full bg-gold text-[9px] font-semibold text-navy hover:bg-gold-soft"
                          >
                            <Check className="size-3" />
                            Mark ready
                          </button>
                        )}
                        {ticket.status === "ready" && (
                          <div className="flex h-7 items-center justify-center gap-1 rounded-full bg-emerald-50 text-[9px] font-semibold text-emerald-700">
                            <UtensilsCrossed className="size-3" />
                            Awaiting waiter
                          </div>
                        )}
                        {ticket.status === "delivered" && (
                          <div className="flex h-7 items-center justify-center gap-1 rounded-full bg-emerald-50 text-[9px] font-semibold text-emerald-700">
                            <Check className="size-3" />
                            Delivered
                          </div>
                        )}
                      </div>
                    </div>
                  ))}

                  {columnTickets.length === 0 && (
                    <EmptyState
                      icon={column.key === "delivered" ? Check : CookingPot}
                      title={`No ${column.label.toLowerCase()} tickets`}
                      description={column.hint}
                    />
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </SectionCard>

      <div className="grid gap-5 lg:grid-cols-[1.15fr_1fr]">
        <SectionCard title="Kitchen stock cues" description="Below reorder point">
          <div className="space-y-3">
            {lowStock.map((item) => (
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
              <p className="text-xs text-muted-foreground">
                Kitchen stock is above reorder point.
              </p>
            )}
          </div>
          <div className="mt-4 flex items-start gap-2 rounded-lg bg-gold/10 px-3 py-2.5 text-[10px] leading-5 text-[#8a6b32]">
            <CircleAlert className="mt-0.5 size-3.5 shrink-0" />
            Stock is deducted when the waiter marks the ticket delivered, not when
            the kitchen accepts it.
          </div>
        </SectionCard>

        <SectionCard title="Pass notes" description="Chef's handover">
          <div className="space-y-3">
            <div className="rounded-xl bg-red-50 p-3">
              <p className="text-xs font-semibold text-navy">Allergy alert · Room 203</p>
              <p className="mt-1 text-[10px] leading-5 text-muted-foreground">
                No chilli on the tilapia. Check the ticket before it leaves the pass.
              </p>
            </div>
            <div className="rounded-xl bg-ivory p-3">
              <p className="text-xs font-semibold text-navy">Timing · Table 4</p>
              <p className="mt-1 text-[10px] leading-5 text-muted-foreground">
                Two burgers, medium. Fire the fries when the burgers are plated.
              </p>
            </div>
            <div className="rounded-xl bg-gold/10 p-3">
              <p className="text-xs font-semibold text-navy">Service note</p>
              <p className="mt-1 text-[10px] leading-5 text-muted-foreground">
                Ready tickets are collected by the floor. Keep the pass clear and
                call the ticket number.
              </p>
            </div>
          </div>
        </SectionCard>
      </div>
    </div>
  );
}
