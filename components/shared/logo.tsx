import Link from "next/link";
import { cn } from "@/lib/utils";

type LogoProps = {
  href?: string;
  variant?: "dark" | "light";
  className?: string;
  compact?: boolean;
};

export function Logo({
  href = "/",
  variant = "dark",
  className,
  compact = false,
}: LogoProps) {
  const isLight = variant === "light";

  return (
    <Link
      href={href}
      className={cn("group inline-flex items-center gap-3", className)}
      aria-label="Aurelia Hotel & Suites home"
    >
      <span
        className={cn(
          "flex size-10 items-center justify-center rounded-full border font-heading text-lg transition-transform duration-300 group-hover:rotate-6",
          isLight
            ? "border-gold/60 bg-white/5 text-gold"
            : "border-gold/60 bg-navy text-gold",
        )}
      >
        A
      </span>
      {!compact && (
        <span className="flex flex-col leading-none">
          <span
            className={cn(
              "font-heading text-[1.35rem] tracking-[0.02em]",
              isLight ? "text-white" : "text-navy",
            )}
          >
            Aurelia
          </span>
          <span
            className={cn(
              "mt-1 text-[0.55rem] font-semibold tracking-[0.32em] uppercase",
              isLight ? "text-gold-soft" : "text-gold",
            )}
          >
            Hotel &amp; Suites
          </span>
        </span>
      )}
    </Link>
  );
}
