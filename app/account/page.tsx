"use client";

import { useMemo, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { toast } from "sonner";
import {
  ArrowRight,
  CalendarDays,
  Check,
  Clock,
  ConciergeBell,
  CreditCard,
  Download,
  Lock,
  MapPin,
  Sparkles,
  Users,
  Wifi,
  X,
} from "lucide-react";
import { formatNaira, formatStayDate } from "@/lib/format";
import { CATEGORY_BY_SLUG } from "@/lib/prototype-data";

const STAY = {
  reference: "AUR-2026-1042",
  room: "401",
  categorySlug: "premier-suite",
  checkIn: "2026-11-20",
  checkOut: "2026-11-23",
  nights: 3,
  guests: 2,
  total: 495000,
  deposit: 148500,
};

const INITIAL_PAYMENTS = [
  {
    id: "PAY-1001",
    date: "12 Nov 2026",
    method: "Paystack · card ending 4242",
    amount: 148500,
    status: "Completed",
  },
];

const FOLIO_ITEMS = [
  { label: "Premier Suite · 3 nights", detail: "₦165,000 per night", amount: 495000 },
  { label: "Breakfast for two", detail: "Included in rate", amount: 0 },
  { label: "Welcome drink", detail: "Book direct benefit", amount: 0 },
];

export default function GuestPortalPage() {
  const [payments, setPayments] = useState(INITIAL_PAYMENTS);
  const [paid, setPaid] = useState(STAY.deposit);
  const [payOpen, setPayOpen] = useState(false);
  const [processing, setProcessing] = useState(false);

  const category = CATEGORY_BY_SLUG[STAY.categorySlug];
  const balance = useMemo(() => Math.max(STAY.total - paid, 0), [paid]);

  function handlePay() {
    setProcessing(true);
    setTimeout(() => {
      setPaid((current) => current + balance);
      setPayments((current) => [
        {
          id: `PAY-${1100 + current.length}`,
          date: "20 Nov 2026",
          method: "Paystack · card ending 4242",
          amount: balance,
          status: "Completed",
        },
        ...current,
      ]);
      setProcessing(false);
      setPayOpen(false);
      toast.success("Payment received. Your folio is settled.");
    }, 1200);
  }

  return (
    <div className="container-page py-10 lg:py-14">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <p className="eyebrow">Guest portal</p>
          <h1 className="mt-2 font-heading text-4xl text-navy sm:text-5xl">
            Welcome back, Adaeze.
          </h1>
          <p className="mt-2 text-sm text-muted-foreground">
            Everything for your stay in one place.
          </p>
        </div>
        <span className="inline-flex w-fit items-center gap-2 rounded-full bg-sage/15 px-4 py-2 text-xs font-semibold text-[#4f6b4a] ring-1 ring-sage/25">
          <span className="size-1.5 rounded-full bg-sage" />
          Arriving today
        </span>
      </div>

      <div className="mt-8 grid gap-6 lg:grid-cols-[1.45fr_0.75fr]">
        <div className="space-y-6">
          <section className="surface-card overflow-hidden">
            <div className="relative h-56 sm:h-64">
              <Image
                src={category.image}
                alt={category.name}
                fill
                sizes="(min-width: 1024px) 65vw, 100vw"
                className="object-cover"
                priority
              />
              <div className="absolute inset-0 bg-gradient-to-t from-navy/85 via-navy/25 to-transparent" />
              <div className="absolute right-0 bottom-0 left-0 flex flex-wrap items-end justify-between gap-4 p-6 text-white">
                <div>
                  <p className="text-[10px] font-semibold tracking-[0.24em] text-gold uppercase">
                    Your room
                  </p>
                  <h2 className="mt-1 font-heading text-3xl">{category.name}</h2>
                  <p className="mt-1 flex items-center gap-1.5 text-xs text-white/60">
                    <MapPin className="size-3.5 text-gold" />
                    Room {STAY.room} · Fourth floor · Victoria Island
                  </p>
                </div>
                <span className="rounded-full bg-white/10 px-3.5 py-1.5 text-[10px] font-bold tracking-[0.12em] uppercase backdrop-blur">
                  Confirmed
                </span>
              </div>
            </div>

            <div className="grid gap-5 p-6 sm:grid-cols-4">
              <div>
                <p className="field-label">Check in</p>
                <p className="mt-1.5 text-sm font-semibold text-navy">
                  {formatStayDate(STAY.checkIn)}
                </p>
                <p className="text-xs text-muted-foreground">From 14:00</p>
              </div>
              <div>
                <p className="field-label">Check out</p>
                <p className="mt-1.5 text-sm font-semibold text-navy">
                  {formatStayDate(STAY.checkOut)}
                </p>
                <p className="text-xs text-muted-foreground">By 12:00</p>
              </div>
              <div>
                <p className="field-label">Guests</p>
                <p className="mt-1.5 flex items-center gap-1.5 text-sm font-semibold text-navy">
                  <Users className="size-3.5 text-gold" />
                  {STAY.guests} adults
                </p>
                <p className="text-xs text-muted-foreground">{STAY.nights} nights</p>
              </div>
              <div>
                <p className="field-label">Reference</p>
                <p className="mt-1.5 text-sm font-semibold text-navy">{STAY.reference}</p>
                <p className="text-xs text-muted-foreground">Booking confirmed</p>
              </div>
            </div>

            <div className="flex flex-wrap gap-3 border-t border-border bg-ivory/60 px-6 py-4">
              <button
                type="button"
                onClick={() => setPayOpen(true)}
                disabled={balance === 0}
                className="inline-flex h-10 items-center gap-2 rounded-full bg-navy px-5 text-xs font-semibold text-white transition-colors hover:bg-navy-800 disabled:cursor-not-allowed disabled:opacity-50"
              >
                <CreditCard className="size-3.5" />
                {balance > 0 ? `Pay balance · ${formatNaira(balance)}` : "Fully paid"}
              </button>
              <Link
                href="/contact"
                className="inline-flex h-10 items-center gap-2 rounded-full border border-border bg-white px-5 text-xs font-semibold text-navy transition-colors hover:border-gold"
              >
                <ConciergeBell className="size-3.5 text-gold" />
                Message the concierge
              </Link>
              <Link
                href="/contact"
                className="inline-flex h-10 items-center gap-2 rounded-full px-4 text-xs font-semibold text-muted-foreground transition-colors hover:text-navy"
              >
                Request early check-in
                <ArrowRight className="size-3.5" />
              </Link>
            </div>
          </section>

          <section className="surface-card">
            <div className="flex flex-wrap items-center justify-between gap-3 border-b border-border px-6 py-5">
              <div>
                <p className="font-heading text-2xl text-navy">Your folio</p>
                <p className="mt-0.5 text-xs text-muted-foreground">
                  Charges and payments for this stay
                </p>
              </div>
              <button
                type="button"
                onClick={() => toast.info("Folio download will be enabled in the production build.")}
                className="inline-flex h-9 items-center gap-2 rounded-full border border-border px-4 text-xs font-semibold text-navy transition-colors hover:border-gold"
              >
                <Download className="size-3.5" />
                Download PDF
              </button>
            </div>

            <div className="divide-y divide-border/70 px-6">
              {FOLIO_ITEMS.map((item) => (
                <div key={item.label} className="flex items-center justify-between gap-4 py-4">
                  <div>
                    <p className="text-sm font-medium text-navy">{item.label}</p>
                    <p className="mt-0.5 text-xs text-muted-foreground">{item.detail}</p>
                  </div>
                  <p className="shrink-0 text-sm font-semibold text-navy">
                    {item.amount === 0 ? "Included" : formatNaira(item.amount)}
                  </p>
                </div>
              ))}
              <div className="flex items-center justify-between py-4 text-sm">
                <span className="text-muted-foreground">Paid to date</span>
                <span className="font-semibold text-[#4f6b4a]">− {formatNaira(paid)}</span>
              </div>
            </div>

            <div className="flex flex-wrap items-center justify-between gap-4 border-t border-border bg-ivory/60 px-6 py-5">
              <div>
                <p className="field-label">Balance</p>
                <p className="mt-1 font-heading text-3xl text-navy">{formatNaira(balance)}</p>
                <p className="mt-0.5 text-xs text-muted-foreground">
                  Due at check-in · no rush
                </p>
              </div>
              <button
                type="button"
                onClick={() => setPayOpen(true)}
                disabled={balance === 0}
                className="inline-flex h-11 items-center gap-2 rounded-full bg-gold px-6 text-sm font-semibold text-navy transition-colors hover:bg-gold-soft disabled:cursor-not-allowed disabled:opacity-50"
              >
                <Lock className="size-4" />
                {balance > 0 ? "Pay securely" : "Paid in full"}
              </button>
            </div>
          </section>

          <section className="surface-card">
            <div className="border-b border-border px-6 py-5">
              <p className="font-heading text-2xl text-navy">Payment history</p>
              <p className="mt-0.5 text-xs text-muted-foreground">
                Receipts for every payment on this booking
              </p>
            </div>
            <div className="divide-y divide-border/70 px-6">
              {payments.map((payment) => (
                <div key={payment.id} className="flex items-center justify-between gap-4 py-4">
                  <div className="flex items-center gap-3">
                    <span className="flex size-9 shrink-0 items-center justify-center rounded-full bg-sage/15 text-[#4f6b4a]">
                      <Check className="size-4" />
                    </span>
                    <div>
                      <p className="text-sm font-medium text-navy">{payment.method}</p>
                      <p className="mt-0.5 text-xs text-muted-foreground">
                        {payment.date} · {payment.id}
                      </p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-sm font-semibold text-navy">
                      {formatNaira(payment.amount)}
                    </p>
                    <p className="text-[10px] font-semibold tracking-[0.08em] text-[#4f6b4a] uppercase">
                      {payment.status}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </section>
        </div>

        <aside className="space-y-6">
          <section className="surface-card p-6">
            <p className="eyebrow">Before you arrive</p>
            <h2 className="mt-2 font-heading text-2xl text-navy">
              A few useful things
            </h2>
            <div className="mt-5 space-y-4">
              {[
                { icon: Clock, title: "Check-in from 14:00", copy: "Reception is open 24 hours. Early check-in is subject to availability." },
                { icon: Wifi, title: "Wi-Fi", copy: "Network: Aurelia Guest · Password: placed in your room." },
                { icon: Sparkles, title: "Your welcome drink", copy: "Redeem at The Gold Room, any evening of your stay." },
                { icon: CalendarDays, title: "Dinner at The Terrace", copy: "Tables fill up. Reply to your confirmation email to reserve one." },
              ].map((item) => (
                <div key={item.title} className="flex items-start gap-3.5">
                  <span className="flex size-9 shrink-0 items-center justify-center rounded-full bg-ivory text-gold">
                    <item.icon className="size-4" />
                  </span>
                  <div>
                    <p className="text-sm font-semibold text-navy">{item.title}</p>
                    <p className="mt-0.5 text-xs leading-5 text-muted-foreground">
                      {item.copy}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </section>

          <section className="overflow-hidden rounded-2xl bg-navy p-6 text-white">
            <p className="eyebrow">Need anything?</p>
            <p className="mt-2 font-heading text-2xl">The front desk is a message away.</p>
            <p className="mt-2 text-xs leading-6 text-white/50">
              Airport transfer, a late checkout, flowers or a restaurant booking
              — just ask.
            </p>
            <Link
              href="/contact"
              className="mt-5 inline-flex h-10 items-center gap-2 rounded-full bg-gold px-5 text-xs font-semibold text-navy transition-colors hover:bg-gold-soft"
            >
              Contact concierge
              <ArrowRight className="size-3.5" />
            </Link>
          </section>

          <section className="surface-card p-6">
            <p className="eyebrow">Cancellation policy</p>
            <p className="mt-3 text-sm leading-6 text-muted-foreground">
              Free cancellation until <span className="font-semibold text-navy">18 Nov 2026, 14:00</span>.
              After that, the first night is charged. Your deposit is applied to
              the final bill.
            </p>
          </section>
        </aside>
      </div>

      {payOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <button
            type="button"
            className="absolute inset-0 bg-navy/60 backdrop-blur-sm"
            onClick={() => !processing && setPayOpen(false)}
            aria-label="Close payment dialog"
          />
          <div className="relative w-full max-w-md rounded-2xl bg-white p-6 shadow-2xl">
            <button
              type="button"
              onClick={() => setPayOpen(false)}
              disabled={processing}
              className="absolute top-4 right-4 flex size-8 items-center justify-center rounded-full text-muted-foreground hover:bg-muted"
              aria-label="Close"
            >
              <X className="size-4" />
            </button>
            <p className="eyebrow">Secure payment</p>
            <h3 className="mt-2 font-heading text-3xl text-navy">Settle your balance</h3>
            <p className="mt-2 text-sm text-muted-foreground">
              Pay the outstanding amount for {STAY.reference}. Your folio updates
              immediately.
            </p>

            <div className="mt-6 rounded-xl bg-ivory p-4">
              <div className="flex items-center justify-between text-sm">
                <span className="text-muted-foreground">Outstanding balance</span>
                <span className="font-heading text-2xl text-navy">{formatNaira(balance)}</span>
              </div>
              <div className="mt-2 flex items-center justify-between text-xs">
                <span className="text-muted-foreground">Card</span>
                <span className="font-semibold text-navy">Visa ···· 4242</span>
              </div>
            </div>

            <button
              type="button"
              onClick={handlePay}
              disabled={processing}
              className="mt-5 flex h-12 w-full items-center justify-center gap-2 rounded-full bg-gold text-sm font-semibold text-navy transition-colors hover:bg-gold-soft disabled:cursor-wait disabled:opacity-70"
            >
              <Lock className="size-4" />
              {processing ? "Processing payment…" : `Pay ${formatNaira(balance)}`}
            </button>
            <p className="mt-3 text-center text-[10px] text-muted-foreground">
              Simulated Paystack checkout · no money is taken in the prototype
            </p>
          </div>
        </div>
      )}
    </div>
  );
}
