"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useState } from "react";
import { ArrowUpRight, Menu, Phone, X } from "lucide-react";
import { Logo } from "@/components/shared/logo";
import { cn } from "@/lib/utils";

const LINKS = [
  { href: "/rooms", label: "Rooms & suites" },
  { href: "/dining", label: "Dining" },
  { href: "/#experience", label: "The hotel" },
  { href: "/contact", label: "Contact" },
];

export function PublicHeader() {
  const pathname = usePathname();
  const overHero = pathname === "/";
  const [open, setOpen] = useState(false);

  return (
    <>
      <header
        className={cn(
          "z-40 w-full",
          overHero
            ? "absolute top-0 left-0 border-b border-white/10 bg-gradient-to-b from-navy/60 to-transparent text-white"
            : "sticky top-0 border-b border-border/70 bg-ivory/95 text-navy backdrop-blur-xl",
        )}
      >
        <div className="container-page flex h-20 items-center justify-between gap-6">
          <Logo variant={overHero ? "light" : "dark"} />

          <nav className="hidden items-center gap-8 lg:flex">
            {LINKS.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                className={cn(
                  "relative text-[0.78rem] font-semibold tracking-[0.14em] uppercase transition-colors",
                  overHero
                    ? "text-white/80 hover:text-white"
                    : "text-navy/70 hover:text-navy",
                )}
              >
                {link.label}
                <span className="absolute -bottom-2 left-0 h-px w-0 bg-gold transition-all duration-300 hover:w-full" />
              </Link>
            ))}
          </nav>

          <div className="hidden items-center gap-5 md:flex">
            <a
              href="tel:+2348000000000"
              className={cn(
                "items-center gap-2 text-sm font-medium lg:flex",
                overHero ? "text-white/80 hover:text-white" : "text-navy/70 hover:text-navy",
              )}
            >
              <Phone className="size-3.5" />
              +234 800 000 0000
            </a>
            <Link
              href="/book"
              className="inline-flex h-10 items-center gap-2 rounded-full bg-gold px-5 text-sm font-semibold text-navy transition-colors hover:bg-gold-soft"
            >
              Book your stay
              <ArrowUpRight className="size-4" />
            </Link>
          </div>

          <button
            type="button"
            onClick={() => setOpen(true)}
            className={cn(
              "inline-flex size-10 items-center justify-center rounded-full border md:hidden",
              overHero ? "border-white/25 text-white" : "border-border text-navy",
            )}
            aria-label="Open menu"
          >
            <Menu className="size-5" />
          </button>
        </div>
      </header>

      {open && (
        <div className="fixed inset-0 z-50 md:hidden">
          <button
            type="button"
            className="absolute inset-0 bg-navy/50 backdrop-blur-sm"
            onClick={() => setOpen(false)}
            aria-label="Close menu"
          />
          <div className="absolute inset-y-0 right-0 flex w-[86%] max-w-sm flex-col bg-ivory p-6 shadow-2xl">
            <div className="flex items-center justify-between">
              <Logo />
              <button
                type="button"
                onClick={() => setOpen(false)}
                className="inline-flex size-10 items-center justify-center rounded-full border border-border text-navy"
                aria-label="Close menu"
              >
                <X className="size-5" />
              </button>
            </div>
            <nav className="mt-12 flex flex-col gap-1">
              {LINKS.map((link) => (
                <Link
                  key={link.href}
                  href={link.href}
                  onClick={() => setOpen(false)}
                  className="border-b border-border/70 py-4 font-heading text-2xl text-navy"
                >
                  {link.label}
                </Link>
              ))}
            </nav>
            <div className="mt-auto space-y-4 pt-8">
              <a
                href="tel:+2348000000000"
                className="flex items-center gap-2 text-sm text-muted-foreground"
              >
                <Phone className="size-4" />
                +234 800 000 0000
              </a>
              <Link
                href="/book"
                onClick={() => setOpen(false)}
                className="flex h-12 items-center justify-center gap-2 rounded-full bg-navy text-sm font-semibold text-white"
              >
                Book your stay
                <ArrowUpRight className="size-4" />
              </Link>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
