import {
  BedDouble,
  ClipboardCheck,
  ConciergeBell,
  CookingPot,
  Crown,
  HandCoins,
  Hotel,
  LayoutDashboard,
  Martini,
  Package,
  Shirt,
  SprayCan,
  UtensilsCrossed,
} from "lucide-react";
import type { LucideIcon } from "lucide-react";

export type RoleSlug =
  | "owner"
  | "manager"
  | "receptionist"
  | "housekeeping"
  | "laundry"
  | "kitchen"
  | "bar"
  | "waiter"
  | "accountant"
  | "inventory";

export type RoleDefinition = {
  slug: RoleSlug;
  label: string;
  person: string;
  title: string;
  description: string;
  icon: LucideIcon;
  readOnly?: boolean;
};

export const ROLES: RoleDefinition[] = [
  {
    slug: "owner",
    label: "Owner",
    person: "Adebayo Johnson",
    title: "Executive overview",
    description: "Revenue, occupancy and the health of the hotel at a glance.",
    icon: Crown,
    readOnly: true,
  },
  {
    slug: "manager",
    label: "Manager",
    person: "Amara Osei",
    title: "Operations desk",
    description: "Run the day: arrivals, exceptions, service pace and staff.",
    icon: LayoutDashboard,
  },
  {
    slug: "receptionist",
    label: "Receptionist",
    person: "Ifeoma Nwankwo",
    title: "Front desk",
    description: "Arrivals, in-house guests, departures and payments.",
    icon: ConciergeBell,
  },
  {
    slug: "housekeeping",
    label: "Housekeeping",
    person: "Mercy Adeyemi",
    title: "Room care",
    description: "Turn rooms around and keep every space inspection-ready.",
    icon: SprayCan,
  },
  {
    slug: "laundry",
    label: "Laundry",
    person: "Esther Bello",
    title: "Laundry desk",
    description: "Guest laundry intake, processing and delivery.",
    icon: Shirt,
  },
  {
    slug: "kitchen",
    label: "Kitchen",
    person: "Chef Tobi Adebayo",
    title: "Kitchen pass",
    description: "Tickets, preparation times and the kitchen board.",
    icon: CookingPot,
  },
  {
    slug: "bar",
    label: "Bar",
    person: "Kunle Martins",
    title: "Bar service",
    description: "Bar orders, stock cues and lounge service.",
    icon: Martini,
  },
  {
    slug: "waiter",
    label: "Waiter",
    person: "Sade Williams",
    title: "Floor service",
    description: "Collect ready orders and deliver them to the right room.",
    icon: UtensilsCrossed,
  },
  {
    slug: "accountant",
    label: "Accountant",
    person: "Bola Ajayi",
    title: "Finance desk",
    description: "Collections, reconciliations, expenses and receivables.",
    icon: HandCoins,
  },
  {
    slug: "inventory",
    label: "Inventory",
    person: "Ngozi Peters",
    title: "Stores & stock",
    description: "Stock levels, movements, suppliers and reorder points.",
    icon: Package,
  },
];

export function roleFromPath(pathname: string): RoleDefinition {
  const slug = pathname.split("/")[2] as RoleSlug | undefined;
  return ROLES.find((role) => role.slug === slug) ?? ROLES[0];
}

export const NAV_SECTIONS: {
  label: string;
  items: { slug: RoleSlug; label: string; icon: LucideIcon }[];
}[] = [
  {
    label: "Overview",
    items: [
      { slug: "owner", label: "Owner", icon: Crown },
      { slug: "manager", label: "Manager", icon: LayoutDashboard },
    ],
  },
  {
    label: "Front desk",
    items: [
      { slug: "receptionist", label: "Reception", icon: ConciergeBell },
      { slug: "housekeeping", label: "Housekeeping", icon: SprayCan },
      { slug: "laundry", label: "Laundry", icon: Shirt },
    ],
  },
  {
    label: "Food & beverage",
    items: [
      { slug: "kitchen", label: "Kitchen", icon: CookingPot },
      { slug: "bar", label: "Bar", icon: Martini },
      { slug: "waiter", label: "Waiter", icon: UtensilsCrossed },
    ],
  },
  {
    label: "Finance & stock",
    items: [
      { slug: "accountant", label: "Accounts", icon: HandCoins },
      { slug: "inventory", label: "Inventory", icon: Package },
    ],
  },
];

export const PUBLIC_ICONS = {
  hotel: Hotel,
  bed: BedDouble,
  clipboard: ClipboardCheck,
};
