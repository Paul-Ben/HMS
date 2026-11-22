"use client";

import { useState } from "react";
import { toast } from "sonner";
import {
  ArrowRight,
  Banknote,
  Check,
  CheckCircle2,
  CreditCard,
  Landmark,
  ReceiptText,
  ShieldCheck,
  Wallet,
} from "lucide-react";
import { formatNaira } from "@/lib/format";
import type { Payment } from "@/lib/prototype-data";
import {
  PageHeader,
  SectionCard,
  StatCard,
  StatusPill,
} from "@/components/dashboard/dashboard-ui";
import { usePrototype } from "@/components/dashboard/prototype-provider";
import { TransferReviewDialog } from "@/components/dashboard/transfer-review-dialog";

export function AccountsDashboard() {
  const {
    payments,
    reservations,
    expenses,
    approveExpense,
    payExpense,
  } = usePrototype();
  const [reviewPayment, setReviewPayment] = useState<Payment | null>(null);

  const completed = payments.filter((payment) => payment.status === "Completed");
  const pendingTransfers = payments.filter((payment) => payment.status === "Pending");
  const collected = completed.reduce((sum, payment) => sum + payment.amount, 0);
  const pendingValue = pendingTransfers.reduce(
    (sum, payment) => sum + payment.amount,
    0,
  );
  const outstanding = reservations
    .filter((reservation) => reservation.status !== "departed")
    .reduce((sum, reservation) => sum + reservation.balance, 0);
  const openFolios = reservations.filter(
    (reservation) => reservation.balance > 0 && reservation.status !== "departed",
  );
  const pendingExpenses = expenses.filter((expense) => expense.status === "Pending");
  const approvedExpenses = expenses.filter((expense) => expense.status === "Approved");

  function handleExpense(expenseId: string, action: "approve" | "pay") {
    const expense = expenses.find((item) => item.id === expenseId);
    if (!expense) return;
    if (action === "approve") {
      approveExpense(expenseId);
      toast.success(`Expense approved · ${expense.vendor}.`);
    } else {
      payExpense(expenseId);
      toast.success(`Expense marked paid · ${expense.vendor}.`);
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        eyebrow="Finance desk"
        title="Clean books, clear balances."
        description="Verify transfers, reconcile daily collections and keep the folio ledger honest. Every approval is recorded."
        badge={<StatusPill label="Accounts · Bola Ajayi" tone="green" />}
        actions={
          <div className="inline-flex items-center gap-2 rounded-full border border-border bg-white px-4 py-2 text-[11px] font-semibold text-navy">
            <ShieldCheck className="size-3.5 text-gold" />
            Segregation of duties enforced
          </div>
        }
      />

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard
          label="Collected to date"
          value={formatNaira(collected)}
          detail={`${completed.length} completed payments`}
          icon={Wallet}
          tone="navy"
        />
        <StatCard
          label="Pending transfers"
          value={formatNaira(pendingValue)}
          detail={`${pendingTransfers.length} awaiting verification`}
          icon={Landmark}
          tone="gold"
        />
        <StatCard
          label="Guest receivables"
          value={formatNaira(outstanding)}
          detail={`${openFolios.length} folios with a balance`}
          icon={ReceiptText}
          tone="red"
        />
        <StatCard
          label="Expenses to review"
          value={String(pendingExpenses.length)}
          detail={formatNaira(pendingExpenses.reduce((sum, expense) => sum + expense.amount, 0))}
          icon={Banknote}
          tone="blue"
        />
      </div>

      <div className="grid gap-5 xl:grid-cols-[1.35fr_0.8fr]">
        <SectionCard
          title="Pending bank transfers"
          description="Verify the credit before it reaches the guest folio."
          action={
            <span className="text-[10px] font-semibold text-muted-foreground">
              {pendingTransfers.length} in queue
            </span>
          }
          bodyClassName="p-0"
        >
          <div className="overflow-x-auto">
            <table className="table-clean w-full min-w-[620px]">
              <thead>
                <tr className="border-b border-border/70 text-left">
                  <th className="px-5 py-2.5 text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                    Guest
                  </th>
                  <th className="px-3 py-2.5 text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                    Reference
                  </th>
                  <th className="px-3 py-2.5 text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                    Submitted by
                  </th>
                  <th className="px-3 py-2.5 text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                    Amount
                  </th>
                  <th className="px-5 py-2.5 text-right text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                    Action
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border/60">
                {pendingTransfers.map((payment) => (
                  <tr key={payment.id} className="hover:bg-ivory/40">
                    <td className="px-5 py-3">
                      <p className="text-xs font-semibold text-navy">{payment.guest}</p>
                      <p className="text-[9px] text-muted-foreground">
                        Room {payment.roomNumber} · {payment.date}
                      </p>
                    </td>
                    <td className="px-3 py-3 text-[10px] text-navy">
                      {payment.reference}
                    </td>
                    <td className="px-3 py-3 text-[10px] text-muted-foreground">
                      {payment.receivedBy}
                    </td>
                    <td className="px-3 py-3 text-xs font-semibold text-navy">
                      {formatNaira(payment.amount)}
                    </td>
                    <td className="px-5 py-3 text-right">
                      <button
                        type="button"
                        onClick={() => setReviewPayment(payment)}
                        className="inline-flex h-8 items-center gap-1 rounded-full bg-navy px-3.5 text-[10px] font-semibold text-white transition-colors hover:bg-navy-800"
                      >
                        Review
                        <ArrowRight className="size-3" />
                      </button>
                    </td>
                  </tr>
                ))}
                {pendingTransfers.length === 0 && (
                  <tr>
                    <td colSpan={5} className="px-5 py-10 text-center">
                      <CheckCircle2 className="mx-auto size-5 text-emerald-500" />
                      <p className="mt-2 text-xs font-semibold text-navy">
                        No transfers waiting
                      </p>
                      <p className="mt-1 text-[10px] text-muted-foreground">
                        All submitted transfers have been reviewed.
                      </p>
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </SectionCard>

        <SectionCard title="Reconciliation" description="Settled by method">
          <div className="space-y-3.5">
            {(Object.keys(
              completed.reduce<Record<string, number>>((accumulator, payment) => {
                accumulator[payment.method] =
                  (accumulator[payment.method] ?? 0) + payment.amount;
                return accumulator;
              }, {}),
            ) as Payment["method"][]).map((method) => {
              const amount = completed
                .filter((payment) => payment.method === method)
                .reduce((sum, payment) => sum + payment.amount, 0);
              return (
                <div key={method} className="flex items-center justify-between">
                  <span className="flex items-center gap-2 text-[11px] text-muted-foreground">
                    {method === "Bank transfer" ? (
                      <Landmark className="size-3.5 text-gold" />
                    ) : method === "Cash" ? (
                      <Banknote className="size-3.5 text-emerald-600" />
                    ) : (
                      <CreditCard className="size-3.5 text-sky-600" />
                    )}
                    {method}
                  </span>
                  <span className="text-[11px] font-semibold text-navy">
                    {formatNaira(amount)}
                  </span>
                </div>
              );
            })}
          </div>
          <div className="mt-4 rounded-xl bg-ivory p-4">
            <div className="flex items-center justify-between text-[11px]">
              <span className="text-muted-foreground">Total settled</span>
              <span className="font-heading text-xl text-navy">{formatNaira(collected)}</span>
            </div>
            <div className="mt-2 flex items-center justify-between text-[10px]">
              <span className="text-muted-foreground">Pending verification</span>
              <span className="font-semibold text-[#8a6b32]">{formatNaira(pendingValue)}</span>
            </div>
          </div>
          <div className="mt-3 flex items-start gap-2 rounded-lg bg-emerald-50 px-3 py-2.5 text-[10px] leading-5 text-emerald-700">
            <ShieldCheck className="mt-0.5 size-3.5 shrink-0" />
            Submitter and verifier are different users in production. The
            prototype demonstrates the workflow, not the enforcement.
          </div>
        </SectionCard>
      </div>

      <div className="grid gap-5 xl:grid-cols-[1.3fr_0.85fr]">
        <SectionCard
          title="Payment ledger"
          description="All recorded payments for the review day"
          action={
            <span className="text-[10px] font-semibold text-muted-foreground">
              {payments.length} entries
            </span>
          }
          bodyClassName="p-0"
        >
          <div className="max-h-[420px] overflow-auto">
            <table className="table-clean w-full min-w-[640px]">
              <thead className="sticky top-0 bg-white">
                <tr className="border-b border-border/70 text-left">
                  <th className="px-5 py-2.5 text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                    Guest
                  </th>
                  <th className="px-3 py-2.5 text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                    Method
                  </th>
                  <th className="px-3 py-2.5 text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                    Reference
                  </th>
                  <th className="px-3 py-2.5 text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                    Received by
                  </th>
                  <th className="px-3 py-2.5 text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                    Status
                  </th>
                  <th className="px-5 py-2.5 text-right text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                    Amount
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border/60">
                {payments.map((payment) => (
                  <tr key={payment.id} className="hover:bg-ivory/40">
                    <td className="px-5 py-2.5">
                      <p className="text-[11px] font-semibold text-navy">{payment.guest}</p>
                      <p className="text-[9px] text-muted-foreground">
                        Room {payment.roomNumber} · {payment.date}
                      </p>
                    </td>
                    <td className="px-3 py-2.5 text-[10px] text-navy">{payment.method}</td>
                    <td className="px-3 py-2.5 text-[9px] text-muted-foreground">
                      {payment.reference}
                    </td>
                    <td className="px-3 py-2.5 text-[9px] text-muted-foreground">
                      {payment.receivedBy}
                    </td>
                    <td className="px-3 py-2.5">
                      <StatusPill
                        label={payment.status}
                        tone={
                          payment.status === "Completed"
                            ? "green"
                            : payment.status === "Pending"
                              ? "gold"
                              : "red"
                        }
                      />
                    </td>
                    <td className="px-5 py-2.5 text-right text-[11px] font-semibold text-navy">
                      {formatNaira(payment.amount)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </SectionCard>

        <SectionCard
          title="Guest receivables"
          description="Open folios with a balance"
          bodyClassName="p-0"
        >
          <div className="divide-y divide-border/60">
            {openFolios.map((reservation) => (
              <div key={reservation.id} className="flex items-center gap-3 px-5 py-3">
                <div className="min-w-0 flex-1">
                  <p className="truncate text-[11px] font-semibold text-navy">
                    {reservation.guest}
                  </p>
                  <p className="text-[9px] text-muted-foreground">
                    Room {reservation.roomNumber} · {reservation.nights} nights
                  </p>
                </div>
                <div className="text-right">
                  <p className="text-[11px] font-semibold text-navy">
                    {formatNaira(reservation.balance)}
                  </p>
                  <StatusPill
                    label={reservation.status === "arriving" ? "Arriving" : "In house"}
                    tone={reservation.status === "arriving" ? "gold" : "green"}
                  />
                </div>
              </div>
            ))}
          </div>
        </SectionCard>
      </div>

      <SectionCard
        title="Expenses"
        description="Approve submitted expenses and mark approved items as paid."
        bodyClassName="p-0"
      >
        <div className="overflow-x-auto">
          <table className="table-clean w-full min-w-[760px]">
            <thead>
              <tr className="border-b border-border/70 text-left">
                <th className="px-5 py-2.5 text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                  Vendor
                </th>
                <th className="px-3 py-2.5 text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                  Category
                </th>
                <th className="px-3 py-2.5 text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                  Submitted by
                </th>
                <th className="px-3 py-2.5 text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                  Date
                </th>
                <th className="px-3 py-2.5 text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                  Status
                </th>
                <th className="px-3 py-2.5 text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                  Amount
                </th>
                <th className="px-5 py-2.5 text-right text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                  Action
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border/60">
              {expenses.map((expense) => (
                <tr key={expense.id} className="hover:bg-ivory/40">
                  <td className="px-5 py-3">
                    <p className="text-xs font-semibold text-navy">{expense.vendor}</p>
                    <p className="text-[9px] text-muted-foreground">{expense.id}</p>
                  </td>
                  <td className="px-3 py-3 text-[10px] text-muted-foreground">
                    {expense.category}
                  </td>
                  <td className="px-3 py-3 text-[10px] text-muted-foreground">
                    {expense.submittedBy}
                  </td>
                  <td className="px-3 py-3 text-[10px] text-muted-foreground">
                    {expense.date}
                  </td>
                  <td className="px-3 py-3">
                    <StatusPill
                      label={expense.status}
                      tone={
                        expense.status === "Pending"
                          ? "gold"
                          : expense.status === "Approved"
                            ? "blue"
                            : "green"
                      }
                    />
                  </td>
                  <td className="px-3 py-3 text-xs font-semibold text-navy">
                    {formatNaira(expense.amount)}
                  </td>
                  <td className="px-5 py-3 text-right">
                    {expense.status === "Pending" && (
                      <button
                        type="button"
                        onClick={() => handleExpense(expense.id, "approve")}
                        className="inline-flex h-8 items-center gap-1 rounded-full bg-navy px-3.5 text-[10px] font-semibold text-white hover:bg-navy-800"
                      >
                        <Check className="size-3" />
                        Approve
                      </button>
                    )}
                    {expense.status === "Approved" && (
                      <button
                        type="button"
                        onClick={() => handleExpense(expense.id, "pay")}
                        className="inline-flex h-8 items-center gap-1 rounded-full bg-gold px-3.5 text-[10px] font-semibold text-navy hover:bg-gold-soft"
                      >
                        Mark paid
                      </button>
                    )}
                    {expense.status === "Paid" && (
                      <span className="text-[9px] text-muted-foreground">Settled</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        {approvedExpenses.length > 0 && (
          <div className="border-t border-border/70 bg-ivory/40 px-5 py-3 text-[10px] text-muted-foreground">
            {approvedExpenses.length} approved expense
            {approvedExpenses.length === 1 ? "" : "s"} ready for payment.
          </div>
        )}
      </SectionCard>

      <TransferReviewDialog
        payment={reviewPayment}
        onClose={() => setReviewPayment(null)}
      />
    </div>
  );
}
