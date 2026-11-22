"use client";

import { toast } from "sonner";
import {
  Check,
  Clock,
  PackageOpen,
  Shirt,
  Sparkles,
  Truck,
} from "lucide-react";
import {
  LAUNDRY_STATUS_LABEL,
  type OrderStatus,
} from "@/lib/prototype-data";
import { formatNaira } from "@/lib/format";
import {
  EmptyState,
  PageHeader,
  SectionCard,
  StatCard,
  StatusPill,
  type Tone,
} from "@/components/dashboard/dashboard-ui";
import { usePrototype } from "@/components/dashboard/prototype-provider";

const COLUMNS: { key: OrderStatus; label: string; hint: string; tone: Tone }[] = [
  { key: "new", label: "Requested", hint: "Awaiting intake", tone: "gold" },
  { key: "preparing", label: "Processing", hint: "In the wash", tone: "blue" },
  { key: "ready", label: "Ready", hint: "Ready to return", tone: "green" },
  { key: "delivered", label: "Delivered", hint: "Back with guest", tone: "neutral" },
];

export function LaundryDashboard() {
  const { orders, inventory, advanceOrder } = usePrototype();

  const laundry = orders.filter((order) => order.kind === "laundry");
  const byStatus = (status: OrderStatus) =>
    laundry.filter((order) => order.status === status);
  const totalItems = laundry.reduce(
    (sum, order) =>
      sum + order.items.reduce((itemSum, item) => itemSum + item.qty, 0),
    0,
  );
  const openValue = laundry
    .filter((order) => order.status !== "delivered")
    .reduce((sum, order) => sum + order.total, 0);
  const detergent = inventory.find((item) => item.id === "INV-11");

  function handleAdvance(
    orderId: string,
    roomNumber: string | undefined,
    status: OrderStatus,
  ) {
    advanceOrder(orderId);
    if (status === "new") {
      toast.success(`Laundry for ${roomNumber ? `Room ${roomNumber}` : "the hotel"} is in process.`);
    } else if (status === "preparing") {
      toast.success(`Order ${orderId} is ready for return.`);
    } else {
      toast.success(`Order ${orderId} delivered. Stock deducted once.`);
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        eyebrow="Laundry desk"
        title="Fresh linen, back on time."
        description="Track guest laundry from intake to delivery. Every delivered order updates the room folio and deducts detergent stock once."
        badge={<StatusPill label="Shift · Esther Bello" tone="green" />}
        actions={
          <div className="inline-flex items-center gap-2 rounded-full border border-border bg-white px-4 py-2 text-[11px] font-semibold text-navy">
            <Clock className="size-3.5 text-gold" />
            Same-day cutoff · 10:00
          </div>
        }
      />

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard
          label="New requests"
          value={String(byStatus("new").length)}
          detail={`${totalItems} items today`}
          icon={Shirt}
          tone="gold"
        />
        <StatCard
          label="In process"
          value={String(byStatus("preparing").length)}
          detail={formatNaira(openValue)}
          icon={Sparkles}
          tone="blue"
        />
        <StatCard
          label="Ready to return"
          value={String(byStatus("ready").length)}
          detail="Call the room before delivery"
          icon={PackageOpen}
          tone="green"
        />
        <StatCard
          label="Delivered today"
          value={String(byStatus("delivered").length)}
          detail="Stock deducted on delivery"
          icon={Check}
          tone="navy"
        />
      </div>

      <SectionCard
        title="Laundry board"
        description="Intake → process → ready → delivered. Delivery deducts stock once and posts the charge."
        bodyClassName="p-4"
      >
        <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
          {COLUMNS.map((column) => {
            const columnOrders = byStatus(column.key);
            return (
              <div
                key={column.key}
                className="rounded-xl bg-ivory/60 p-2.5 ring-1 ring-border/60"
              >
                <div className="flex items-center justify-between px-1.5 py-1">
                  <div className="flex items-center gap-2">
                    <StatusPill label={column.label} tone={column.tone} />
                    <span className="text-[10px] font-semibold text-muted-foreground">
                      {columnOrders.length}
                    </span>
                  </div>
                  <span className="text-[8px] text-muted-foreground">{column.hint}</span>
                </div>

                <div className="mt-2 space-y-2">
                  {columnOrders.map((order) => (
                    <div
                      key={order.id}
                      className="rounded-lg border border-border/70 bg-white p-3 shadow-sm"
                    >
                      <div className="flex items-start justify-between gap-2">
                        <div>
                          <p className="font-heading text-xl leading-none text-navy">
                            {order.roomNumber ? `Room ${order.roomNumber}` : order.source}
                          </p>
                          <p className="mt-1 text-[10px] text-muted-foreground">
                            {order.guest ?? "Walk-in"} · {order.id}
                          </p>
                        </div>
                        <StatusPill
                          label={LAUNDRY_STATUS_LABEL[order.status]}
                          tone={column.tone}
                        />
                      </div>

                      <div className="mt-2.5 space-y-1">
                        {order.items.map((item) => (
                          <div
                            key={`${order.id}-${item.name}`}
                            className="flex items-center justify-between text-[10px]"
                          >
                            <span className="text-muted-foreground">
                              {item.qty} × {item.name}
                            </span>
                            <span className="font-medium text-navy">
                              {formatNaira(item.price * item.qty)}
                            </span>
                          </div>
                        ))}
                      </div>

                      {order.note && (
                        <p className="mt-2 rounded-md bg-ivory/80 px-2 py-1.5 text-[9px] leading-4 text-muted-foreground">
                          {order.note}
                        </p>
                      )}

                      <div className="mt-2 flex items-center justify-between text-[9px]">
                        <span className="flex items-center gap-1 text-muted-foreground">
                          <Clock className="size-2.5" />
                          {order.due ?? order.placedAt}
                        </span>
                        <span className="font-semibold text-navy">
                          {formatNaira(order.total)}
                        </span>
                      </div>

                      <div className="mt-2.5">
                        {order.status === "new" && (
                          <button
                            type="button"
                            onClick={() =>
                              handleAdvance(order.id, order.roomNumber, "new")
                            }
                            className="inline-flex h-7 w-full items-center justify-center gap-1 rounded-full bg-navy text-[9px] font-semibold text-white hover:bg-navy-800"
                          >
                            <Shirt className="size-3" />
                            Start wash
                          </button>
                        )}
                        {order.status === "preparing" && (
                          <button
                            type="button"
                            onClick={() =>
                              handleAdvance(order.id, order.roomNumber, "preparing")
                            }
                            className="inline-flex h-7 w-full items-center justify-center gap-1 rounded-full bg-gold text-[9px] font-semibold text-navy hover:bg-gold-soft"
                          >
                            <Check className="size-3" />
                            Mark ready
                          </button>
                        )}
                        {order.status === "ready" && (
                          <button
                            type="button"
                            onClick={() =>
                              handleAdvance(order.id, order.roomNumber, "ready")
                            }
                            className="inline-flex h-7 w-full items-center justify-center gap-1 rounded-full bg-emerald-600 text-[9px] font-semibold text-white hover:bg-emerald-700"
                          >
                            <Truck className="size-3" />
                            Deliver to room
                          </button>
                        )}
                        {order.status === "delivered" && (
                          <div className="flex h-7 items-center justify-center gap-1 rounded-full bg-emerald-50 text-[9px] font-semibold text-emerald-700">
                            <Check className="size-3" />
                            Delivered
                          </div>
                        )}
                      </div>
                    </div>
                  ))}

                  {columnOrders.length === 0 && (
                    <EmptyState
                      icon={column.key === "delivered" ? Check : Shirt}
                      title={`No ${column.label.toLowerCase()} orders`}
                      description={column.hint}
                    />
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </SectionCard>

      <div className="grid gap-5 lg:grid-cols-[1fr_1fr_0.9fr]">
        <SectionCard title="Today's load" description="Items by service">
          <div className="space-y-3">
            {laundry.map((order) => {
              const items = order.items.reduce((sum, item) => sum + item.qty, 0);
              return (
                <div key={order.id} className="flex items-center gap-3">
                  <span className="flex size-8 shrink-0 items-center justify-center rounded-full bg-ivory text-gold">
                    <Shirt className="size-3.5" />
                  </span>
                  <div className="min-w-0 flex-1">
                    <p className="text-[11px] font-semibold text-navy">
                      {order.roomNumber ? `Room ${order.roomNumber}` : order.source}
                    </p>
                    <p className="text-[9px] text-muted-foreground">
                      {items} items · {order.due ?? order.placedAt}
                    </p>
                  </div>
                  <StatusPill
                    label={LAUNDRY_STATUS_LABEL[order.status]}
                    tone={COLUMNS.find((column) => column.key === order.status)?.tone ?? "neutral"}
                  />
                </div>
              );
            })}
          </div>
        </SectionCard>

        <SectionCard title="Detergent stock" description="Deducted on delivery">
          <div className="flex items-center justify-between rounded-xl bg-ivory p-4">
            <div>
              <p className="font-heading text-3xl text-navy">
                {detergent?.stock ?? 0}
              </p>
              <p className="text-[10px] text-muted-foreground">
                {detergent?.unit ?? "litres"} remaining
              </p>
            </div>
            <span className="flex size-10 items-center justify-center rounded-full bg-white text-gold ring-1 ring-border">
              <Sparkles className="size-4" />
            </span>
          </div>
          <div className="mt-3 flex items-center justify-between text-[10px]">
            <span className="text-muted-foreground">Reorder point</span>
            <span className="font-semibold text-navy">
              {detergent?.reorder ?? 0} {detergent?.unit ?? "litres"}
            </span>
          </div>
          <p className="mt-3 text-[10px] leading-5 text-muted-foreground">
            Stock is deducted once when an order is marked delivered, matching
            the production rule.
          </p>
        </SectionCard>

        <SectionCard title="Return checklist" description="Before leaving the desk">
          <div className="space-y-2.5">
            {[
              "Items counted and matched to the ticket",
              "Garments checked for damage",
              "Room called before delivery",
              "Charge posted to the folio",
              "Delivery time recorded",
            ].map((item) => (
              <div key={item} className="flex items-start gap-2.5 text-[10px] leading-5 text-muted-foreground">
                <Check className="mt-0.5 size-3 shrink-0 text-emerald-600" />
                {item}
              </div>
            ))}
          </div>
        </SectionCard>
      </div>
    </div>
  );
}
