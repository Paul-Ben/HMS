import Image from "next/image";
import Link from "next/link";
import {
  ArrowRight,
  ArrowUpRight,
  CarFront,
  Dumbbell,
  Quote,
  Sparkles,
  Star,
  UtensilsCrossed,
  Waves,
  Wifi,
} from "lucide-react";
import { AvailabilitySearch } from "@/components/site/availability-search";
import { RoomCard } from "@/components/site/room-card";
import { SectionHeading } from "@/components/site/section-heading";
import { ROOM_CATEGORIES } from "@/lib/prototype-data";

const FEATURED_ROOMS = ROOM_CATEGORIES.slice(0, 3);

const AMENITIES = [
  { icon: Waves, title: "Courtyard pool", copy: "A quiet 18-metre pool framed by palms." },
  { icon: UtensilsCrossed, title: "Two restaurants", copy: "Coastal Nigerian cooking and a terrace grill." },
  { icon: Sparkles, title: "Aurelia Spa", copy: "Three treatment rooms and a hammam." },
  { icon: Wifi, title: "Fast Wi-Fi", copy: "Fibre throughout, ready for work." },
  { icon: CarFront, title: "Airport transfers", copy: "Private pick-up from Murtala Muhammed." },
  { icon: Dumbbell, title: "24-hour gym", copy: "Technogym equipment and a stretch studio." },
];

const EXPERIENCES = [
  {
    title: "The Terrace",
    copy: "Coastal Nigerian plates, charcoal grill and long Sunday lunches under the palms.",
    image:
      "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?auto=format&fit=crop&w=1400&q=80",
    href: "/dining",
    label: "Explore dining",
  },
  {
    title: "The Gold Room",
    copy: "A low-lit bar for a first drink, a last nightcap and everything in between.",
    image:
      "https://images.unsplash.com/photo-1514933651103-005eec06c04b?auto=format&fit=crop&w=1400&q=80",
    href: "/dining",
    label: "See the bar",
  },
];

