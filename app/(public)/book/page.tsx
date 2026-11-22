import type { Metadata } from "next";
import { Suspense } from "react";
import { BookingWizard } from "@/components/public/booking-wizard";

export const metadata: Metadata = {
  title: "Book your stay",
  description:
    "Check availability and reserve a room at Aurelia Hotel & Suites. Book direct for the best rate and flexible cancellation.",
};

export default function BookPage() {
  return (
    <>
      <section className="border-b border-border bg-ivory pt-14 pb-10">
        <div className="container-page">
          <p className="eyebrow">Reservations</p>
          <h1 className="mt-3 font-heading text-4xl leading-tight tracking-[-0.02em] text-navy sm:text-5xl">
            Reserve your stay.
          </h1>
          <p className="mt-3 max-w-xl text-sm leading-7 text-muted-foreground">
            A 30% deposit holds your room. The balance is settled at check-in,
            and you can cancel free of charge until 48 hours before arrival.
          </p>
        </div>
      </section>

      <section className="container-page py-10 lg:py-14">
        <Suspense
          fallback={
            <div className="grid gap-8 lg:grid-cols-[1.55fr_0.85fr]">
              <div className="h-[520px] animate-pulse rounded-2xl bg-muted" />
              <div className="h-[420px] animate-pulse rounded-2xl bg-muted" />
            </div>
          }
        >
          <BookingWizard />
        </Suspense>
      </section>
    </>
  );
}
