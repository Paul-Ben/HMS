import type { Metadata } from "next";
import Image from "next/image";
import { Clock, Mail, MapPin, Phone } from "lucide-react";
import { ContactForm } from "@/components/site/contact-form";

export const metadata: Metadata = {
  title: "Contact",
  description:
    "Contact Aurelia Hotel & Suites on Victoria Island, Lagos. Reservations, dining and general enquiries.",
};

export default function ContactPage() {
  return (
    <>
      <section className="relative overflow-hidden bg-navy pt-32 pb-20 text-white">
        <Image
          src="https://images.unsplash.com/photo-1564501049412-61c2a3083791?auto=format&fit=crop&w=2000&q=80"
          alt=""
          fill
          priority
          sizes="100vw"
          className="object-cover opacity-25"
        />
        <div className="absolute inset-0 bg-gradient-to-r from-navy via-navy/80 to-navy/30" />
        <div className="container-page relative z-10">
          <p className="eyebrow">Contact</p>
          <h1 className="mt-3 max-w-2xl font-heading text-5xl leading-[1.02] tracking-[-0.03em] sm:text-6xl">
            We are here, and we answer.
          </h1>
          <p className="mt-5 max-w-xl text-sm leading-7 text-white/60">
            For reservations, dining, events or anything else, reach the front
            desk. A real person will reply.
          </p>
        </div>
      </section>

      <section className="container-page py-16 lg:py-24">
        <div className="grid gap-14 lg:grid-cols-[0.9fr_1.1fr]">
          <div>
            <p className="eyebrow">Find us</p>
            <h2 className="mt-3 font-heading text-4xl text-navy">
              12 Akin Adesola Street
            </h2>
            <p className="mt-2 text-sm text-muted-foreground">
              Victoria Island, Lagos, Nigeria
            </p>

            <div className="mt-8 space-y-5 border-y border-border py-7">
              <div className="flex items-start gap-4">
                <span className="flex size-10 shrink-0 items-center justify-center rounded-full bg-ivory text-gold">
                  <Phone className="size-4" />
                </span>
                <div>
                  <p className="text-xs font-semibold tracking-[0.12em] text-muted-foreground uppercase">
                    Front desk
                  </p>
                  <a href="tel:+2348000000000" className="mt-1 block text-sm font-semibold text-navy hover:text-gold">
                    +234 800 000 0000
                  </a>
                  <a href="tel:+2348000000001" className="mt-0.5 block text-sm text-navy/65 hover:text-gold">
                    +234 800 000 0001
                  </a>
                </div>
              </div>
              <div className="flex items-start gap-4">
                <span className="flex size-10 shrink-0 items-center justify-center rounded-full bg-ivory text-gold">
                  <Mail className="size-4" />
                </span>
                <div>
                  <p className="text-xs font-semibold tracking-[0.12em] text-muted-foreground uppercase">
                    Email
                  </p>
                  <a href="mailto:reservations@example.com" className="mt-1 block text-sm font-semibold text-navy hover:text-gold">
                    reservations@example.com
                  </a>
                  <a href="mailto:hello@example.com" className="mt-0.5 block text-sm text-navy/65 hover:text-gold">
                    hello@example.com
                  </a>
                </div>
              </div>
              <div className="flex items-start gap-4">
                <span className="flex size-10 shrink-0 items-center justify-center rounded-full bg-ivory text-gold">
                  <Clock className="size-4" />
                </span>
                <div>
                  <p className="text-xs font-semibold tracking-[0.12em] text-muted-foreground uppercase">
                    Opening hours
                  </p>
                  <p className="mt-1 text-sm font-semibold text-navy">
                    Reception · 24 hours
                  </p>
                  <p className="mt-0.5 text-sm text-navy/65">
                    The Terrace · 06:30–22:30
                  </p>
                </div>
              </div>
            </div>

            <div className="relative mt-8 aspect-[4/3] overflow-hidden rounded-2xl bg-navy">
              <Image
                src="https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1400&q=80"
                alt="Aurelia Hotel exterior and pool"
                fill
                sizes="(min-width: 1024px) 40vw, 100vw"
                className="object-cover opacity-70"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-navy/80 via-transparent to-transparent" />
              <div className="absolute bottom-5 left-5 flex items-center gap-2 text-xs font-semibold text-white">
                <MapPin className="size-4 text-gold" />
                12 Akin Adesola Street, Victoria Island
              </div>
            </div>
          </div>

          <div className="surface-card p-6 sm:p-8">
            <p className="eyebrow">Write to us</p>
            <h2 className="mt-2 font-heading text-3xl text-navy">
              How can we help?
            </h2>
            <p className="mt-2 mb-7 text-sm text-muted-foreground">
              We aim to reply within one working day.
            </p>
            <ContactForm />
          </div>
        </div>
      </section>
    </>
  );
}
