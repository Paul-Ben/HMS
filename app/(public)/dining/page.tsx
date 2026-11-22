import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { ArrowUpRight, Clock, MapPin, UtensilsCrossed, Wine } from "lucide-react";

export const metadata: Metadata = {
  title: "Dining",
  description:
    "The Terrace restaurant and The Gold Room bar at Aurelia Hotel & Suites, Victoria Island.",
};

const MENU = [
  {
    section: "Small plates",
    items: [
      { name: "Suya-spiced beef skewers", price: "₦14,000", note: "red onion, roasted peanut" },
      { name: "Charred plantain", price: "₦9,500", note: "scotch bonnet honey, sesame" },
      { name: "Seafood pepper soup", price: "₦16,000", note: "prawn, snapper, scent leaf" },
    ],
  },
  {
    section: "Mains",
    items: [
      { name: "Grilled tilapia", price: "₦28,000", note: "jollof rice, charred lemon" },
      { name: "Aurelia burger", price: "₦18,000", note: "beef, smoked cheese, plantain chips" },
      { name: "Coconut rice & prawns", price: "₦26,000", note: "crispy shallot, lime" },
      { name: "Seafood pasta", price: "₦26,000", note: "prawn, calamari, tomato, chilli" },
    ],
  },
  {
    section: "Sweet",
    items: [
      { name: "Coconut cake", price: "₦8,500", note: "lime curd, toasted coconut" },
      { name: "Dark chocolate pot", price: "₦9,000", note: "sea salt, biscuit" },
    ],
  },
];

const BAR_MENU = [
  { name: "Aurelia Sunset", price: "₦9,500", note: "gin, hibiscus, grapefruit" },
  { name: "Gold Room Old Fashioned", price: "₦12,000", note: "bourbon, palm sugar, bitters" },
  { name: "Espresso martini", price: "₦11,000", note: "vodka, cold brew, vanilla" },
  { name: "Chapman", price: "₦6,000", note: "the Lagos classic" },
];

