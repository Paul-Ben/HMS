import Link from "next/link";
import { ArrowUpRight, Camera, Mail, MapPin, Phone } from "lucide-react";
import { Logo } from "@/components/shared/logo";

const HOTEL_LINKS = [
  { href: "/rooms", label: "Rooms & suites" },
  { href: "/dining", label: "Dining" },
  { href: "/#experience", label: "Experiences" },
  { href: "/#story", label: "Our story" },
];

const GUEST_LINKS = [
  { href: "/book", label: "Book a stay" },
  { href: "/account", label: "Guest portal" },
  { href: "/dashboard/owner", label: "Staff workspace" },
  { href: "/contact", label: "Contact us" },
];

export function PublicFooter() {
  return (
    <footer className="bg-navy text-white">
      <div className="container-page py-16 lg:py-20">
        <div className="grid gap-12 lg:grid-cols-[1.4fr_0.7fr_0.7fr_1.2fr]">
          <div>
            <Logo variant="light" />
            <p className="mt-5 max-w-xs text-sm leading-7 text-white/60">
              A quiet luxury hotel on Victoria Island. Thoughtful rooms, generous
              dining and the kind of service that remembers your name.
            </p>
            <div className="mt-7 flex items-center gap-3">
              <span className="flex size-9 items-center justify-center rounded-full border border-white/15 text-gold">
                <Camera className="size-4" />
              </span>
              <span className="flex size-9 items-center justify-center rounded-full border border-white/15 text-gold">
                <Mail className="size-4" />
              </span>
              <span className="flex size-9 items-center justify-center rounded-full border border-white/15 text-gold">
                <Phone className="size-4" />
              </span>
            </div>
          </div>

          <div>
            <p className="eyebrow">The hotel</p>
            <ul className="mt-5 space-y-3">
              {HOTEL_LINKS.map((link) => (
                <li key={link.href}>
                  <Link
                    href={link.href}
                    className="text-sm text-white/65 transition-colors hover:text-gold"
                  >
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          <div>
            <p className="eyebrow">Guests</p>
            <ul className="mt-5 space-y-3">
              {GUEST_LINKS.map((link) => (
                <li key={link.href}>
                  <Link
                    href={link.href}
                    className="text-sm text-white/65 transition-colors hover:text-gold"
                  >
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          <div>
            <p className="eyebrow">Stay in touch</p>
            <p className="mt-5 text-sm leading-7 text-white/60">
              Notes on new suites, seasonal menus and quiet weekends in Lagos.
            </p>
            <form className="mt-5 flex overflow-hidden rounded-full border border-white/15 bg-white/5">
              <input
                type="email"
                placeholder="Your email address"
                className="h-11 min-w-0 flex-1 bg-transparent px-4 text-sm text-white outline-none placeholder:text-white/35"
                aria-label="Email address"
              />
              <button
                type="submit"
                className="flex size-11 shrink-0 items-center justify-center bg-gold text-navy transition-colors hover:bg-gold-soft"
                aria-label="Subscribe"
              >
                <ArrowUpRight className="size-4" />
              </button>
            </form>
            <div className="mt-6 space-y-3 text-sm text-white/60">
              <p className="flex items-start gap-2.5">
                <MapPin className="mt-0.5 size-4 shrink-0 text-gold" />
                12 Akin Adesola Street, Victoria Island, Lagos
              </p>
              <p className="flex items-center gap-2.5">
                <Phone className="size-4 shrink-0 text-gold" />
                +234 800 000 0000
              </p>
            </div>
          </div>
        </div>

        <div className="mt-14 flex flex-col gap-5 border-t border-white/10 pt-7 text-xs text-white/40 sm:flex-row sm:items-center sm:justify-between">
          <p>© 2026 Aurelia Hotel & Suites. All rights reserved.</p>
          <div className="flex flex-wrap gap-5">
            <Link href="/contact" className="hover:text-gold">
              Privacy
            </Link>
            <Link href="/contact" className="hover:text-gold">
              Terms
            </Link>
            <span>Prototype · sample data only</span>
          </div>
        </div>
      </div>
    </footer>
  );
}
