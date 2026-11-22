"use client";

import { toast } from "sonner";
import {
  Check,
  Clock,
  ConciergeBell,
  CookingPot,
  MapPin,
  Martini,
  PackageCheck,
  Truck,
  UtensilsCrossed,
} from "lucide-react";
import { formatNaira } from "@/lib/format";
import {
  EmptyState,
  PageHeader,
  SectionCard,
  StatCard,
  StatusPill,
} from "@/components/dashboard/dashboard-ui";
import { usePrototype } from "@/components/dashboard/prototype-provider";

export function WaiterDashboard() {
  const { orders, advanceOrder } = usePrototype();

  const readyOrders = orders.filter(
    (order) => order.kind !== "laundry" && order.status === "ready",
  );
  const preparingOrders = orders.filter(
    (order) => order.kind !== "laundry" && order.status === "preparing",
  );
  const deliveredOrders = orders.filter(
    (order) => order.kind !== "laundry" && order.status === "delivered",
  );
  const openOrders = orders.filter(
    (order) => order.kind !== "laundry" && order.status !== "delivered",
  );

  function handleDeliver(orderId: string, destination: string) {
    advanceOrder(orderId);
    toast.success(
      `Delivered to ${destination}. The room folio was updated and stock deducted once.`,
    );
  }

  return (
    <div className="space-y-6">
      <PageHeader
        eyebrow="Floor service"
        title="Ready plates, right rooms."
        description="Collect ready kitchen and bar orders, deliver them to the right destination and close the loop with the guest."
        badge={
          <StatusPill
            label={`${readyOrders.length} ready for pickup`}
            tone={readyOrders.length > 0 ? "green" : "neutral"}
          />
        }
        actions={
          <div className="inline-flex items-center gap-2 rounded-full border border-border bg-white px-4 py-2 text-[11px] font-semibold text-navy">
            <Clock className="size-3.5 text-gold" />
            Service window · 12:00–22:30
          </div>
        }
      />

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard
          label="Ready for pickup"
          value={String(readyOrders.length)}
          detail="Collect from the pass now"
          icon={ConciergeBell}
          tone="green"
        />
        <StatCard
          label="Still preparing"
          value={String(preparingOrders.length)}
          detail="Do not collect yet"
          icon={CookingPot}
          tone="gold"
        />
        <StatCard
          label="Open tickets"
          value={String(openOrders.length)}
          detail="Across kitchen and bar"
          icon={UtensilsCrossed}
          tone="navy"
        />
        <StatCard
          label="Delivered today"
          value={String(deliveredOrders.length)}
          detail="Charges posted to folios"
          icon={PackageCheck}
          tone="blue"
        />
      </div>

      <div className="grid gap-5 xl:grid-cols-[1.2fr_0.9fr]">
        <SectionCard
          title="Ready for pickup"
          description="Confirm the destination with the guest before delivery."
          action={
            <span className="rounded-full bg-emerald-50 px-2.5 py-1 text-[9px] font-bold tracking-[0.08em] text-emerald-700 uppercase ring-1 ring-emerald-200">
              {readyOrders.length} active
            </span>
          }
        >
          <div className="space-y-3">
            {readyOrders.map((order) => (
              <div
                key={order.id}
                className="rounded-xl border border-border/70 bg-white p-4 shadow-sm"
              >
                <div className="flex flex-wrap items-start justify-between gap-3">
                  <div className="flex items-start gap-3">
                    <span
                      className={`flex size-9 shrink-0 items-center justify-center rounded-xl ${
                        order.kind === "kitchen"
                          ? "bg-clay/10 text-clay"
                          : "bg-gold/15 text-[#8a6b32]"
                      }`}
                    >
                      {order.kind === "kitchen" ? (
                        <UtensilsCrossed className="size-4" />
                      ) : (
                        <Martini className="size-4" />
                      )}
                    </span>
                    <div>
                      <p className="flex items-center gap-2 text-sm font-semibold text-navy">
                        {order.source}
                        <StatusPill
                          label={order.kind === "kitchen" ? "Kitchen" : "Bar"}
                          tone={order.kind === "kitchen" ? "clay" : "gold"}
                        />
                      </p>
                      <p className="mt-0.5 flex items-center gap-1 text-[10px] text-muted-foreground">
                        <MapPin className="size-2.5" />
                        {order.roomNumber
                          ? `Room ${order.roomNumber}${order.guest ? ` · ${order.guest}` : ""}`
                          : `${order.source} · walk-in`}
                      </p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-xs font-semibold text-navy">
                      {formatNaira(order.total)}
                    </p>
                    <p className="text-[9px] text-muted-foreground">
                      Ready since {order.placedAt}
                    </p>
                  </div>
                </div>

                <div className="mt-3 flex flex-wrap items-center gap-x-4 gap-y-1 rounded-lg bg-ivory/70 px-3 py-2">
                  {order.items.map((item) => (
                    <span key={`${order.id}-${item.name}`} className="text-[10px] text-navy">
                      <span className="font-semibold">{item.qty}×</span> {item.name}
                    </span>
                  ))}
                </div>

                <div className="mt-3 flex flex-wrap items-center justify-between gap-2">
                  <p className="text-[9px] text-muted-foreground">
                    {order.roomNumber
                      ? "Delivery charges the room folio automatically."
                      : "Walk-in charge settles at the point of sale."}
                  </p>
                  <button
                    type="button"
                    onClick={() =>
                      handleDeliver(
                        order.id,
                        order.roomNumber
                          ? `Room ${order.roomNumber}`
                          : order.source,
                      )
                    }
                    className="inline-flex h-9 items-center gap-2 rounded-full bg-navy px-4 text-[10px] font-semibold text-white transition-colors hover:bg-navy-800"
                  >
                    <Truck className="size-3.5" />
                    Confirm delivery
                  </button>
                </div>
              </div>
            ))}

            {readyOrders.length === 0 && (
              <EmptyState
                icon={ConciergeBell}
                title="Nothing waiting at the pass"
                description="When the kitchen or bar marks an order ready, it will appear here."
              />
            )}
          </div>
        </SectionCard>

        <div className="space-y-5">
          <SectionCard title="In the pass" description="Preparing now — do not collect">
            <div className="space-y-2.5">
              {preparingOrders.map((order) => (
                <div
                  key={order.id}
                  className="flex items-center gap-3 rounded-lg border border-border/60 px-3 py-2.5"
                >
                  <span className="flex size-7 items-center justify-center rounded-full bg-gold/15 text-gold">
                    {order.kind === "kitchen" ? (
                      <CookingPot className="size-3.5" />
                    ) : (
                      <Martini className="size-3.5" />
                    )}
                  </span>
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-[11px] font-semibold text-navy">
                      {order.id} · {order.source}
                    </p>
                    <p className="text-[9px] text-muted-foreground">
                      {order.items.reduce((sum, item) => sum + item.qty, 0)} items ·{" "}
                      {formatNaira(order.total)}
                    </p>
                  </div>
                  <StatusPill label="Preparing" tone="gold" />
                </div>
              ))}
              {preparingOrders.length === 0 && (
                <p className="text-xs text-muted-foreground">Nothing in preparation.</p>
              )}
            </div>
          </SectionCard>

          <SectionCard title="Delivered" description="Closed today">
            <div className="space-y-2.5">
              {deliveredOrders.map((order) => (
                <div key={order.id} className="flex items-center gap-3">
                  <span className="flex size-7 shrink-0 items-center justify-center rounded-full bg-emerald-50 text-emerald-600">
                    <Check className="size-3.5" />
                  </span>
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-[11px] font-semibold text-navy">
                      {order.source}
                    </p>
                    <p className="text-[9px] text-muted-foreground">
                      {order.id} · {formatNaira(order.total)}
                    </p>
                  </div>
                  <span className="text-[9px] text-muted-foreground">{order.placedAt}</span>
                </div>
              ))}
              {deliveredOrders.length === 0 && (
                <p className="text-xs text-muted-foreground">No deliveries yet.</p>
              )}
            </div>
          </SectionCard>
        </div>
      </div>

      <SectionCard title="Service sequence" description="A quick check before leaving the pass">
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
          {[
            {
              step: "01",
              title: "Confirm the ticket",
              copy: "Match order number, room and any allergy note.",
            },
            {
              step: "02",
              title: "Check the plate",
              copy: "Everything present, hot, and presented as ordered.",
            },
            {
              step: "03",
              title: "Deliver and greet",
              copy: "Knock, announce, and place the order where the guest asks.",
            },
            {
              step: "04",
              title: "Close the loop",
              copy: "Mark delivered so the folio and stock update once.",
            },
          ].map((item) => (
            <div key={item.step} className="rounded-xl bg-ivory/70 p-4">
              <p className="font-heading text-2xl text-gold">{item.step}</p>
              <p className="mt-1 text-[11px] font-semibold text-navy">{item.title}</p>
              <p className="mt-1 text-[10px] leading-5 text-muted-foreground">{item.copy}</p>
            </div>
          ))}
        </div>
      </SectionCard>
    </div>
  );
}
