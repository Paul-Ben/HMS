"use client";

import { useEffect, type ReactNode } from "react";
import { X, type LucideIcon } from "lucide-react";
import { cn } from "@/lib/utils";

export type Tone = "green" | "gold" | "red" | "blue" | "neutral" | "clay";

const TONE_CLASS: Record<Tone, string> = {
  green: "bg-emerald-50 text-emerald-700 ring-emerald-200",
  gold: "bg-gold/10 text-[#8a6b32] ring-gold/30",
  red: "bg-red-50 text-red-700 ring-red-200",
  blue: "bg-sky-50 text-sky-700 ring-sky-200",
  neutral: "bg-zinc-100 text-zinc-600 ring-zinc-200",
  clay: "bg-clay/10 text-clay ring-clay/20",
};

export function StatusPill({
  label,
  tone = "neutral",
  className,
}: {
  label: string;
  tone?: Tone;
  className?: string;
}) {
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-[10px] font-bold tracking-[0.08em] uppercase ring-1 ring-inset",
        TONE_CLASS[tone],
        className,
      )}
    >
      <span className="size-1.5 rounded-full bg-current opacity-70" />
      {label}
    </span>
  );
}

export function PageHeader({
  eyebrow,
  title,
  description,
  actions,
  badge,
}: {
  eyebrow: string;
  title: string;
  description: string;
  actions?: ReactNode;
  badge?: ReactNode;
}) {
  return (
    <div className="flex flex-col gap-5 xl:flex-row xl:items-end xl:justify-between">
      <div>
        <div className="flex flex-wrap items-center gap-2.5">
          <p className="text-[10px] font-bold tracking-[0.26em] text-gold uppercase">
            {eyebrow}
          </p>
          {badge}
        </div>
        <h1 className="mt-2 font-heading text-3xl leading-tight tracking-[-0.02em] text-navy sm:text-4xl">
          {title}
        </h1>
        <p className="mt-2 max-w-2xl text-sm leading-6 text-muted-foreground">
          {description}
        </p>
      </div>
      {actions && <div className="flex flex-wrap items-center gap-2.5">{actions}</div>}
    </div>
  );
}

export function StatCard({
  label,
  value,
  detail,
  icon: Icon,
  tone = "navy",
  trend,
}: {
  label: string;
  value: string;
  detail: string;
  icon: LucideIcon;
  tone?: "navy" | "gold" | "green" | "red" | "blue";
  trend?: string;
}) {
  const toneStyles = {
    navy: "bg-navy text-gold",
    gold: "bg-gold/15 text-[#8a6b32]",
    green: "bg-emerald-50 text-emerald-700",
    red: "bg-red-50 text-red-600",
    blue: "bg-sky-50 text-sky-700",
  };

  return (
    <div className="surface-card p-5">
      <div className="flex items-start justify-between gap-3">
        <p className="text-[10px] font-bold tracking-[0.18em] text-muted-foreground uppercase">
          {label}
        </p>
        <span
          className={cn(
            "flex size-9 shrink-0 items-center justify-center rounded-xl",
            toneStyles[tone],
          )}
        >
          <Icon className="size-4" />
        </span>
      </div>
      <p className="mt-3 font-heading text-[1.9rem] leading-none tracking-[-0.02em] text-navy">
        {value}
      </p>
      <div className="mt-2 flex items-center gap-2">
        {trend && (
          <span className="text-[10px] font-bold tracking-[0.04em] text-emerald-600">
            {trend}
          </span>
        )}
        <p className="text-[11px] text-muted-foreground">{detail}</p>
      </div>
    </div>
  );
}

export function SectionCard({
  title,
  description,
  action,
  children,
  className,
  bodyClassName,
}: {
  title: string;
  description?: string;
  action?: ReactNode;
  children: ReactNode;
  className?: string;
  bodyClassName?: string;
}) {
  return (
    <section className={cn("surface-card overflow-hidden", className)}>
      <div className="flex flex-wrap items-start justify-between gap-3 border-b border-border/70 px-5 py-4">
        <div>
          <h2 className="font-heading text-xl text-navy">{title}</h2>
          {description && (
            <p className="mt-0.5 text-[11px] leading-5 text-muted-foreground">
              {description}
            </p>
          )}
        </div>
        {action}
      </div>
      <div className={cn("p-5", bodyClassName)}>{children}</div>
    </section>
  );
}

