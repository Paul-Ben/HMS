import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { notFound } from "next/navigation";
import {
  ArrowLeft,
  BedDouble,
  Check,
  ChevronRight,
  Maximize,
  ShieldCheck,
  Users,
  UtensilsCrossed,
  Wifi,
} from "lucide-react";
import { CATEGORY_BY_SLUG, ROOM_CATEGORIES } from "@/lib/prototype-data";
import { formatNaira } from "@/lib/format";

export function generateStaticParams() {
  return ROOM_CATEGORIES.map((category) => ({ slug: category.slug }));
}

export async function generateMetadata({
  params,
}: PageProps<"/rooms/[slug]">): Promise<Metadata> {
  const { slug } = await params;
  const category = CATEGORY_BY_SLUG[slug];

  if (!category) {
    return { title: "Room not found" };
  }

  return {
    title: category.name,
    description: category.description,
  };
}

export default async function RoomDetailPage({
  params,
}: PageProps<"/rooms/[slug]">) {
  const { slug } = await params;
  const category = CATEGORY_BY_SLUG[slug];

  if (!category) {
    notFound();
  }

  return (
    <>
      <section className="container-page pt-10 pb-8">
        <div className="flex items-center gap-2 text-[10px] font-semibold tracking-[0.18em] text-muted-foreground uppercase">
          <Link href="/" className="hover:text-gold">
            Home
          </Link>
          <ChevronRight className="size-3" />
          <Link href="/rooms" className="hover:text-gold">
            Rooms
          </Link>
          <ChevronRight className="size-3" />
          <span className="text-navy">{category.name}</span>
        </div>

        <div className="mt-7 flex flex-col gap-5 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p className="eyebrow">{category.shortName}</p>
            <h1 className="mt-2 font-heading text-5xl leading-none tracking-[-0.03em] text-navy">
              {category.name}
            </h1>
          </div>
          <div className="sm:text-right">
            <p className="font-heading text-3xl text-navy">
              {formatNaira(category.rate)}
            </p>
            <p className="text-xs text-muted-foreground">per night, breakfast included</p>
          </div>
        </div>
      </section>

      <section className="container-page">
        <div className="grid gap-3 lg:grid-cols-[1.5fr_1fr]">
          <div className="relative aspect-[16/10] overflow-hidden rounded-2xl">
            <Image
              src={category.gallery[0]}
              alt={`${category.name} main view`}
              fill
              priority
              sizes="(min-width: 1024px) 60vw, 100vw"
              className="object-cover"
            />
          </div>
          <div className="grid h-full grid-cols-2 gap-3 lg:grid-cols-1 lg:grid-rows-2">
            {category.gallery.slice(1, 3).map((image, index) => (
              <div
                key={image}
                className="relative aspect-[4/3] overflow-hidden rounded-2xl lg:h-full lg:min-h-0"
              >
                <Image
                  src={image}
                  alt={`${category.name} detail ${index + 1}`}
                  fill
                  sizes="(min-width: 1024px) 30vw, 50vw"
                  className="object-cover"
                />
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="container-page py-14 lg:py-20">
        <div className="grid gap-14 lg:grid-cols-[1.45fr_0.85fr]">
          <div>
            <div className="grid grid-cols-3 gap-4 border-y border-border py-5">
              {[
                { icon: Maximize, label: `${category.size} sqm` },
                { icon: BedDouble, label: category.bed },
                { icon: Users, label: `Up to ${category.occupancy} guests` },
              ].map((item) => (
                <div key={item.label} className="flex items-center gap-2.5">
                  <item.icon className="size-4 shrink-0 text-gold" />
                  <span className="text-xs font-medium text-navy/70">{item.label}</span>
                </div>
              ))}
            </div>

            <div className="mt-10">
              <p className="eyebrow">The room</p>
              <h2 className="mt-3 font-heading text-3xl text-navy">
                Quiet by design.
              </h2>
              <p className="mt-5 text-[0.95rem] leading-8 text-muted-foreground">
                {category.description} Rooms face the courtyard or the garden,
                away from the street. Blackout curtains, a proper desk and
                bedside reading lights come as standard.
              </p>
              <p className="mt-4 text-[0.95rem] leading-8 text-muted-foreground">
                Breakfast is served at The Terrace from 06:30 to 10:30, or in
                your room if you prefer. The pool is open until 21:00, and the
                gym never closes.
              </p>
            </div>

            <div className="mt-10">
              <p className="eyebrow">In every room</p>
              <ul className="mt-5 grid gap-3 sm:grid-cols-2">
                {category.amenities.map((amenity) => (
                  <li key={amenity} className="flex items-center gap-3 text-sm text-navy/75">
                    <span className="flex size-6 items-center justify-center rounded-full bg-ivory text-gold">
                      <Check className="size-3.5" />
                    </span>
                    {amenity}
                  </li>
                ))}
              </ul>
            </div>

            <div className="mt-10 rounded-2xl bg-ivory p-6">
              <div className="flex items-start gap-3">
                <ShieldCheck className="mt-0.5 size-5 shrink-0 text-gold" />
                <div>
                  <p className="text-sm font-semibold text-navy">
                    Book direct, stay flexible
                  </p>
                  <p className="mt-1.5 text-sm leading-6 text-muted-foreground">
                    Free cancellation up to 48 hours before arrival. A 30%
                    deposit secures the room; the balance is due at check-in.
                  </p>
                </div>
              </div>
            </div>
          </div>

          <aside className="h-fit rounded-2xl border border-border bg-white p-6 shadow-[0_24px_60px_-40px_rgba(16,38,58,0.35)] lg:sticky lg:top-28">
            <div className="flex items-end justify-between">
              <div>
                <p className="text-xs font-semibold tracking-[0.16em] text-muted-foreground uppercase">
                  From
                </p>
                <p className="mt-1 font-heading text-4xl text-navy">
                  {formatNaira(category.rate)}
                </p>
              </div>
              <span className="rounded-full bg-gold/15 px-3 py-1 text-[10px] font-bold tracking-[0.12em] text-navy uppercase">
                Best rate
              </span>
            </div>

            <div className="mt-6 grid grid-cols-2 gap-3">
              <label className="flex flex-col gap-1.5">
                <span className="field-label">Check in</span>
                <input type="date" defaultValue="2026-11-24" className="input-luxe" />
              </label>
              <label className="flex flex-col gap-1.5">
                <span className="field-label">Check out</span>
                <input type="date" defaultValue="2026-11-27" className="input-luxe" />
              </label>
            </div>
            <label className="mt-3 flex flex-col gap-1.5">
              <span className="field-label">Guests</span>
              <select defaultValue="2" className="input-luxe appearance-none">
                <option value="1">1 guest</option>
                <option value="2">2 guests</option>
                <option value="3">3 guests</option>
                <option value="4">4 guests</option>
              </select>
            </label>

            <Link
              href={`/book?room=${category.slug}`}
              className="mt-5 flex h-12 items-center justify-center rounded-full bg-navy text-sm font-semibold text-white transition-colors hover:bg-navy-800"
            >
              Reserve this room
            </Link>
            <p className="mt-4 text-center text-[11px] text-muted-foreground">
              No payment needed to check availability
            </p>

            <div className="mt-6 space-y-3 border-t border-border pt-5">
              <p className="flex items-center gap-2.5 text-xs text-navy/65">
                <UtensilsCrossed className="size-4 text-gold" />
                Breakfast included
              </p>
              <p className="flex items-center gap-2.5 text-xs text-navy/65">
                <Wifi className="size-4 text-gold" />
                Fibre Wi-Fi, workspace
              </p>
              <p className="flex items-center gap-2.5 text-xs text-navy/65">
                <ShieldCheck className="size-4 text-gold" />
                Free cancellation up to 48h
              </p>
            </div>
          </aside>
        </div>
      </section>

      <section className="container-page pb-20">
        <div className="flex items-center justify-between border-t border-border pt-7">
          <Link
            href="/rooms"
            className="inline-flex items-center gap-2 text-sm font-semibold text-navy transition-colors hover:text-gold"
          >
            <ArrowLeft className="size-4" />
            All rooms
          </Link>
          <Link
            href="/book"
            className="inline-flex h-11 items-center rounded-full bg-gold px-6 text-sm font-semibold text-navy transition-colors hover:bg-gold-soft"
          >
            Check availability
          </Link>
        </div>
      </section>
    </>
  );
}