export default function HomePage() {
  return (
    <>
      <section className="relative min-h-[940px] overflow-hidden bg-navy text-white">
        <Image
          src="https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=2200&q=85"
          alt="Aurelia Hotel pool and terrace at dusk"
          fill
          priority
          sizes="100vw"
          className="object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-r from-navy/85 via-navy/45 to-navy/10" />
        <div className="absolute inset-0 bg-gradient-to-t from-navy/80 via-transparent to-navy/30" />

        <div className="container-page relative z-10 flex min-h-[940px] flex-col justify-end pt-36 pb-10">
          <div className="mb-auto max-w-3xl animate-soft-rise">
            <div className="flex items-center gap-3">
              <span className="h-px w-10 bg-gold" />
              <p className="text-[11px] font-semibold tracking-[0.32em] text-gold uppercase">
                Victoria Island · Lagos
              </p>
            </div>
            <h1 className="mt-7 font-heading text-[3.4rem] leading-[0.98] font-medium tracking-[-0.035em] sm:text-[4.6rem] lg:text-[5.6rem]">
              Stay where Lagos
              <span className="block italic text-gold-soft">slows down.</span>
            </h1>
            <p className="mt-7 max-w-lg text-base leading-8 text-white/70">
              Thirty rooms and suites, a courtyard pool and a restaurant that
              feels like a well-kept secret. Tucked away on a quiet Victoria
              Island street, minutes from everything.
            </p>
            <div className="mt-9 flex flex-wrap items-center gap-4">
              <Link
                href="/rooms"
                className="inline-flex h-12 items-center gap-2 rounded-full bg-gold px-6 text-sm font-semibold text-navy transition-colors hover:bg-gold-soft"
              >
                Explore rooms &amp; suites
                <ArrowRight className="size-4" />
              </Link>
              <Link
                href="/#story"
                className="inline-flex h-12 items-center gap-2 rounded-full border border-white/25 px-6 text-sm font-semibold text-white transition-colors hover:border-gold hover:text-gold"
              >
                Discover Aurelia
              </Link>
            </div>
            <div className="mt-10 flex items-center gap-4 text-xs text-white/60">
              <span className="flex items-center gap-1 text-gold">
                {[0, 1, 2, 3, 4].map((star) => (
                  <Star key={star} className="size-3.5 fill-gold" />
                ))}
              </span>
              <span>4.7 from 380+ guest reviews</span>
            </div>
          </div>

          <AvailabilitySearch />
        </div>
      </section>

      <section id="story" className="container-page py-24 lg:py-32">
        <div className="grid items-center gap-14 lg:grid-cols-2 lg:gap-24">
          <div className="relative">
            <div className="relative aspect-[4/5] overflow-hidden rounded-[1.75rem]">
              <Image
                src="https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=1400&q=80"
                alt="The Aurelia lobby"
                fill
                sizes="(min-width: 1024px) 45vw, 100vw"
                className="object-cover"
              />
            </div>
            <div className="absolute -right-4 -bottom-8 hidden w-56 rounded-2xl bg-navy p-6 text-white shadow-2xl sm:block lg:-right-10">
              <p className="font-heading text-4xl text-gold">Est. 2019</p>
              <p className="mt-2 text-xs leading-5 tracking-[0.08em] text-white/60 uppercase">
                Independently owned. Quietly run.
              </p>
            </div>
          </div>

          <div>
            <p className="eyebrow">Welcome to Aurelia</p>
            <h2 className="mt-4 font-heading text-4xl leading-[1.08] tracking-[-0.025em] text-navy sm:text-5xl">
              A small hotel with a generous sense of space.
            </h2>
            <p className="mt-6 text-[0.95rem] leading-8 text-muted-foreground">
              Aurelia was designed for people who would rather have one
              beautifully considered room than a hundred anonymous ones. Every
              suite opens to light and greenery. Every meal starts with produce
              chosen that morning. And every guest is looked after by a team
              that has been here long enough to remember how you take your
              coffee.
            </p>
            <p className="mt-4 text-[0.95rem] leading-8 text-muted-foreground">
              Whether you are in Lagos for a board meeting, a family celebration
              or a quiet weekend, the city is close. The noise is not.
            </p>

            <div className="mt-9 grid grid-cols-3 gap-6 border-y border-border py-7">
              {[
                { value: "30", label: "Rooms & suites" },
                { value: "4.7", label: "Guest rating" },
                { value: "12", label: "Minutes to the marina" },
              ].map((stat) => (
                <div key={stat.label}>
                  <p className="font-heading text-3xl text-navy">{stat.value}</p>
                  <p className="mt-1 text-[0.68rem] font-semibold tracking-[0.14em] text-muted-foreground uppercase">
                    {stat.label}
                  </p>
                </div>
              ))}
            </div>

            <Link
              href="/contact"
              className="mt-8 inline-flex items-center gap-2 border-b border-navy/25 pb-1 text-sm font-semibold text-navy transition-colors hover:border-gold hover:text-gold"
            >
              Plan your visit
              <ArrowUpRight className="size-4" />
            </Link>
          </div>
        </div>
      </section>

      <section className="bg-ivory py-24 lg:py-28">
        <div className="container-page">
          <SectionHeading
            eyebrow="Rooms & suites"
            title="Considered spaces, from first light to late evening."
            description="Five room styles, each with its own character. All include breakfast, fast Wi-Fi and access to the courtyard pool."
            action={{ href: "/rooms", label: "View all rooms" }}
          />
          <div className="mt-12 grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            {FEATURED_ROOMS.map((category) => (
              <RoomCard key={category.slug} category={category} />
            ))}
          </div>
        </div>
      </section>

      <section id="experience" className="py-24 lg:py-32">
        <div className="container-page">
          <SectionHeading
            eyebrow="Eat, drink, linger"
            title="The best part of the hotel is not the room."
            description="A courtyard restaurant, a charcoal grill and a small bar with a very good bartender. Open to guests and neighbours alike."
            action={{ href: "/dining", label: "Dining at Aurelia" }}
          />

          <div className="mt-12 grid gap-6 lg:grid-cols-2">
            {EXPERIENCES.map((experience, index) => (
              <Link
                key={experience.title}
                href={experience.href}
                className={`group relative overflow-hidden rounded-[1.5rem] ${
                  index === 0 ? "aspect-[5/4] lg:aspect-[4/5]" : "aspect-[5/4] lg:mt-20"
                }`}
              >
                <Image
                  src={experience.image}
                  alt={experience.title}
                  fill
                  sizes="(min-width: 1024px) 50vw, 100vw"
                  className="object-cover transition-transform duration-700 group-hover:scale-[1.04]"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-navy/85 via-navy/15 to-transparent" />
                <div className="absolute right-0 bottom-0 left-0 p-7 text-white">
                  <p className="text-[10px] font-semibold tracking-[0.24em] text-gold uppercase">
                    {index === 0 ? "Restaurant" : "Bar"}
                  </p>
                  <h3 className="mt-2 font-heading text-3xl">{experience.title}</h3>
                  <p className="mt-2 max-w-sm text-sm leading-6 text-white/65">
                    {experience.copy}
                  </p>
                  <span className="mt-5 inline-flex items-center gap-2 text-xs font-semibold tracking-[0.1em] uppercase">
                    {experience.label}
                    <ArrowUpRight className="size-3.5 transition-transform group-hover:translate-x-1 group-hover:-translate-y-1" />
                  </span>
                </div>
              </Link>
            ))}
          </div>
        </div>
      </section>

      <section className="bg-navy py-24 text-white lg:py-28">
        <div className="container-page">
          <div className="grid gap-12 lg:grid-cols-[0.9fr_1.1fr] lg:items-end">
            <div>
              <p className="eyebrow">The details</p>
              <h2 className="mt-3 max-w-lg font-heading text-4xl leading-[1.08] tracking-[-0.02em] sm:text-5xl">
                Everything you need. Nothing you have to think about.
              </h2>
            </div>
            <p className="max-w-md text-sm leading-7 text-white/55 lg:ml-auto">
              From the airport pick-up to the last espresso, the small things are
              already taken care of. If there is something else, ask. We are
              good at that.
            </p>
          </div>

          <div className="mt-14 grid gap-x-10 gap-y-9 sm:grid-cols-2 lg:grid-cols-3">
            {AMENITIES.map((amenity) => (
              <div
                key={amenity.title}
                className="flex gap-4 border-t border-white/10 pt-6"
              >
                <amenity.icon className="mt-0.5 size-5 shrink-0 text-gold" />
                <div>
                  <h3 className="text-sm font-semibold text-white">{amenity.title}</h3>
                  <p className="mt-1.5 text-sm leading-6 text-white/50">
                    {amenity.copy}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="container-page py-24 lg:py-32">
        <div className="mx-auto max-w-3xl text-center">
          <Quote className="mx-auto size-7 text-gold" />
          <blockquote className="mt-7 font-heading text-3xl leading-[1.3] text-navy sm:text-[2.6rem]">
            “The kind of hotel you tell people about quietly, because you would
            rather keep it to yourself.”
          </blockquote>
          <div className="mt-7 flex items-center justify-center gap-3 text-xs font-semibold tracking-[0.16em] text-muted-foreground uppercase">
            <span className="h-px w-8 bg-gold" />
            Sarah M. · London
            <span className="h-px w-8 bg-gold" />
          </div>
        </div>
      </section>

      <section className="container-page pb-24 lg:pb-32">
        <div className="relative overflow-hidden rounded-[2rem] bg-navy px-7 py-16 text-center text-white sm:px-12 lg:py-24">
          <Image
            src="https://images.unsplash.com/photo-1571896349842-33c89424de2d?auto=format&fit=crop&w=2000&q=80"
            alt=""
            fill
            sizes="100vw"
            className="object-cover opacity-30"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-navy via-navy/60 to-navy/20" />
          <div className="relative mx-auto max-w-2xl">
            <p className="eyebrow">Your next stay</p>
            <h2 className="mt-4 font-heading text-4xl leading-[1.1] sm:text-5xl">
              The city can wait. Your room is ready.
            </h2>
            <p className="mx-auto mt-5 max-w-md text-sm leading-7 text-white/60">
              Book direct for our best rate, a flexible cancellation window and
              a welcome drink at the Gold Room.
            </p>
            <div className="mt-8 flex flex-wrap justify-center gap-3">
              <Link
                href="/book"
                className="inline-flex h-12 items-center gap-2 rounded-full bg-gold px-7 text-sm font-semibold text-navy transition-colors hover:bg-gold-soft"
              >
                Check availability
                <ArrowRight className="size-4" />
              </Link>
              <Link
                href="/contact"
                className="inline-flex h-12 items-center rounded-full border border-white/25 px-7 text-sm font-semibold text-white transition-colors hover:border-gold hover:text-gold"
              >
                Speak to the team
              </Link>
            </div>
          </div>
        </div>
      </section>
    </>
  );
}
