import type { Metadata } from "next";
import { DashboardShell } from "@/components/dashboard/dashboard-shell";
import { PrototypeProvider } from "@/components/dashboard/prototype-provider";

export const metadata: Metadata = {
  title: "Staff dashboard",
  description: "Aurelia Hotel & Suites operations dashboard prototype.",
  robots: { index: false, follow: false },
};

export default function DashboardLayout({ children }: LayoutProps<"/dashboard">) {
  return (
    <PrototypeProvider>
      <DashboardShell>{children}</DashboardShell>
    </PrototypeProvider>
  );
}
