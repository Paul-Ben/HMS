"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { CalendarDays, Search, Users } from "lucide-react";

export function AvailabilitySearch() {
  const router = useRouter();
  const [checkIn, setCheckIn] = useState("2026-11-24");
  const [checkOut, setCheckOut] = useState("2026-11-27");
  const [guests, setGuests] = useState("2");

  function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const params = new URLSearchParams({ checkIn, checkOut, guests });
    router.push(`/book?${params.toString()}`);
  }

  return (
    <form
      onSubmit={handleSubmit}
      className="grid gap-0 overflow-hidden rounded-2xl border border-white/60 bg-white shadow-[0_30px_80px_-40px_rgba(7,22,38,0.55)] sm:grid-cols-2 lg:grid-cols-[1.1fr_1.1fr_0.8fr_auto]"
    >
      <label className="flex flex-col gap-1.5 border-b border-border/70 px-5 py-4 sm:border-r lg:border-b-0">
        <span className="field-label flex items-center gap-2">
          <CalendarDays className="size-3.5 text-gold" />
          Check in
        </span>
        <input
          type="date"
          value={checkIn}
          min="2026-11-20"
          onChange={(event) => setCheckIn(event.target.value)}
          className="w-full bg-transparent text-sm font-semibold text-navy outline-none"
        />
      </label>
      <label className="flex flex-col gap-1.5 border-b border-border/70 px-5 py-4 lg:border-r lg:border-b-0">
        <span className="field-label flex items-center gap-2">
          <CalendarDays className="size-3.5 text-gold" />
          Check out
        </span>
        <input
          type="date"
          value={checkOut}
          min={checkIn}
          onChange={(event) => setCheckOut(event.target.value)}
          className="w-full bg-transparent text-sm font-semibold text-navy outline-none"
        />
      </label>
      <label className="flex flex-col gap-1.5 border-b border-border/70 px-5 py-4 sm:border-r sm:border-b-0">
        <span className="field-label flex items-center gap-2">
          <Users className="size-3.5 text-gold" />
          Guests
        </span>
        <select
          value={guests}
          onChange={(event) => setGuests(event.target.value)}
          className="w-full appearance-none bg-transparent text-sm font-semibold text-navy outline-none"
        >
          <option value="1">1 guest</option>
          <option value="2">2 guests</option>
          <option value="3">3 guests</option>
          <option value="4">4 guests</option>
        </select>
      </label>
      <button
        type="submit"
        className="flex min-h-16 items-center justify-center gap-2 bg-navy px-7 text-sm font-semibold text-white transition-colors hover:bg-navy-800"
      >
        <Search className="size-4 text-gold" />
        Check availability
      </button>
    </form>
  );
}
