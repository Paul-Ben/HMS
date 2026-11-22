"use client";

import { useMemo, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { toast } from "sonner";
import {
  ArrowLeft,
  ArrowRight,
  BedDouble,
  CalendarDays,
  Check,
  CheckCircle2,
  CreditCard,
  Landmark,
  Lock,
  ShieldCheck,
  Sparkles,
  Users,
} from "lucide-react";
import {
  CATEGORY_BY_SLUG,
  ROOM_CATEGORIES,
  ROOMS,
} from "@/lib/prototype-data";
import { formatNaira, formatStayDate, nightsBetween } from "@/lib/format";
import { cn } from "@/lib/utils";

type Step = "stay" | "room" | "guest" | "done";

const STEPS: { key: Step; label: string }[] = [
  { key: "stay", label: "Your stay" },
  { key: "room", label: "Choose a room" },
  { key: "guest", label: "Guest details" },
];

export function BookingWizard() {
  const searchParams = useSearchParams();
  const requestedRoom = searchParams.get("room");
  const initialRoom =
    requestedRoom && CATEGORY_BY_SLUG[requestedRoom] ? requestedRoom : "deluxe-king";

  const [step, setStep] = useState<Step>("stay");
  const [checkIn, setCheckIn] = useState(
    searchParams.get("checkIn") ?? "2026-11-24",
  );
  const [checkOut, setCheckOut] = useState(
    searchParams.get("checkOut") ?? "2026-11-27",
  );
  const [adults, setAdults] = useState(2);
  const [children, setChildren] = useState(0);
  const [selected, setSelected] = useState(initialRoom);
  const [paymentOption, setPaymentOption] = useState<"deposit" | "full">("deposit");
  const [form, setForm] = useState({
    firstName: "",
    lastName: "",
    email: "",
    phone: "",
    arrival: "14:00 – 16:00",
    requests: "",
    consent: true,
  });
  const [processing, setProcessing] = useState(false);
  const [error, setError] = useState("");
  const [reference, setReference] = useState("");

  const category = CATEGORY_BY_SLUG[selected];
  const nights = nightsBetween(checkIn, checkOut);
  const guests = adults + children;
  const subtotal = category.rate * nights;
  const vat = Math.round(subtotal * 0.075);
  const total = subtotal + vat;
  const deposit = Math.round(total * 0.3);
  const amountDueNow = paymentOption === "deposit" ? deposit : total;
  const balance = total - amountDueNow;
  const stepIndex = STEPS.findIndex((item) => item.key === step);

  const availability = useMemo(() => {
    const counts: Record<string, number> = {};
    for (const room of ROOMS) {
      if (room.status === "available") {
        counts[room.categorySlug] = (counts[room.categorySlug] ?? 0) + 1;
      }
    }
    return counts;
  }, []);

  function moveTo(next: Step) {
    setError("");
    setStep(next);
    if (typeof window !== "undefined") {
      window.scrollTo({ top: 180, behavior: "smooth" });
    }
  }

  function validateStay() {
    if (checkOut <= checkIn) {
      setError("Check-out must be after check-in.");
      return false;
    }
    if (guests > 4) {
      setError("For more than four guests, please contact the hotel directly.");
      return false;
    }
    return true;
  }

  function handleStayContinue() {
    if (validateStay()) {
      moveTo("room");
    }
  }

  function handleRoomContinue() {
    const chosen = CATEGORY_BY_SLUG[selected];
    if (guests > chosen.occupancy) {
      setError(
        `${chosen.name} sleeps up to ${chosen.occupancy}. Please choose a larger room or split the party.`,
      );
      return;
    }
    moveTo("guest");
  }

  function handleConfirm(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError("");

    if (!form.firstName || !form.lastName || !form.email || !form.phone) {
      setError("Please add the lead guest's name, email and phone number.");
      return;
    }
    if (!form.consent) {
      setError("Please accept the booking and cancellation terms.");
      return;
    }

    setProcessing(true);
    const newReference = `AUR-2026-${Math.floor(1100 + Math.random() * 800)}`;
    setTimeout(() => {
      setReference(newReference);
      setProcessing(false);
      setStep("done");
      toast.success(
        paymentOption === "deposit"
          ? "Deposit received. Your room is held."
          : "Payment received. Your stay is confirmed.",
      );
      window.scrollTo({ top: 0, behavior: "smooth" });
    }, 1100);
  }

  if (step === "done") {
    return (
      <div className="mx-auto max-w-3xl">
        <div className="surface-card overflow-hidden">
          <div className="bg-navy px-8 py-12 text-center text-white">
            <span className="mx-auto flex size-16 items-center justify-center rounded-full bg-gold/15 text-gold ring-1 ring-gold/30">
              <CheckCircle2 className="size-8" />
            </span>
            <p className="mt-6 text-[10px] font-semibold tracking-[0.28em] text-gold uppercase">
              Booking confirmed
            </p>
            <h2 className="mt-3 font-heading text-4xl">We will see you soon.</h2>
            <p className="mx-auto mt-3 max-w-md text-sm leading-6 text-white/55">
              A confirmation and receipt are on their way to {form.email}. Your
              reference is{" "}
              <span className="font-semibold text-gold-soft">{reference}</span>.
            </p>
          </div>

          <div className="p-7 sm:p-9">
            <div className="grid gap-8 sm:grid-cols-[1.2fr_0.8fr]">
              <div>
                <p className="eyebrow">Your reservation</p>
                <div className="mt-4 space-y-4 text-sm">
                  <div className="flex items-start gap-3">
                    <BedDouble className="mt-0.5 size-4 shrink-0 text-gold" />
                    <div>
                      <p className="font-semibold text-navy">{category.name}</p>
                      <p className="mt-0.5 text-xs text-muted-foreground">
                        {nights} {nights === 1 ? "night" : "nights"} · {guests}{" "}
                        {guests === 1 ? "guest" : "guests"}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-start gap-3">
                    <CalendarDays className="mt-0.5 size-4 shrink-0 text-gold" />
                    <div>
                      <p className="font-semibold text-navy">
                        {formatStayDate(checkIn)} → {formatStayDate(checkOut)}
                      </p>
                      <p className="mt-0.5 text-xs text-muted-foreground">
                        Check-in 14:00 · Check-out 12:00
                      </p>
                    </div>
                  </div>
                  <div className="flex items-start gap-3">
                    <Users className="mt-0.5 size-4 shrink-0 text-gold" />
                    <div>
                      <p className="font-semibold text-navy">
                        {form.firstName} {form.lastName}
                      </p>
                      <p className="mt-0.5 text-xs text-muted-foreground">
                        {form.email}
                      </p>
                    </div>
                  </div>
                </div>
              </div>

              <div className="rounded-2xl bg-ivory p-5">
                <p className="text-xs font-semibold tracking-[0.16em] text-muted-foreground uppercase">
                  Payment
                </p>
                <p className="mt-2 font-heading text-3xl text-navy">
                  {formatNaira(amountDueNow)}
                </p>
                <p className="mt-1 text-xs text-muted-foreground">
                  {paymentOption === "deposit"
                    ? "30% deposit paid · balance due at check-in"
                    : "Paid in full · nothing due at check-in"}
                </p>
                {balance > 0 && (
                  <p className="mt-4 flex items-center justify-between border-t border-border pt-3 text-xs">
                    <span className="text-muted-foreground">Balance</span>
                    <span className="font-semibold text-navy">
                      {formatNaira(balance)}
                    </span>
                  </p>
                )}
                <p className="mt-4 flex items-center gap-1.5 text-[10px] text-muted-foreground">
                  <Lock className="size-3 text-sage" />
                  Simulated Paystack payment · no money moved
                </p>
              </div>
            </div>

            <div className="mt-8 flex flex-wrap gap-3 border-t border-border pt-6">
              <Link
                href="/account"
                className="inline-flex h-11 items-center rounded-full bg-navy px-6 text-sm font-semibold text-white transition-colors hover:bg-navy-800"
              >
                Open guest portal
              </Link>
              <Link
                href="/"
                className="inline-flex h-11 items-center rounded-full border border-border px-6 text-sm font-semibold text-navy transition-colors hover:border-gold"
              >
                Back to the hotel
              </Link>
              <button
                type="button"
                onClick={() => {
                  setStep("stay");
                  setReference("");
                  setForm({
                    firstName: "",
                    lastName: "",
                    email: "",
                    phone: "",
                    arrival: "14:00 – 16:00",
                    requests: "",
                    consent: true,
                  });
                }}
                className="inline-flex h-11 items-center rounded-full px-4 text-sm font-semibold text-muted-foreground transition-colors hover:text-navy"
              >
                Make another booking
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div>
      <div className="flex flex-wrap items-center gap-3 sm:gap-5">
        {STEPS.map((item, index) => {
          const active = item.key === step;
          const complete = index < stepIndex;
          return (
            <div key={item.key} className="flex items-center gap-3">
              <div
                className={cn(
                  "flex size-7 items-center justify-center rounded-full text-[11px] font-bold transition-colors",
                  active && "bg-navy text-white",
                  complete && "bg-gold text-navy",
                  !active && !complete && "border border-border bg-white text-muted-foreground",
                )}
              >
                {complete ? <Check className="size-3.5" /> : index + 1}
              </div>
              <span
                className={cn(
                  "text-xs font-semibold tracking-[0.08em] uppercase",
                  active ? "text-navy" : "text-muted-foreground",
                )}
              >
                {item.label}
              </span>
              {index < STEPS.length - 1 && (
                <span className="hidden h-px w-8 bg-border sm:block" />
              )}
            </div>
          );
        })}
      </div>

      <div className="mt-8 grid gap-8 lg:grid-cols-[1.55fr_0.85fr] lg:items-start">
        <div className="surface-card p-6 sm:p-8">
          {step === "stay" && (
            <div>
              <p className="eyebrow">Step one</p>
              <h2 className="mt-2 font-heading text-3xl text-navy">
                When would you like to arrive?
              </h2>
              <p className="mt-2 text-sm text-muted-foreground">
                Rates include breakfast and access to the pool. Free cancellation
                until 48 hours before arrival.
              </p>

              <div className="mt-7 grid gap-4 sm:grid-cols-2">
                <label className="flex flex-col gap-2">
                  <span className="field-label">Check in</span>
                  <input
                    type="date"
                    value={checkIn}
                    min="2026-11-20"
                    onChange={(event) => setCheckIn(event.target.value)}
                    className="input-luxe"
                  />
                </label>
                <label className="flex flex-col gap-2">
                  <span className="field-label">Check out</span>
                  <input
                    type="date"
                    value={checkOut}
                    min={checkIn}
                    onChange={(event) => setCheckOut(event.target.value)}
                    className="input-luxe"
                  />
                </label>
              </div>

              <div className="mt-5 grid gap-4 sm:grid-cols-2">
                <label className="flex flex-col gap-2">
                  <span className="field-label">Adults</span>
                  <select
                    value={adults}
                    onChange={(event) => setAdults(Number(event.target.value))}
                    className="input-luxe appearance-none"
                  >
                    <option value={1}>1 adult</option>
                    <option value={2}>2 adults</option>
                    <option value={3}>3 adults</option>
                    <option value={4}>4 adults</option>
                  </select>
                </label>
                <label className="flex flex-col gap-2">
                  <span className="field-label">Children</span>
                  <select
                    value={children}
                    onChange={(event) => setChildren(Number(event.target.value))}
                    className="input-luxe appearance-none"
                  >
                    <option value={0}>No children</option>
                    <option value={1}>1 child</option>
                    <option value={2}>2 children</option>
                  </select>
                </label>
              </div>

              <div className="mt-6 flex items-start gap-2.5 rounded-xl bg-ivory p-4 text-xs leading-5 text-muted-foreground">
                <Sparkles className="mt-0.5 size-4 shrink-0 text-gold" />
                Booking direct includes a welcome drink at The Gold Room and
                priority room allocation.
              </div>

              {error && <p className="mt-4 text-xs font-medium text-destructive">{error}</p>}

              <button
                type="button"
                onClick={handleStayContinue}
                className="mt-7 inline-flex h-11 items-center gap-2 rounded-full bg-navy px-6 text-sm font-semibold text-white transition-colors hover:bg-navy-800"
              >
                Choose a room
                <ArrowRight className="size-4" />
              </button>
            </div>
          )}

          {step === "room" && (
            <div>
              <p className="eyebrow">Step two</p>
              <h2 className="mt-2 font-heading text-3xl text-navy">
                Pick your room.
              </h2>
              <p className="mt-2 text-sm text-muted-foreground">
                {nights} {nights === 1 ? "night" : "nights"} · {guests}{" "}
                {guests === 1 ? "guest" : "guests"} · {formatStayDate(checkIn)} to{" "}
                {formatStayDate(checkOut)}
              </p>

              <div className="mt-6 space-y-3">
                {ROOM_CATEGORIES.map((roomCategory) => {
                  const isSelected = selected === roomCategory.slug;
                  const available = availability[roomCategory.slug] ?? 0;
                  const tooSmall = guests > roomCategory.occupancy;

                  return (
                    <button
                      key={roomCategory.slug}
                      type="button"
                      onClick={() => {
                        setSelected(roomCategory.slug);
                        setError("");
                      }}
                      className={cn(
                        "flex w-full gap-4 rounded-2xl border p-3 text-left transition-all",
                        isSelected
                          ? "border-gold bg-gold/5 ring-1 ring-gold/40"
                          : "border-border bg-white hover:border-gold/50",
                      )}
                    >
                      <div className="relative size-24 shrink-0 overflow-hidden rounded-xl sm:size-28">
                        <Image
                          src={roomCategory.image}
                          alt={roomCategory.name}
                          fill
                          sizes="112px"
                          className="object-cover"
                        />
                      </div>
                      <div className="flex min-w-0 flex-1 flex-col justify-between py-0.5">
                        <div>
                          <div className="flex items-start justify-between gap-3">
                            <p className="font-heading text-xl text-navy">
                              {roomCategory.name}
                            </p>
                            <span
                              className={cn(
                                "mt-0.5 flex size-5 shrink-0 items-center justify-center rounded-full border",
                                isSelected
                                  ? "border-gold bg-gold text-navy"
                                  : "border-border bg-white",
                              )}
                            >
                              {isSelected && <Check className="size-3" />}
                            </span>
                          </div>
                          <p className="mt-1 line-clamp-2 text-xs leading-5 text-muted-foreground">
                            {roomCategory.bed} · {roomCategory.size} sqm · up to{" "}
                            {roomCategory.occupancy} guests
                          </p>
                        </div>
                        <div className="mt-2 flex flex-wrap items-center justify-between gap-2">
                          <p className="text-xs">
                            <span className="font-bold text-navy">
                              {formatNaira(roomCategory.rate)}
                            </span>
                            <span className="text-muted-foreground"> / night</span>
                          </p>
                          <span
                            className={cn(
                              "text-[10px] font-semibold tracking-[0.08em] uppercase",
                              tooSmall
                                ? "text-clay"
                                : available <= 2
                                  ? "text-clay"
                                  : "text-sage",
                            )}
                          >
                            {tooSmall
                              ? "Too small for party"
                              : available <= 2
                                ? `${available} rooms left`
                                : `${available} rooms available`}
                          </span>
                        </div>
                      </div>
                    </button>
                  );
                })}
              </div>

              {error && <p className="mt-4 text-xs font-medium text-destructive">{error}</p>}

              <div className="mt-7 flex flex-wrap items-center gap-4">
                <button
                  type="button"
                  onClick={() => moveTo("stay")}
                  className="inline-flex h-11 items-center gap-2 rounded-full border border-border px-5 text-sm font-semibold text-navy transition-colors hover:border-gold"
                >
                  <ArrowLeft className="size-4" />
                  Back
                </button>
                <button
                  type="button"
                  onClick={handleRoomContinue}
                  className="inline-flex h-11 items-center gap-2 rounded-full bg-navy px-6 text-sm font-semibold text-white transition-colors hover:bg-navy-800"
                >
                  Continue to details
                  <ArrowRight className="size-4" />
                </button>
              </div>
            </div>
          )}

          {step === "guest" && (
            <form onSubmit={handleConfirm}>
              <p className="eyebrow">Step three</p>
              <h2 className="mt-2 font-heading text-3xl text-navy">
                Who shall we expect?
              </h2>
              <p className="mt-2 text-sm text-muted-foreground">
                We only need the lead guest. You can add the rest of your party
                at check-in.
              </p>

              <div className="mt-7 grid gap-4 sm:grid-cols-2">
                <label className="flex flex-col gap-2">
                  <span className="field-label">First name</span>
                  <input
                    value={form.firstName}
                    onChange={(event) =>
                      setForm({ ...form, firstName: event.target.value })
                    }
                    placeholder="Ada"
                    className="input-luxe"
                    autoComplete="given-name"
                  />
                </label>
                <label className="flex flex-col gap-2">
                  <span className="field-label">Last name</span>
                  <input
                    value={form.lastName}
                    onChange={(event) =>
                      setForm({ ...form, lastName: event.target.value })
                    }
                    placeholder="Okafor"
                    className="input-luxe"
                    autoComplete="family-name"
                  />
                </label>
                <label className="flex flex-col gap-2">
                  <span className="field-label">Email address</span>
                  <input
                    type="email"
                    value={form.email}
                    onChange={(event) =>
                      setForm({ ...form, email: event.target.value })
                    }
                    placeholder="you@example.com"
                    className="input-luxe"
                    autoComplete="email"
                  />
                </label>
                <label className="flex flex-col gap-2">
                  <span className="field-label">Phone number</span>
                  <input
                    type="tel"
                    value={form.phone}
                    onChange={(event) =>
                      setForm({ ...form, phone: event.target.value })
                    }
                    placeholder="+234 800 000 0000"
                    className="input-luxe"
                    autoComplete="tel"
                  />
                </label>
              </div>

              <div className="mt-4 grid gap-4 sm:grid-cols-2">
                <label className="flex flex-col gap-2">
                  <span className="field-label">Estimated arrival</span>
                  <select
                    value={form.arrival}
                    onChange={(event) =>
                      setForm({ ...form, arrival: event.target.value })
                    }
                    className="input-luxe appearance-none"
                  >
                    <option>12:00 – 14:00</option>
                    <option>14:00 – 16:00</option>
                    <option>16:00 – 18:00</option>
                    <option>18:00 – 20:00</option>
                    <option>After 20:00</option>
                  </select>
                </label>
                <label className="flex flex-col gap-2">
                  <span className="field-label">Anything we should know?</span>
                  <input
                    value={form.requests}
                    onChange={(event) =>
                      setForm({ ...form, requests: event.target.value })
                    }
                    placeholder="Allergies, occasion, quiet room…"
                    className="input-luxe"
                  />
                </label>
              </div>

              <div className="mt-7">
                <p className="field-label">Payment</p>
                <div className="mt-3 grid gap-3 sm:grid-cols-2">
                  <button
                    type="button"
                    onClick={() => setPaymentOption("deposit")}
                    className={cn(
                      "rounded-2xl border p-4 text-left transition-all",
                      paymentOption === "deposit"
                        ? "border-gold bg-gold/5 ring-1 ring-gold/40"
                        : "border-border bg-white hover:border-gold/50",
                    )}
                  >
                    <div className="flex items-center justify-between">
                      <span className="flex size-9 items-center justify-center rounded-full bg-navy text-gold">
                        <CreditCard className="size-4" />
                      </span>
                      <span className="rounded-full bg-gold/15 px-2.5 py-1 text-[9px] font-bold tracking-[0.1em] text-navy uppercase">
                        Recommended
                      </span>
                    </div>
                    <p className="mt-3 text-sm font-semibold text-navy">
                      Pay 30% deposit
                    </p>
                    <p className="mt-0.5 font-heading text-2xl text-navy">
                      {formatNaira(deposit)}
                    </p>
                    <p className="mt-1 text-[11px] leading-5 text-muted-foreground">
                      Balance of {formatNaira(total - deposit)} at check-in
                    </p>
                  </button>

                  <button
                    type="button"
                    onClick={() => setPaymentOption("full")}
                    className={cn(
                      "rounded-2xl border p-4 text-left transition-all",
                      paymentOption === "full"
                        ? "border-gold bg-gold/5 ring-1 ring-gold/40"
                        : "border-border bg-white hover:border-gold/50",
                    )}
                  >
                    <span className="flex size-9 items-center justify-center rounded-full bg-navy text-gold">
                      <Landmark className="size-4" />
                    </span>
                    <p className="mt-3 text-sm font-semibold text-navy">
                      Pay in full
                    </p>
                    <p className="mt-0.5 font-heading text-2xl text-navy">
                      {formatNaira(total)}
                    </p>
                    <p className="mt-1 text-[11px] leading-5 text-muted-foreground">
                      Nothing to settle at check-in
                    </p>
                  </button>
                </div>
              </div>

              <label className="mt-5 flex items-start gap-2.5 text-xs leading-5 text-muted-foreground">
                <input
                  type="checkbox"
                  checked={form.consent}
                  onChange={(event) =>
                    setForm({ ...form, consent: event.target.checked })
                  }
                  className="mt-0.5 size-4 accent-[#0b1f33]"
                />
                <span>
                  I accept the booking terms and the cancellation policy: free
                  cancellation until 48 hours before arrival, after which the
                  first night is charged.
                </span>
              </label>

              {error && <p className="mt-4 text-xs font-medium text-destructive">{error}</p>}

              <div className="mt-6 flex flex-wrap items-center gap-4">
                <button
                  type="button"
                  onClick={() => moveTo("room")}
                  className="inline-flex h-11 items-center gap-2 rounded-full border border-border px-5 text-sm font-semibold text-navy transition-colors hover:border-gold"
                >
                  <ArrowLeft className="size-4" />
                  Back
                </button>
                <button
                  type="submit"
                  disabled={processing}
                  className="inline-flex h-11 items-center gap-2 rounded-full bg-gold px-6 text-sm font-semibold text-navy transition-colors hover:bg-gold-soft disabled:cursor-wait disabled:opacity-70"
                >
                  <Lock className="size-4" />
                  {processing
                    ? "Securing your room…"
                    : paymentOption === "deposit"
                      ? `Pay ${formatNaira(deposit)} deposit`
                      : `Pay ${formatNaira(total)}`}
                </button>
              </div>
              <p className="mt-3 flex items-center gap-1.5 text-[10px] text-muted-foreground">
                <ShieldCheck className="size-3 text-sage" />
                Prototype checkout · Paystack is simulated and no payment is taken
              </p>
            </form>
          )}
        </div>

        <aside className="surface-card overflow-hidden lg:sticky lg:top-28">
          <div className="relative aspect-[16/9]">
            <Image
              src={category.image}
              alt={category.name}
              fill
              sizes="(min-width: 1024px) 32vw, 100vw"
              className="object-cover"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-navy/70 to-transparent" />
            <div className="absolute bottom-4 left-4 text-white">
              <p className="text-[10px] font-semibold tracking-[0.2em] text-gold uppercase">
                Your selection
              </p>
              <p className="mt-1 font-heading text-2xl">{category.name}</p>
            </div>
          </div>
          <div className="p-5">
            <div className="space-y-2.5 text-sm">
              <div className="flex items-center justify-between gap-3">
                <span className="text-muted-foreground">Dates</span>
                <span className="text-right text-xs font-semibold text-navy">
                  {formatStayDate(checkIn)} → {formatStayDate(checkOut)}
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">Guests</span>
                <span className="font-semibold text-navy">{guests}</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">
                  {formatNaira(category.rate)} × {nights}{" "}
                  {nights === 1 ? "night" : "nights"}
                </span>
                <span className="font-semibold text-navy">{formatNaira(subtotal)}</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">VAT (7.5%)</span>
                <span className="font-semibold text-navy">{formatNaira(vat)}</span>
              </div>
            </div>

            <div className="mt-4 flex items-end justify-between border-t border-border pt-4">
              <span className="text-sm font-semibold text-navy">Total</span>
              <span className="font-heading text-2xl text-navy">{formatNaira(total)}</span>
            </div>

            {step === "guest" && (
              <div className="mt-4 rounded-xl bg-ivory p-3.5">
                <div className="flex items-center justify-between text-xs">
                  <span className="text-muted-foreground">Due now</span>
                  <span className="font-bold text-navy">{formatNaira(amountDueNow)}</span>
                </div>
                {balance > 0 && (
                  <div className="mt-1.5 flex items-center justify-between text-xs">
                    <span className="text-muted-foreground">At check-in</span>
                    <span className="font-semibold text-navy">{formatNaira(balance)}</span>
                  </div>
                )}
              </div>
            )}

            <div className="mt-5 space-y-2 border-t border-border pt-4 text-[11px] text-muted-foreground">
              <p className="flex items-center gap-2">
                <ShieldCheck className="size-3.5 text-sage" />
                Free cancellation up to 48h before arrival
              </p>
              <p className="flex items-center gap-2">
                <Lock className="size-3.5 text-sage" />
                Secure payment via Paystack
              </p>
              <p className="flex items-center gap-2">
                <CalendarDays className="size-3.5 text-sage" />
                Check-in 14:00 · Check-out 12:00
              </p>
            </div>
          </div>
        </aside>
      </div>
    </div>
  );
}
