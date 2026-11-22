import Link from "next/link";
import { ArrowUpRight } from "lucide-react";
import { cn } from "@/lib/utils";

type SectionHeadingProps = {
  eyebrow: string;
  title: string;
  description?: string;
  action?: { href: string; label: string };
  align?: "left" | "center";
  light?: boolean;
  className?: string;
};

export function SectionHeading({
  eyebrow,
  title,
  description,
  action,
  align = "left",
  light = false,
  className,
}: SectionHeadingProps) {
  return (
    <div
      className={cn(
        "flex flex-col gap-6 sm:flex-row sm:items-end sm:justify-between",
        align === "center" && "sm:flex-col sm:items-center sm:text-center",
        className,
      )}
    >
      <div className={cn("max-w-2xl", align === "center" && "mx-auto")}>
        <p className="eyebrow">{eyebrow}</p>
        <h2
          className={cn(
            "mt-3 font-heading text-3xl leading-[1.12] tracking-[-0.02em] sm:text-4xl lg:text-[2.75rem]",
            light ? "text-white" : "text-navy",
          )}
        >
          {title}
        </h2>
        {description && (
          <p
            className={cn(
              "mt-4 max-w-xl text-[0.95rem] leading-7",
              light ? "text-white/60" : "text-muted-foreground",
            )}
          >
            {description}
          </p>
        )}
      </div>
      {action && (
        <Link
          href={action.href}
          className={cn(
            "inline-flex shrink-0 items-center gap-2 border-b pb-1 text-sm font-semibold transition-colors",
            light
              ? "border-white/30 text-white hover:border-gold hover:text-gold"
              : "border-navy/25 text-navy hover:border-gold hover:text-gold",
          )}
        >
          {action.label}
          <ArrowUpRight className="size-4" />
        </Link>
      )}
    </div>
  );
}
