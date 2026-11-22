"use client";

import { useState } from "react";
import { toast } from "sonner";
import {
  Check,
  CircleAlert,
  Clock,
  GlassWater,
  Martini,
  Plus,
  Sparkles,
  Wine,
} from "lucide-react";
import {
  ORDER_STATUS_LABEL,
  type OrderStatus,
} from "@/lib/prototype-data";
import { formatNaira } from "@/lib/format";
import {
  EmptyState,
  Modal,
  PageHeader,
  ProgressBar,
  SectionCard,
  StatCard,
  StatusPill,
  type Tone,
} from "@/components/dashboard/dashboard-ui";
import { usePrototype } from "@/components/dashboard/prototype-provider";

const COLUMNS: { key: OrderStatus; label: string; hint: string; tone: Tone }[] = [
  { key: "new", label: "New", hint: "Make the drink", tone: "gold" },
  { key: "preparing", label: "Preparing", hint: "At the bar", tone: "blue" },
  { key: "ready", label: "Ready", hint: "Awaiting pickup", tone: "green" },
  { key: "delivered", label: "Delivered", hint: "Service complete", tone: "neutral" },
];

const BAR_ITEMS = [
  { id: "bar-1", name: "Aurelia Sunset", price: 9500, stockId: "INV-01", stockQty: 0.2 },
  { id: "bar-2", name: "House red glass", price: 7000, stockId: "INV-02", stockQty: 0.2 },
  { id: "bar-3", name: "Espresso martini", price: 11000, stockId: "INV-02", stockQty: 0.2 },
  { id: "bar-4", name: "Chapman", price: 6000, stockId: "INV-03", stockQty: 2 },
  { id: "bar-5", name: "Sparkling water", price: 2500, stockId: "INV-04", stockQty: 1 },
];