export function ProgressBar({
  value,
  tone = "gold",
  className,
}: {
  value: number;
  tone?: "gold" | "green" | "red" | "navy";
  className?: string;
}) {
  const tones = {
    gold: "bg-gold",
    green: "bg-emerald-500",
    red: "bg-red-500",
    navy: "bg-navy",
  };
  return (
    <div className={cn("h-1.5 w-full overflow-hidden rounded-full bg-navy/8", className)}>
      <div
        className={cn("h-full rounded-full transition-all duration-500", tones[tone])}
        style={{ width: `${Math.min(100, Math.max(0, value))}%` }}
      />
    </div>
  );
}

export function Avatar({
  name,
  className,
}: {
  name: string;
  className?: string;
}) {
  const letters = name
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase())
    .join("");
  return (
    <span
      className={cn(
        "flex size-9 shrink-0 items-center justify-center rounded-full bg-navy/5 text-[10px] font-bold text-navy ring-1 ring-navy/10",
        className,
      )}
    >
      {letters}
    </span>
  );
}

export function EmptyState({
  icon: Icon,
  title,
  description,
}: {
  icon: LucideIcon;
  title: string;
  description: string;
}) {
  return (
    <div className="flex flex-col items-center justify-center rounded-xl border border-dashed border-border bg-ivory/40 px-5 py-9 text-center">
      <span className="flex size-10 items-center justify-center rounded-full bg-white text-gold ring-1 ring-border">
        <Icon className="size-4" />
      </span>
      <p className="mt-3 text-sm font-semibold text-navy">{title}</p>
      <p className="mt-1 max-w-xs text-[11px] leading-5 text-muted-foreground">
        {description}
      </p>
    </div>
  );
}

export function Modal({
  open,
  onClose,
  title,
  description,
  children,
  footer,
  size = "md",
}: {
  open: boolean;
  onClose: () => void;
  title: string;
  description?: string;
  children: ReactNode;
  footer?: ReactNode;
  size?: "sm" | "md" | "lg";
}) {
  useEffect(() => {
    if (!open) return;
    function handleKey(event: KeyboardEvent) {
      if (event.key === "Escape") onClose();
    }
    window.addEventListener("keydown", handleKey);
    const previous = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      window.removeEventListener("keydown", handleKey);
      document.body.style.overflow = previous;
    };
  }, [open, onClose]);

  if (!open) return null;

  const widths = {
    sm: "max-w-sm",
    md: "max-w-lg",
    lg: "max-w-2xl",
  };

  return (
    <div className="fixed inset-0 z-[80] flex items-end justify-center p-3 sm:items-center sm:p-5">
      <button
        type="button"
        onClick={onClose}
        className="absolute inset-0 bg-navy/55 backdrop-blur-sm"
        aria-label="Close dialog"
      />
      <div
        role="dialog"
        aria-modal="true"
        className={cn(
          "relative max-h-[92vh] w-full overflow-y-auto rounded-2xl bg-white shadow-2xl",
          widths[size],
        )}
      >
        <div className="flex items-start justify-between gap-4 border-b border-border/70 px-5 py-4">
          <div>
            <h2 className="font-heading text-2xl text-navy">{title}</h2>
            {description && (
              <p className="mt-0.5 text-[11px] leading-5 text-muted-foreground">
                {description}
              </p>
            )}
          </div>
          <button
            type="button"
            onClick={onClose}
            className="flex size-8 shrink-0 items-center justify-center rounded-full text-muted-foreground transition-colors hover:bg-muted hover:text-navy"
            aria-label="Close"
          >
            <X className="size-4" />
          </button>
        </div>
        <div className="px-5 py-5">{children}</div>
        {footer && (
          <div className="flex flex-wrap items-center justify-end gap-2.5 border-t border-border/70 bg-ivory/50 px-5 py-4">
            {footer}
          </div>
        )}
      </div>
    </div>
  );
}

export function DetailRow({
  label,
  value,
  strong,
}: {
  label: string;
  value: ReactNode;
  strong?: boolean;
}) {
  return (
    <div className="flex items-start justify-between gap-4 py-2">
      <span className="text-xs text-muted-foreground">{label}</span>
      <span
        className={cn(
          "text-right text-xs text-navy",
          strong ? "font-bold" : "font-medium",
        )}
      >
        {value}
      </span>
    </div>
  );
}