export default function DiningPage() {
  return (
    <>
      <section className="relative min-h-[560px] overflow-hidden bg-navy text-white">
        <Image
          src="https://images.unsplash.com/photo-1414235077428-338989a2e8c0?auto=format&fit=crop&w=2200&q=85"
          alt="The Terrace restaurant"
          fill
          priority
          sizes="100vw"
          className="object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-navy via-navy/55 to-navy/20" />
        <div className="container-page relative flex min-h-[560px] flex-col justify-end pt-32 pb-14">
          <p className="eyebrow">Eat & drink</p>
          <h1 className="mt-3 max-w-2xl font-heading text-5xl leading-[1.02] tracking-[-0.03em] sm:text-6xl">
            Good food. Long lunches. No rush.
          </h1>
          <p className="mt-5 max-w-xl text-sm leading-7 text-white/65">
            Two rooms, one kitchen philosophy: coastal Nigerian ingredients,
            cooked simply and served generously. Open to guests and neighbours
            alike.
          </p>
        </div>
      </section>

      <section className="container-page py-20 lg:py-28">
        <div className="grid gap-14 lg:grid-cols-[1fr_1.1fr] lg:items-center">
          <div className="relative aspect-[4/5] overflow-hidden rounded-2xl">
            <Image
              src="https://images.unsplash.com/photo-1559339352-11d035aa65de?auto=format&fit=crop&w=1400&q=80"
              alt="The Terrace dining room"
              fill
              sizes="(min-width: 1024px) 45vw, 100vw"
              className="object-cover"
            />
          </div>
          <div>
            <p className="eyebrow">The Terrace</p>
            <h2 className="mt-3 font-heading text-4xl leading-[1.08] text-navy sm:text-5xl">
              A courtyard restaurant that feels like a secret.
            </h2>
            <p className="mt-5 text-[0.95rem] leading-8 text-muted-foreground">
              Breakfast under the palms, a quiet lunch between meetings, or a
              long dinner with friends. The menu follows the market: snapper and
              prawns from the coast, greens from the farm, and a charcoal grill
              that runs all evening.
            </p>
            <div className="mt-7 flex flex-wrap gap-6 text-sm">
              <span className="flex items-center gap-2 text-navy/70">
                <Clock className="size-4 text-gold" />
                Breakfast 06:30–10:30
              </span>
              <span className="flex items-center gap-2 text-navy/70">
                <UtensilsCrossed className="size-4 text-gold" />
                Lunch &amp; dinner 12:00–22:30
              </span>
            </div>
            <Link
              href="/contact"
              className="mt-8 inline-flex h-11 items-center gap-2 rounded-full bg-navy px-6 text-sm font-semibold text-white transition-colors hover:bg-navy-800"
            >
              Reserve a table
              <ArrowUpRight className="size-4" />
            </Link>
          </div>
        </div>
      </section>

      <section className="bg-ivory py-20 lg:py-24">
        <div className="container-page">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
            <div>
              <p className="eyebrow">The menu</p>
              <h2 className="mt-2 font-heading text-4xl text-navy">A taste of the Terrace</h2>
            </div>
            <p className="max-w-sm text-xs leading-6 text-muted-foreground">
              Sample menu for the prototype. Dishes change with the season.
              Vegetarian and allergy-friendly options are always available.
            </p>
          </div>

          <div className="mt-10 grid gap-10 md:grid-cols-3">
            {MENU.map((group) => (
              <div key={group.section}>
                <p className="border-b border-navy/15 pb-3 text-[11px] font-bold tracking-[0.2em] text-gold uppercase">
                  {group.section}
                </p>
                <ul className="mt-4 space-y-5">
                  {group.items.map((item) => (
                    <li key={item.name}>
                      <div className="flex items-baseline justify-between gap-4">
                        <span className="text-sm font-semibold text-navy">{item.name}</span>
                        <span className="shrink-0 text-sm font-semibold text-navy">
                          {item.price}
                        </span>
                      </div>
                      <p className="mt-1 text-xs text-muted-foreground">{item.note}</p>
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="container-page py-20 lg:py-28">
        <div className="grid overflow-hidden rounded-[1.75rem] bg-navy text-white lg:grid-cols-2">
          <div className="relative min-h-[360px]">
            <Image
              src="https://images.unsplash.com/photo-1514933651103-005eec06c04b?auto=format&fit=crop&w=1600&q=80"
              alt="The Gold Room bar"
              fill
              sizes="(min-width: 1024px) 50vw, 100vw"
              className="object-cover"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-navy/60 to-transparent lg:bg-gradient-to-r" />
          </div>
          <div className="p-8 sm:p-12">
            <p className="eyebrow">The Gold Room</p>
            <h2 className="mt-3 font-heading text-4xl leading-[1.08]">
              Low light, good ice, a very good bartender.
            </h2>
            <p className="mt-4 text-sm leading-7 text-white/55">
              A small bar for the first drink and the last one. Classic cocktails,
              a short wine list and a whisky shelf worth staying for. Open from
              17:00, with live vinyl on Fridays.
            </p>

            <ul className="mt-7 space-y-4">
              {BAR_MENU.map((item) => (
                <li key={item.name} className="flex items-baseline justify-between gap-4 border-b border-white/10 pb-3">
                  <div>
                    <p className="text-sm font-semibold text-white">{item.name}</p>
                    <p className="mt-0.5 text-[11px] text-white/40">{item.note}</p>
                  </div>
                  <span className="text-xs font-semibold text-gold">{item.price}</span>
                </li>
              ))}
            </ul>

            <div className="mt-6 flex items-center gap-2 text-xs text-white/45">
              <Wine className="size-4 text-gold" />
              Open daily 17:00–00:00 · Smart casual
            </div>
          </div>
        </div>
      </section>

      <section className="container-page pb-20">
        <div className="flex flex-col items-start justify-between gap-6 rounded-2xl border border-border bg-white p-7 sm:flex-row sm:items-center">
          <div className="flex items-start gap-4">
            <span className="flex size-10 shrink-0 items-center justify-center rounded-full bg-ivory text-gold">
              <MapPin className="size-5" />
            </span>
            <div>
              <p className="text-sm font-semibold text-navy">Dining is open to non-residents</p>
              <p className="mt-1 text-xs leading-5 text-muted-foreground">
                Please reserve ahead for dinner and weekend brunch.
              </p>
            </div>
          </div>
          <Link
            href="/contact"
            className="inline-flex h-11 shrink-0 items-center rounded-full bg-gold px-6 text-sm font-semibold text-navy transition-colors hover:bg-gold-soft"
          >
            Enquire about a table
          </Link>
        </div>
      </section>
    </>
  );
}
