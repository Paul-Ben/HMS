"use client";

import { useMemo, useState } from "react";
import { SlidersHorizontal } from "lucide-react";
import { RoomCard } from "@/components/site/room-card";
import { ROOM_CATEGORIES } from "@/lib/prototype-data";
import { cn } from "@/lib/utils";

const FILTERS = [
  { slug: "all", label: "All rooms" },
  ...ROOM_CATEGORIES.map((category) => ({
    slug: category.slug,
    label: category.shortName,
  })),
];

export function RoomsExplorer() {
  const [filter, setFilter] = useState("all");
  const [sort, setSort] = useState("recommended");

  const categories = useMemo(() => {
    const filtered =
      filter === "all"
        ? [...ROOM_CATEGORIES]
        : ROOM_CATEGORIES.filter((category) => category.slug === filter);

    if (sort === "low") {
      return filtered.sort((a, b) => a.rate - b.rate);
    }
    if (sort === "high") {
      return filtered.sort((a, b) => b.rate - a.rate);
    }
    return filtered;
  }, [filter, sort]);

  return (
    <div>
      <div className="flex flex-col gap-5 border-y border-border py-5 sm:flex-row sm:items-center sm:justify-between">
        <div className="no-scrollbar flex gap-2 overflow-x-auto">
          {FILTERS.map((item) => (
            <button
              key={item.slug}
              type="button"
              onClick={() => setFilter(item.slug)}
              className={cn(
                "shrink-0 rounded-full px-4 py-2 text-xs font-semibold tracking-[0.08em] uppercase transition-colors",
                filter === item.slug
                  ? "bg-navy text-white"
                  : "border border-border bg-white text-navy/65 hover:border-gold hover:text-navy",
              )}
            >
              {item.label}
            </button>
          ))}
        </div>
        <label className="flex shrink-0 items-center gap-2 text-xs font-medium text-muted-foreground">
          <SlidersHorizontal className="size-4 text-gold" />
          <span className="sr-only">Sort rooms</span>
          <select
            value={sort}
            onChange={(event) => setSort(event.target.value)}
            className="h-9 rounded-full border border-border bg-white px-3 text-xs font-semibold text-navy outline-none focus:border-gold"
          >
            <option value="recommended">Recommended</option>
            <option value="low">Price: low to high</option>
            <option value="high">Price: high to low</option>
          </select>
        </label>
      </div>

      <p className="mt-5 text-xs text-muted-foreground">
        {categories.length} room {categories.length === 1 ? "style" : "styles"} ·
        Rates shown per night, breakfast included
      </p>

      <div className="mt-8 grid gap-6 md:grid-cols-2 xl:grid-cols-3">
        {categories.map((category) => (
          <RoomCard key={category.slug} category={category} />
        ))}
      </div>
    </div>
  );
}
