"use client";

import type { ComponentType } from "react";
import type { RoleSlug } from "@/lib/roles";
import { OwnerDashboard } from "@/components/dashboard/pages/owner-dashboard";
import { ManagerDashboard } from "@/components/dashboard/pages/manager-dashboard";
import { ReceptionDashboard } from "@/components/dashboard/pages/reception-dashboard";
import { HousekeepingDashboard } from "@/components/dashboard/pages/housekeeping-dashboard";
import { LaundryDashboard } from "@/components/dashboard/pages/laundry-dashboard";
import { KitchenDashboard } from "@/components/dashboard/pages/kitchen-dashboard";
import { BarDashboard } from "@/components/dashboard/pages/bar-dashboard";
import { WaiterDashboard } from "@/components/dashboard/pages/waiter-dashboard";
import { AccountsDashboard } from "@/components/dashboard/pages/accounts-dashboard";
import { InventoryDashboard } from "@/components/dashboard/pages/inventory-dashboard";

const PAGES: Record<RoleSlug, ComponentType> = {
  owner: OwnerDashboard,
  manager: ManagerDashboard,
  receptionist: ReceptionDashboard,
  housekeeping: HousekeepingDashboard,
  laundry: LaundryDashboard,
  kitchen: KitchenDashboard,
  bar: BarDashboard,
  waiter: WaiterDashboard,
  accountant: AccountsDashboard,
  inventory: InventoryDashboard,
};

export function DashboardRouter({ role }: { role: RoleSlug }) {
  const Page = PAGES[role] ?? OwnerDashboard;
  return <Page />;
}
