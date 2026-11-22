"use client";

import { useState } from "react";
import { toast } from "sonner";
import {
  ArrowDownUp,
  ArrowRight,
  Boxes,
  CircleAlert,
  Package,
  PackageOpen,
  Plus,
  TrendingDown,
} from "lucide-react";
import { formatNaira } from "@/lib/format";
import type { InventoryItem } from "@/lib/prototype-data";
import {
  Modal,
  PageHeader,
  ProgressBar,
  SectionCard,
  StatCard,
  StatusPill,
} from "@/components/dashboard/dashboard-ui";
import { usePrototype } from "@/components/dashboard/prototype-provider";

function statusFor(item: InventoryItem) {
  if (item.stock < item.reorder) {
    return { label: "Low", tone: "red" as const };
  }
  if (item.stock < item.reorder * 1.25) {
    return { label: "Watch", tone: "gold" as const };
  }
  return { label: "Healthy", tone: "green" as const };
}

export function InventoryDashboard() {
  const { inventory, orders, adjustStock } = usePrototype();
  const [open, setOpen] = useState(false);
  const [selectedId, setSelectedId] = useState(inventory[0]?.id ?? "");
  const [mode, setMode] = useState<"receive" | "issue">("receive");
  const [qty, setQty] = useState("1");
  const [note, setNote] = useState("");

  const selected = inventory.find((item) => item.id === selectedId) ?? inventory[0];
  const quantity = Math.max(0, Number(qty) || 0);
  const projected = selected
    ? Math.max(
        0,
        Number(
          (selected.stock + (mode === "receive" ? quantity : -quantity)).toFixed(2),
        ),
      )
    : 0;
  const lowStock = inventory.filter((item) => item.stock < item.reorder);
  const totalValue = inventory.reduce(
    (sum, item) => sum + item.stock * item.cost,
    0,
  );
  const categories = Array.from(new Set(inventory.map((item) => item.category)));
  const delivered = orders.filter(
    (order) => order.status === "delivered" && order.stockDeducted,
  );

  function openAdjust(itemId?: string) {
    setSelectedId(itemId ?? inventory[0]?.id ?? "");
    setMode("receive");
    setQty("1");
    setNote("");
    setOpen(true);
  }

  function handleAdjust() {
    if (!selected) return;
    if (quantity <= 0) {
      toast.error("Enter a quantity greater than zero.");
      return;
    }
    adjustStock(selected.id, mode === "receive" ? quantity : -quantity);
    toast.success(
      `${selected.name} updated to ${projected} ${selected.unit}.`,
    );
    setOpen(false);
  }

  return (
    <div className="space-y-6">
      <PageHeader
        eyebrow="Stores & stock"
        title="Know what is on the shelf."
        description="Track stock across the bar, kitchen, housekeeping and laundry. Low-stock items surface before service is affected."
        badge={<StatusPill label="Stores · Ngozi Peters" tone="green" />}
        actions={
          <button
            type="button"
            onClick={() => openAdjust()}
            className="inline-flex h-9 items-center gap-2 rounded-full bg-navy px-4 text-[11px] font-semibold text-white transition-colors hover:bg-navy-800"
          >
            <Plus className="size-3.5" />
            Receive stock
          </button>
        }
      />

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard
          label="Active SKUs"
          value={String(inventory.length)}
          detail={`${categories.length} categories`}
          icon={Boxes}
          tone="navy"
        />
        <StatCard
          label="Below reorder"
          value={String(lowStock.length)}
          detail="Ready to raise a purchase order"
          icon={CircleAlert}
          tone="red"
        />
        <StatCard
          label="Stock value"
          value={formatNaira(totalValue)}
          detail="At latest unit cost"
          icon={Package}
          tone="gold"
        />
        <StatCard
          label="Delivered movements"
          value={String(delivered.length)}
          detail="Auto-deducted from orders"
          icon={ArrowDownUp}
          tone="blue"
        />
      </div>

      {lowStock.length > 0 && (
        <div className="flex flex-col gap-3 rounded-2xl border border-red-200 bg-red-50 p-4 sm:flex-row sm:items-center sm:justify-between">
          <div className="flex items-start gap-3">
            <span className="flex size-9 shrink-0 items-center justify-center rounded-full bg-white text-red-500 ring-1 ring-red-200">
              <TrendingDown className="size-4" />
            </span>
            <div>
              <p className="text-sm font-semibold text-navy">
                {lowStock.length} items need attention
              </p>
              <p className="mt-0.5 text-[10px] leading-5 text-muted-foreground">
                {lowStock.map((item) => `${item.name} (${item.stock} ${item.unit})`).join(" · ")}
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={() => openAdjust(lowStock[0]?.id)}
            className="inline-flex h-9 shrink-0 items-center gap-1.5 rounded-full bg-white px-4 text-[10px] font-semibold text-red-600 ring-1 ring-red-200 hover:bg-red-100"
          >
            Receive stock
            <ArrowRight className="size-3" />
          </button>
        </div>
      )}

      <SectionCard
        title="Stock ledger"
        description="On-hand quantities, reorder points and valuation."
        action={
          <span className="text-[10px] font-semibold text-muted-foreground">
            {formatNaira(totalValue)} total
          </span>
        }
        bodyClassName="p-0"
      >
        <div className="overflow-x-auto">
          <table className="table-clean w-full min-w-[880px]">
            <thead>
              <tr className="border-b border-border/70 text-left">
                <th className="px-5 py-2.5 text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                  Item
                </th>
                <th className="px-3 py-2.5 text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                  Category
                </th>
                <th className="px-3 py-2.5 text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                  Location
                </th>
                <th className="px-3 py-2.5 text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                  On hand
                </th>
                <th className="px-3 py-2.5 text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                  Reorder
                </th>
                <th className="px-3 py-2.5 text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                  Unit cost
                </th>
                <th className="px-3 py-2.5 text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                  Status
                </th>
                <th className="px-3 py-2.5 text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                  Value
                </th>
                <th className="px-5 py-2.5 text-right text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                  Adjust
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border/60">
              {inventory.map((item) => {
                const status = statusFor(item);
                return (
                  <tr key={item.id} className="hover:bg-ivory/40">
                    <td className="px-5 py-2.5">
                      <p className="text-[11px] font-semibold text-navy">{item.name}</p>
                      <p className="text-[9px] text-muted-foreground">{item.id}</p>
                    </td>
                    <td className="px-3 py-2.5 text-[10px] text-muted-foreground">
                      {item.category}
                    </td>
                    <td className="px-3 py-2.5 text-[10px] text-muted-foreground">
                      {item.location}
                    </td>
                    <td className="px-3 py-2.5">
                      <p className="text-[11px] font-semibold text-navy">
                        {item.stock} {item.unit}
                      </p>
                      <ProgressBar
                        value={(item.stock / Math.max(item.reorder * 2, 1)) * 100}
                        tone={status.tone === "red" ? "red" : status.tone === "gold" ? "gold" : "green"}
                        className="mt-1 w-20"
                      />
                    </td>
                    <td className="px-3 py-2.5 text-[10px] text-muted-foreground">
                      {item.reorder} {item.unit}
                    </td>
                    <td className="px-3 py-2.5 text-[10px] text-muted-foreground">
                      {formatNaira(item.cost)}
                    </td>
                    <td className="px-3 py-2.5">
                      <StatusPill label={status.label} tone={status.tone} />
                    </td>
                    <td className="px-3 py-2.5 text-[11px] font-semibold text-navy">
                      {formatNaira(item.stock * item.cost)}
                    </td>
                    <td className="px-5 py-2.5 text-right">
                      <button
                        type="button"
                        onClick={() => openAdjust(item.id)}
                        className="inline-flex h-7 items-center gap-1 rounded-full border border-border px-2.5 text-[9px] font-semibold text-navy hover:border-gold"
                      >
                        <ArrowDownUp className="size-2.5" />
                        Adjust
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </SectionCard>

      <div className="grid gap-5 lg:grid-cols-[1.2fr_1fr]">
        <SectionCard
          title="Recent stock movements"
          description="Deductions posted automatically from delivered orders"
          bodyClassName="p-0"
        >
          <div className="divide-y divide-border/60">
            {delivered.slice(0, 8).map((order) => (
              <div key={order.id} className="flex items-start gap-3 px-5 py-3">
                <span className="flex size-8 shrink-0 items-center justify-center rounded-full bg-ivory text-gold">
                  <PackageOpen className="size-3.5" />
                </span>
                <div className="min-w-0 flex-1">
                  <p className="text-[11px] font-semibold text-navy">
                    {order.id} · {order.source}
                  </p>
                  <p className="mt-0.5 text-[9px] leading-4 text-muted-foreground">
                    {order.items
                      .filter((item) => item.stockId)
                      .map((item) => `${item.name} ×${item.qty}`)
                      .join(" · ") || "No stock items"}
                  </p>
                </div>
                <div className="text-right">
                  <p className="text-[11px] font-semibold text-navy">
                    {formatNaira(order.total)}
                  </p>
                  <p className="text-[8px] text-muted-foreground">Deducted once</p>
                </div>
              </div>
            ))}
            {delivered.length === 0 && (
              <p className="px-5 py-8 text-center text-xs text-muted-foreground">
                No delivered orders have posted stock movements yet.
              </p>
            )}
          </div>
        </SectionCard>

        <SectionCard title="Stock rules" description="How the prototype behaves">
          <div className="space-y-3">
            {[
              "Kitchen and bar stock deducts when the waiter confirms delivery.",
              "Laundry detergent deducts when a laundry order is delivered.",
              "Low stock triggers when the quantity falls below the reorder point.",
              "Stock value uses the latest unit cost, not a weighted average.",
              "Housekeeping linen is issued manually from this page.",
            ].map((rule) => (
              <div key={rule} className="flex items-start gap-2.5 text-[10px] leading-5 text-muted-foreground">
                <span className="mt-1.5 size-1.5 shrink-0 rounded-full bg-gold" />
                {rule}
              </div>
            ))}
          </div>
          <div className="mt-4 rounded-xl bg-ivory p-4">
            <div className="flex items-center justify-between text-[10px]">
              <span className="text-muted-foreground">Categories tracked</span>
              <span className="font-semibold text-navy">{categories.join(" · ")}</span>
            </div>
          </div>
        </SectionCard>
      </div>

      <Modal
        open={open}
        onClose={() => setOpen(false)}
        title="Adjust stock"
        description="Record a receipt or an issue. The ledger updates immediately."
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
              onClick={handleAdjust}
              className="h-10 rounded-full bg-gold px-5 text-xs font-semibold text-navy hover:bg-gold-soft"
            >
              Save adjustment
            </button>
          </>
        }
      >
        <div className="grid gap-4 sm:grid-cols-2">
          <label className="flex flex-col gap-2">
            <span className="field-label">Item</span>
            <select
              value={selectedId}
              onChange={(event) => setSelectedId(event.target.value)}
              className="input-luxe appearance-none"
            >
              {inventory.map((item) => (
                <option key={item.id} value={item.id}>
                  {item.name} · {item.stock} {item.unit}
                </option>
              ))}
            </select>
          </label>
          <label className="flex flex-col gap-2">
            <span className="field-label">Movement</span>
            <select
              value={mode}
              onChange={(event) => setMode(event.target.value as "receive" | "issue")}
              className="input-luxe appearance-none"
            >
              <option value="receive">Receive stock</option>
              <option value="issue">Issue stock</option>
            </select>
          </label>
        </div>

        <div className="mt-4 grid gap-4 sm:grid-cols-2">
          <label className="flex flex-col gap-2">
            <span className="field-label">Quantity</span>
            <input
              type="number"
              min={0.01}
              step="0.01"
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
              placeholder="Supplier, invoice or reason"
              className="input-luxe"
            />
          </label>
        </div>

        {selected && (
          <div className="mt-4 rounded-xl bg-ivory p-4">
            <div className="flex items-center justify-between text-[11px]">
              <span className="text-muted-foreground">Current</span>
              <span className="font-semibold text-navy">
                {selected.stock} {selected.unit}
              </span>
            </div>
            <div className="mt-1.5 flex items-center justify-between text-[11px]">
              <span className="text-muted-foreground">After movement</span>
              <span className="font-heading text-xl text-navy">
                {projected} {selected.unit}
              </span>
            </div>
            <div className="mt-2">
              <ProgressBar
                value={(projected / Math.max(selected.reorder * 2, 1)) * 100}
                tone={projected < selected.reorder ? "red" : "green"}
              />
            </div>
            <p className="mt-2 text-[9px] text-muted-foreground">
              Reorder at {selected.reorder} {selected.unit}.{" "}
              {note ? `Note: ${note}` : "No note added."}
            </p>
          </div>
        )}
      </Modal>
    </div>
  );
}
