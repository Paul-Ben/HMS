"use client";

import { useState } from "react";
import { toast } from "sonner";
import { Check, Landmark, X } from "lucide-react";
import { formatNaira } from "@/lib/format";
import type { Payment } from "@/lib/prototype-data";
import { DetailRow, Modal, StatusPill } from "@/components/dashboard/dashboard-ui";
import { usePrototype } from "@/components/dashboard/prototype-provider";

export function TransferReviewDialog({
  payment,
  onClose,
}: {
  payment: Payment | null;
  onClose: () => void;
}) {
  const { verifyPayment } = usePrototype();
  const [note, setNote] = useState("");

  if (!payment) return null;
  const paymentId = payment.id;

  function decide(approve: boolean) {
    verifyPayment(paymentId, approve, note.trim() || undefined);
    toast.success(
      approve ? "Transfer verified and applied to the folio." : "Transfer rejected.",
    );
    setNote("");
    onClose();
  }

  return (
    <Modal
      open={Boolean(payment)}
      onClose={onClose}
      title="Review bank transfer"
      description="Verify the credit before applying it to the guest folio."
      footer={
        <>
          <button
            type="button"
            onClick={() => decide(false)}
            className="inline-flex h-10 items-center gap-2 rounded-full border border-red-200 bg-white px-5 text-xs font-semibold text-red-600 transition-colors hover:bg-red-50"
          >
            <X className="size-3.5" />
            Reject
          </button>
          <button
            type="button"
            onClick={() => decide(true)}
            className="inline-flex h-10 items-center gap-2 rounded-full bg-emerald-600 px-5 text-xs font-semibold text-white transition-colors hover:bg-emerald-700"
          >
            <Check className="size-3.5" />
            Verify &amp; apply
          </button>
        </>
      }
    >
      <div className="flex items-center justify-between gap-4 rounded-xl bg-ivory p-4">
        <div className="flex items-center gap-3">
          <span className="flex size-10 items-center justify-center rounded-full bg-white text-gold ring-1 ring-border">
            <Landmark className="size-4" />
          </span>
          <div>
            <p className="text-sm font-semibold text-navy">{payment.guest}</p>
            <p className="text-[11px] text-muted-foreground">
              Room {payment.roomNumber} · {payment.reference}
            </p>
          </div>
        </div>
        <StatusPill label="Pending" tone="gold" />
      </div>

      <div className="mt-4 divide-y divide-border/70">
        <DetailRow label="Amount" value={formatNaira(payment.amount)} strong />
        <DetailRow label="Method" value={payment.method} />
        <DetailRow label="Submitted by" value={payment.receivedBy} />
        <DetailRow label="Received" value={payment.date} />
      </div>

      <label className="mt-4 flex flex-col gap-2">
        <span className="field-label">Verification note</span>
        <textarea
          value={note}
          onChange={(event) => setNote(event.target.value)}
          rows={3}
          placeholder="Reference, bank narration or reason for rejection."
          className="w-full rounded-xl border border-input bg-white px-3.5 py-3 text-sm outline-none transition placeholder:text-muted-foreground/70 focus-visible:border-gold focus-visible:ring-3 focus-visible:ring-gold/20"
        />
      </label>

      <p className="mt-3 rounded-lg bg-gold/10 px-3 py-2 text-[10px] leading-5 text-[#8a6b32]">
        Segregation of duties: the person who submitted this transfer cannot
        verify it in production.
      </p>
    </Modal>
  );
}
