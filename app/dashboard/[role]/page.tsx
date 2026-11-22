import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { DashboardRouter } from "@/components/dashboard/dashboard-router";
import { ROLES, type RoleSlug } from "@/lib/roles";

const VALID_ROLES = new Set(ROLES.map((role) => role.slug));

export function generateStaticParams() {
  return ROLES.map((role) => ({ role: role.slug }));
}

export async function generateMetadata({
  params,
}: PageProps<"/dashboard/[role]">): Promise<Metadata> {
  const { role } = await params;
  const definition = ROLES.find((item) => item.slug === role);
  return {
    title: definition ? `${definition.label} dashboard` : "Dashboard",
  };
}

export default async function DashboardRolePage({
  params,
}: PageProps<"/dashboard/[role]">) {
  const { role } = await params;
  if (!VALID_ROLES.has(role as RoleSlug)) notFound();
  return <DashboardRouter role={role as RoleSlug} />;
}
