import type { Metadata } from "next";
import Link from "next/link";
import { ArrowLeft, LifeBuoy } from "lucide-react";
import { Logo } from "@/components/shared/logo";

export const metadata: Metadata = {
  title: "Guest portal",
  description: "Your stay, folio and payment history at Aurelia Hotel & Suites.",
};

export default function AccountLayout({ children }: LayoutProps<"/account">) {
  return (
    <div className="flex min-h-screen flex-col bg-[#f6f2ea]">
      <header className="border-b border-border/70 bg-ivory/90 backdrop-blur-xl">
        <div className="container-page flex h-20 items-center justify-between">
          <Logo />
          <div className="flex items-center gap-3">
            <Link
              href="/"
              className="hidden items-center gap-2 text-xs font-semibold text-navy/60 transition-colors hover:text-navy sm:flex"
            >
              <ArrowLeft className="size-3.5" />
              Back to the hotel
            </Link>
            <Link
              href="/contact"
              className="flex h-9 items-center gap-2 rounded-full border border-border px-4 text-xs font-semibold text-navy transition-colors hover:border-gold"
            >
              <LifeBuoy className="size-3.5 text-gold" />
              Support
            </Link>
            <span className="flex size-9 items-center justify-center rounded-full bg-navy text-xs font-bold text-gold">
              AO
            </span>
          </div>
        </div>
      </header>

      <main className="flex-1">{children}</main>

      <footer className="border-t border-border/70">
        <div className="container-page flex flex-col gap-3 py-8 text-[11px] text-muted-foreground sm:flex-row sm:items-center sm:justify-between">
          <p>© 2026 Aurelia Hotel &amp; Suites · Guest portal prototype</p>
          <div className="flex gap-5">
            <Link href="/contact" className="hover:text-navy">
              Privacy
            </Link>
            <Link href="/contact" className="hover:text-navy">
              Terms
            </Link>
            <span>Sample data only</span>
          </div>
        </div>
      </footer>
    </div>
  );
}
