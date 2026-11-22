"use client";

import { useState } from "react";
import { toast } from "sonner";
import { ArrowRight } from "lucide-react";

export function ContactForm() {
  const [submitted, setSubmitted] = useState(false);

  function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setSubmitted(true);
    toast.success("Message received. The team will reply within one working day.");
  }

  if (submitted) {
    return (
      <div className="rounded-2xl bg-ivory p-8 text-center">
        <p className="font-heading text-3xl text-navy">Thank you.</p>
        <p className="mx-auto mt-3 max-w-sm text-sm leading-6 text-muted-foreground">
          Your message is with the front desk. We reply within one working day,
          usually much sooner.
        </p>
        <button
          type="button"
          onClick={() => setSubmitted(false)}
          className="mt-6 text-xs font-semibold tracking-[0.12em] text-gold uppercase hover:text-navy"
        >
          Send another message
        </button>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="grid gap-4 sm:grid-cols-2">
        <label className="flex flex-col gap-2">
          <span className="field-label">Full name</span>
          <input required placeholder="Ada Okafor" className="input-luxe" />
        </label>
        <label className="flex flex-col gap-2">
          <span className="field-label">Email</span>
          <input required type="email" placeholder="you@example.com" className="input-luxe" />
        </label>
      </div>
      <div className="grid gap-4 sm:grid-cols-2">
        <label className="flex flex-col gap-2">
          <span className="field-label">Phone</span>
          <input type="tel" placeholder="+234 800 000 0000" className="input-luxe" />
        </label>
        <label className="flex flex-col gap-2">
          <span className="field-label">I am writing about</span>
          <select className="input-luxe appearance-none" defaultValue="A room reservation">
            <option>A room reservation</option>
            <option>A dining reservation</option>
            <option>An event or celebration</option>
            <option>Press or partnership</option>
            <option>Something else</option>
          </select>
        </label>
      </div>
      <label className="flex flex-col gap-2">
        <span className="field-label">Message</span>
        <textarea
          required
          rows={5}
          placeholder="Tell us how we can help."
          className="w-full rounded-xl border border-input bg-white px-3.5 py-3 text-sm outline-none transition placeholder:text-muted-foreground/70 focus-visible:border-gold focus-visible:ring-3 focus-visible:ring-gold/20"
        />
      </label>
      <button
        type="submit"
        className="inline-flex h-12 items-center gap-2 rounded-full bg-navy px-7 text-sm font-semibold text-white transition-colors hover:bg-navy-800"
      >
        Send message
        <ArrowRight className="size-4" />
      </button>
    </form>
  );
}
