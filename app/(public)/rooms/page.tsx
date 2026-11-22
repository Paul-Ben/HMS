import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { ChevronRight } from "lucide-react";
import { RoomsExplorer } from "@/components/site/rooms-explorer";

export const metadata: Metadata = {
  title: "Rooms & Suites",
  description:
    "Explore Aurelia's rooms and suites: calm, light-filled spaces with breakfast, fast Wi-Fi and access to the courtyard pool.",
};

export default function RoomsPage() {
  return (
    <>
      <section className="relative overflow-hidden bg-navy pt-32 pb-20 text-white">
        <Image
          src="https://images.unsplash.com/photo-1611892440504-42a792e24d32?auto=format&fit=crop&w=2000&q=80"
          alt=""
          fill
          priority
          sizes="100vw"
          className="object-cover opacity-30"
        />
        <div className="absolute inset-0 bg-gradient-to-r from-navy via-navy/80 to-navy/30" />
        <div className="container-page relative z-10">
          <div className="flex items-center gap-2 text-[10px] font-semibold tracking-[0.18em] text-white/45 uppercase">
            <Link href="/" className="hover:text-gold">
              Home
            </Link>
            <ChevronRight className="size-3" />
            <span className="text-gold">Rooms &amp; suites</span>
          </div>
          <p className="eyebrow mt-8">Sleep well</p>
          <h1 className="mt-3 max-w-3xl font-heading text-5xl leading-[1.02] tracking-[-0.03em] sm:text-6xl">
            Five ways to stay. All of them quiet.
          </h1>
          <p className="mt-5 max-w-xl text-sm leading-7 text-white/60">
            Every room includes breakfast at The Terrace, fibre Wi-Fi, filtered
            water and access to the courtyard pool. Choose the one that fits the
            trip.
          </p>
        </div>
      </section>

      <section className="container-page py-14 lg:py-20">
        <RoomsExplorer />
      </section>

      <section className="border-t border-border bg-ivory py-16">
        <div className="container-page flex flex-col items-start justify-between gap-6 sm:flex-row sm:items-center">
          <div>
            <p className="eyebrow">Not sure?</p>
            <h2 className="mt-2 font-heading text-3xl text-navy">
              Tell us how you travel. We will suggest the room.
            </h2>
          </div>
          <Link
            href="/contact"
            className="inline-flex h-11 shrink-0 items-center rounded-full bg-navy px-6 text-sm font-semibold text-white transition-colors hover:bg-navy-800"
          >
            Talk to the team
          </Link>
        </div>
      </section>
    </>
  );
}
