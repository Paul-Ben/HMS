import type { Metadata } from "next";
import { Manrope, Playfair_Display } from "next/font/google";
import { Toaster } from "@/components/ui/sonner";
import "./globals.css";

const manrope = Manrope({
  variable: "--font-manrope",
  subsets: ["latin"],
  display: "swap",
});

const playfair = Playfair_Display({
  variable: "--font-playfair",
  subsets: ["latin"],
  display: "swap",
});

export const metadata: Metadata = {
  title: {
    default: "Aurelia Hotel & Suites | Victoria Island, Lagos",
    template: "%s | Aurelia Hotel & Suites",
  },
  description:
    "A quiet luxury hotel on Victoria Island, Lagos. Boutique rooms and suites, refined dining, and attentive service for business and leisure travellers.",
  keywords: [
    "Aurelia Hotel",
    "hotel in Lagos",
    "Victoria Island hotel",
    "luxury hotel Nigeria",
    "hotel booking Lagos",
  ],
  openGraph: {
    title: "Aurelia Hotel & Suites",
    description:
      "A quiet luxury hotel on Victoria Island, Lagos. Rooms, suites, dining and effortless hospitality.",
    type: "website",
  },
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html
      lang="en"
      className={`${manrope.variable} ${playfair.variable} h-full`}
    >
      <body className="flex min-h-full flex-col">
        {children}
        <Toaster position="top-right" />
      </body>
    </html>
  );
}