export function BarDashboard() {
  const { orders, reservations, inventory, advanceOrder, createOrder } =
    usePrototype();
  const [open, setOpen] = useState(false);
  const [roomNumber, setRoomNumber] = useState("");
  const [itemId, setItemId] = useState(BAR_ITEMS[0].id);
  const [qty, setQty] = useState("1");
  const [note, setNote] = useState("");

  const barOrders = orders.filter((order) => order.kind === "bar");
  const byStatus = (status: OrderStatus) =>
    barOrders.filter((order) => order.status === status);
  const inHouse = reservations.filter((reservation) => reservation.status === "in-house");
  const lowStock = inventory.filter(
    (item) => item.category === "Bar" && item.stock < item.reorder,
  );
  const selectedItem = BAR_ITEMS.find((item) => item.id === itemId) ?? BAR_ITEMS[0];
  const quantity = Math.max(1, Number(qty) || 1);
  const orderTotal = selectedItem.price * quantity;
  const selectedGuest = inHouse.find(
    (reservation) => reservation.roomNumber === roomNumber,
  );

  function handleAdvance(orderId: string, status: OrderStatus) {
    advanceOrder(orderId);
    if (status === "new") {
      toast.success(`Order ${orderId} accepted at the bar.`);
    } else {
      toast.success(`Order ${orderId} is ready for the waiter.`);
    }
  }

  function handleCreate() {
    if (!roomNumber) {
      toast.error("Select an in-house room for this order.");
      return;
    }
    createOrder({
      kind: "bar",
      source: `Room ${roomNumber}`,
      roomNumber,
      guest: selectedGuest?.guest,
      items: [
        {
          name: selectedItem.name,
          qty: quantity,
          price: selectedItem.price,
          stockId: selectedItem.stockId,
          stockQty: selectedItem.stockQty,
        },
      ],
      note: note.trim() || undefined,
    });
    toast.success(`Bar order added for Room ${roomNumber}.`);
    setOpen(false);
    setRoomNumber("");
    setQty("1");
    setNote("");
  }

  return (
    <div className="space-y-6">
      <PageHeader
        eyebrow="Bar service"
        title="The Gold Room, in flow."
        description="Keep the bar queue moving, watch stock cues and send ready drinks to the floor."
        badge={<StatusPill label="Bar · Kunle Martins" tone="green" />}
        actions={
          <>
            <button
              type="button"
              onClick={() => setOpen(true)}
              className="inline-flex h-9 items-center gap-2 rounded-full bg-navy px-4 text-[11px] font-semibold text-white transition-colors hover:bg-navy-800"
            >
              <Plus className="size-3.5" />
              Quick order
            </button>
            <span className="inline-flex h-9 items-center gap-2 rounded-full border border-border bg-white px-4 text-[11px] font-semibold text-navy">
              <Clock className="size-3.5 text-gold" />
              Happy hour · 17:00
            </span>
          </>
        }
      />

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard
          label="New orders"
          value={String(byStatus("new").length)}
          detail="Awaiting the bar"
          icon={Martini}
          tone="gold"
        />
        <StatCard
          label="Preparing"
          value={String(byStatus("preparing").length)}
          detail="At the well"
          icon={GlassWater}
          tone="blue"
        />
        <StatCard
          label="Ready"
          value={String(byStatus("ready").length)}
          detail="Waiter will collect"
          icon={Sparkles}
          tone="green"
        />
        <StatCard
          label="Delivered"
          value={String(byStatus("delivered").length)}
          detail="Closed today"
          icon={Check}
          tone="navy"
        />
      </div>

      <SectionCard
        title="Bar board"
        description="New orders are accepted at the bar, prepared, then handed to the floor. Stock deducts on delivery."
        action={
          <button
            type="button"
            onClick={() => setOpen(true)}
            className="inline-flex items-center gap-1.5 text-[10px] font-bold tracking-[0.08em] text-gold uppercase hover:text-navy"
          >
            <Plus className="size-3" />
            New order
          </button>
        }
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
                            {order.id}
                          </p>
                          <p className="mt-1 text-[10px] text-muted-foreground">
                            {order.source}
                            {order.guest ? ` · ${order.guest}` : ""}
                          </p>
                        </div>
                        <span className="inline-flex items-center gap-1 text-[9px] text-muted-foreground">
                          <Clock className="size-2.5" />
                          {order.placedAt}
                        </span>
                      </div>

                      <div className="mt-2.5 space-y-1">
                        {order.items.map((item) => (
                          <div
                            key={`${order.id}-${item.name}`}
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

                      {order.note && (
                        <p className="mt-2 rounded-md bg-gold/10 px-2 py-1.5 text-[9px] leading-4 text-[#8a6b32]">
                          {order.note}
                        </p>
                      )}

                      <div className="mt-2 flex items-center justify-between text-[9px]">
                        <span className="text-muted-foreground">
                          {ORDER_STATUS_LABEL[order.status]}
                        </span>
                        <span className="font-semibold text-navy">
                          {formatNaira(order.total)}
                        </span>
                      </div>

                      <div className="mt-2.5">
                        {order.status === "new" && (
                          <button
                            type="button"
                            onClick={() => handleAdvance(order.id, "new")}
                            className="inline-flex h-7 w-full items-center justify-center gap-1 rounded-full bg-navy text-[9px] font-semibold text-white hover:bg-navy-800"
                          >
                            <Martini className="size-3" />
                            Accept order
                          </button>
                        )}
                        {order.status === "preparing" && (
                          <button
                            type="button"
                            onClick={() => handleAdvance(order.id, "preparing")}
                            className="inline-flex h-7 w-full items-center justify-center gap-1 rounded-full bg-gold text-[9px] font-semibold text-navy hover:bg-gold-soft"
                          >
                            <Check className="size-3" />
                            Mark ready
                          </button>
                        )}
                        {order.status === "ready" && (
                          <div className="flex h-7 items-center justify-center gap-1 rounded-full bg-emerald-50 text-[9px] font-semibold text-emerald-700">
                            <Sparkles className="size-3" />
                            Awaiting waiter
                          </div>
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
                      icon={column.key === "delivered" ? Check : Martini}
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

      <div className="grid gap-5 lg:grid-cols-[1.1fr_1fr]">
        <SectionCard title="Bar stock cues" description="Below reorder point">
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
                All bar stock is above reorder point.
              </p>
            )}
          </div>
          <div className="mt-4 flex items-start gap-2 rounded-lg bg-gold/10 px-3 py-2.5 text-[10px] leading-5 text-[#8a6b32]">
            <CircleAlert className="mt-0.5 size-3.5 shrink-0" />
            The quick-order flow adds a ticket to the bar queue. Stock is deducted
            only when the waiter delivers it.
          </div>
        </SectionCard>

        <SectionCard title="Bar notes" description="Service cues">
          <div className="space-y-3">
            <div className="rounded-xl bg-ivory p-3">
              <p className="text-xs font-semibold text-navy">Sparkling water · low</p>
              <p className="mt-1 text-[10px] leading-5 text-muted-foreground">
                Four bottles left. Move two from the store before the evening
                service.
              </p>
            </div>
            <div className="rounded-xl bg-gold/10 p-3">
              <p className="text-xs font-semibold text-navy">VIP welcome · Penthouse</p>
              <p className="mt-1 text-[10px] leading-5 text-muted-foreground">
                Chilled sparkling water and two glasses on arrival. Charge to the
                room folio.
              </p>
            </div>
            <div className="rounded-xl bg-emerald-50 p-3">
              <p className="text-xs font-semibold text-navy">Bar snack pairing</p>
              <p className="mt-1 text-[10px] leading-5 text-muted-foreground">
                Suggest suya skewers with the Aurelia Sunset. Kitchen has stock.
              </p>
            </div>
          </div>
        </SectionCard>
      </div>

      <Modal
        open={open}
        onClose={() => setOpen(false)}
        title="Quick bar order"
        description="Add a drink to an in-house room. The ticket lands in the New column."
        footer={
          <>
            <button
              type="button"
              onClick={() => setOpen(false)}
              className="h-10 rounded-full border border-border px-5 text-xs font-semibold text-navy hover:border-gold"
            >
              Cancel
            </button>
            <button
              type="button"
              onClick={handleCreate}
              className="h-10 rounded-full bg-gold px-5 text-xs font-semibold text-navy hover:bg-gold-soft"
            >
              Create order · {formatNaira(orderTotal)}
            </button>
          </>
        }
      >
        <div className="grid gap-4 sm:grid-cols-2">
          <label className="flex flex-col gap-2">
            <span className="field-label">Room</span>
            <select
              value={roomNumber}
              onChange={(event) => setRoomNumber(event.target.value)}
              className="input-luxe appearance-none"
            >
              <option value="">Select an in-house room</option>
              {inHouse.map((reservation) => (
                <option key={reservation.id} value={reservation.roomNumber}>
                  Room {reservation.roomNumber} · {reservation.guest}
                </option>
              ))}
            </select>
          </label>
          <label className="flex flex-col gap-2">
            <span className="field-label">Drink</span>
            <select
              value={itemId}
              onChange={(event) => setItemId(event.target.value)}
              className="input-luxe appearance-none"
            >
              {BAR_ITEMS.map((item) => (
                <option key={item.id} value={item.id}>
                  {item.name} · {formatNaira(item.price)}
                </option>
              ))}
            </select>
          </label>
        </div>

        <div className="mt-4 grid gap-4 sm:grid-cols-[120px_1fr]">
          <label className="flex flex-col gap-2">
            <span className="field-label">Quantity</span>
            <input
              type="number"
              min={1}
              value={qty}
              onChange={(event) => setQty(event.target.value)}
              className="input-luxe"
            />
          </label>
          <label className="flex flex-col gap-2">
            <span className="field-label">Note (optional)</span>
            <input
              value={note}
              onChange={(event) => setNote(event.target.value)}
              placeholder="No ice, charge to room, etc."
              className="input-luxe"
            />
          </label>
        </div>

        <div className="mt-4 flex items-center justify-between rounded-xl bg-ivory p-4">
          <div>
            <p className="field-label">Order total</p>
            <p className="mt-1 font-heading text-3xl text-navy">
              {formatNaira(orderTotal)}
            </p>
          </div>
          <div className="text-right text-[10px] text-muted-foreground">
            <p>{selectedGuest ? selectedGuest.guest : "Select a room"}</p>
            <p>{selectedItem.name}</p>
          </div>
        </div>

        <p className="mt-3 flex items-center gap-1.5 text-[10px] text-muted-foreground">
          <Wine className="size-3.5 text-gold" />
          Charge posts to the room folio. Stock deducts once on delivery.
        </p>
      </Modal>
    </div>
  );
}
