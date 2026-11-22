"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useState, type ReactNode } from "react";
import { toast } from "sonner";
import {
  CalendarDays,
  ChevronDown,
  ExternalLink,
  Eye,
  LogOut,
  Menu,
  RotateCcw,
  X,
} from "lucide-react";
import { Logo } from "@/components/shared/logo";
import { NAV_SECTIONS, ROLES, roleFromPath } from "@/lib/roles";
import { usePrototype } from "@/components/dashboard/prototype-provider";
import { cn } from "@/lib/utils";

export function DashboardShell({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const { resetDemo } = usePrototype();
  const [mobileOpen, setMobileOpen] = useState(false);
  const role = roleFromPath(pathname);

  function handleReset() {
    resetDemo();
    toast.success("Prototype data reset to the start of the review day.");
  }

  function handleRoleChange(nextRole: string) {
    router.push(`/dashboard/${nextRole}`);
    setMobileOpen(false);
  }

  const sidebar = (
    <div className="flex h-full flex-col bg-sidebar text-sidebar-foreground">
      <div className="flex h-20 shrink-0 items-center justify-between border-b border-sidebar-border px-5">
        <Logo variant="light" href="/dashboard/owner" />
        <button
          type="button"
          onClick={() => setMobileOpen(false)}
          className="flex size-8 items-center justify-center rounded-full text-white/60 hover:bg-white/10 hover:text-white lg:hidden"
          aria-label="Close navigation"
        >
          <X className="size-4" />
        </button>
      </div>

      <div className="no-scrollbar flex-1 overflow-y-auto px-3 py-5">
        <div className="mb-5 flex items-center gap-2.5 rounded-xl bg-white/5 px-3 py-2.5 ring-1 ring-white/10">
          <span className="flex size-8 items-center justify-center rounded-full bg-gold/15 text-[10px] font-bold text-gold">
            {role.label.slice(0, 2).toUpperCase()}
          </span>
          <div className="min-w-0">
            <p className="truncate text-xs font-semibold text-white">
              {role.person}
            </p>
            <p className="truncate text-[10px] text-white/45">{role.title}</p>
          </div>
          {role.readOnly && (
            <span className="ml-auto flex size-6 items-center justify-center rounded-full bg-gold/15 text-gold">
              <Eye className="size-3" />
            </span>
          )}
        </div>

        <nav className="space-y-5">
          {NAV_SECTIONS.map((section) => (
            <div key={section.label}>
              <p className="px-3 pb-2 text-[9px] font-bold tracking-[0.22em] text-white/35 uppercase">
                {section.label}
              </p>
              <div className="space-y-0.5">
                {section.items.map((item) => {
                  const href = `/dashboard/${item.slug}`;
                  const active = pathname === href;
                  return (
                    <Link
                      key={item.slug}
                      href={href}
                      onClick={() => setMobileOpen(false)}
                      className={cn(
                        "group flex items-center gap-3 rounded-lg px-3 py-2.5 text-[12px] font-medium transition-colors",
                        active
                          ? "bg-gold text-navy"
                          : "text-white/60 hover:bg-white/5 hover:text-white",
                      )}
                    >
                      <item.icon
                        className={cn(
                          "size-4",
                          active ? "text-navy" : "text-white/40 group-hover:text-gold",
                        )}
                      />
                      <span>{item.label}</span>
                      {active && (
                        <span className="ml-auto size-1.5 rounded-full bg-navy/60" />
                      )}
                    </Link>
                  );
                })}
              </div>
            </div>
          ))}
        </nav>
      </div>

      <div className="shrink-0 border-t border-sidebar-border p-3">
        <button
          type="button"
          onClick={handleReset}
          className="flex w-full items-center gap-2.5 rounded-lg px-3 py-2.5 text-[11px] font-medium text-white/55 transition-colors hover:bg-white/5 hover:text-white"
        >
          <RotateCcw className="size-3.5" />
          Reset demo data
        </button>
        <Link
          href="/"
          className="flex w-full items-center gap-2.5 rounded-lg px-3 py-2.5 text-[11px] font-medium text-white/55 transition-colors hover:bg-white/5 hover:text-white"
        >
          <LogOut className="size-3.5" />
          Exit to public site
        </Link>
        <div className="mt-2 flex items-center gap-2 rounded-lg bg-white/5 px-3 py-2.5">
          <span className="size-1.5 rounded-full bg-emerald-400" />
          <p className="text-[10px] text-white/40">
            Prototype · sample data only
          </p>
        </div>
      </div>
    </div>
  );

  return (
    <div className="min-h-screen bg-[#f4f1ea]">
      <aside className="fixed inset-y-0 left-0 z-40 hidden w-[270px] lg:block">
        {sidebar}
      </aside>

      {mobileOpen && (
        <div className="fixed inset-0 z-[70] lg:hidden">
          <button
            type="button"
            className="absolute inset-0 bg-navy/60 backdrop-blur-sm"
            onClick={() => setMobileOpen(false)}
            aria-label="Close navigation"
          />
          <aside className="absolute inset-y-0 left-0 w-[280px] shadow-2xl">
            {sidebar}
          </aside>
        </div>
      )}

      <div className="lg:pl-[270px]">
        <header className="sticky top-0 z-30 border-b border-border/70 bg-[#fbf9f4]/90 backdrop-blur-xl">
          <div className="flex h-16 items-center gap-3 px-4 sm:px-6 lg:px-8">
            <button
              type="button"
              onClick={() => setMobileOpen(true)}
              className="flex size-9 items-center justify-center rounded-lg border border-border bg-white text-navy lg:hidden"
              aria-label="Open navigation"
            >
              <Menu className="size-4" />
            </button>

            <div className="min-w-0">
              <p className="flex items-center gap-2 text-[9px] font-bold tracking-[0.2em] text-muted-foreground uppercase">
                Dashboard
                {role.readOnly && (
                  <span className="hidden items-center gap-1 rounded-full bg-gold/15 px-2 py-0.5 text-[8px] text-[#8a6b32] sm:inline-flex">
                    <Eye className="size-2.5" />
                    Read-only
                  </span>
                )}
              </p>
              <p className="truncate text-sm font-semibold text-navy">
                {role.label} · {role.person}
              </p>
            </div>

            <div className="ml-auto flex items-center gap-2">
              <span className="hidden items-center gap-1.5 text-[11px] text-muted-foreground xl:flex">
                <CalendarDays className="size-3.5" />
                Fri, 20 Nov 2026
              </span>
              <Link
                href="/"
                className="hidden h-8 items-center gap-1.5 rounded-full border border-border bg-white px-3 text-[10px] font-semibold text-navy transition-colors hover:border-gold sm:flex"
              >
                Public site
                <ExternalLink className="size-3" />
              </Link>
              <button
                type="button"
                onClick={handleReset}
                className="flex size-8 items-center justify-center rounded-full border border-border bg-white text-muted-foreground transition-colors hover:border-gold hover:text-navy"
                aria-label="Reset demo data"
                title="Reset demo data"
              >
                <RotateCcw className="size-3.5" />
              </button>
              <div className="relative">
                <select
                  aria-label="Switch role"
                  value={role.slug}
                  onChange={(event) => handleRoleChange(event.target.value)}
                  className="h-8 appearance-none rounded-full border border-border bg-white pr-8 pl-3 text-[10px] font-semibold text-navy outline-none focus-visible:border-gold"
                >
                  {ROLES.map((option) => (
                    <option key={option.slug} value={option.slug}>
                      {option.label}
                    </option>
                  ))}
                </select>
                <ChevronDown className="pointer-events-none absolute top-1/2 right-2.5 size-3 -translate-y-1/2 text-muted-foreground" />
              </div>
              <span className="flex size-8 items-center justify-center rounded-full bg-navy text-[9px] font-bold text-gold">
                {role.person
                  .split(" ")
                  .slice(0, 2)
                  .map((part) => part[0])
                  .join("")}
              </span>
            </div>
          </div>
        </header>

        <main className="mx-auto w-full max-w-[1500px] px-4 py-6 sm:px-6 lg:px-8 lg:py-8">
          {children}
        </main>
      </div>
    </div>
  );
}
