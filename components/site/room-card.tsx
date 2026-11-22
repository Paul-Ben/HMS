import Image from "next/image";
import Link from "next/link";
import { ArrowUpRight, BedDouble, Maximize, Users } from "lucide-react";
import type { RoomCategory } from "@/lib/prototype-data";
import { formatNaira } from "@/lib/format";

export function RoomCard({ category }: { category: RoomCategory }) {
  return (
    <article className="group flex flex-col overflow-hidden rounded-2xl border border-border/80 bg-white shadow-[0_1px_2px_rgba(16,38,58,0.04),0_20px_50px_-36px_rgba(16,38,58,0.35)] transition-shadow duration-300 hover:shadow-[0_24px_60px_-30px_rgba(16,38,58,0.35)]">
      <Link
        href={`/rooms/${category.slug}`}
        className="relative block aspect-[4/3] overflow-hidden"
      >
        <Image
          src={category.image}
          alt={category.name}
          fill
          sizes="(min-width: 1024px) 33vw, (min-width: 640px) 50vw, 100vw"
          className="object-cover transition-transform duration-700 group-hover:scale-[1.04]"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-navy/50 via-transparent to-transparent opacity-70" />
        {category.tag && (
          <span className="absolute top-4 left-4 rounded-full bg-ivory/95 px-3 py-1 text-[10px] font-semibold tracking-[0.18em] text-navy uppercase">
            {category.tag}
          </span>
        )}
        <span className="absolute right-4 bottom-4 rounded-full bg-gold px-3.5 py-1.5 text-xs font-bold text-navy">
          {formatNaira(category.rate)}
          <span className="font-medium text-navy/70"> / night</span>
        </span>
      </Link>

      <div className="flex flex-1 flex-col p-5">
        <div className="flex items-start justify-between gap-4">
          <h3 className="font-heading text-2xl text-navy">{category.name}</h3>
          <Link
            href={`/rooms/${category.slug}`}
            className="mt-1 flex size-8 shrink-0 items-center justify-center rounded-full border border-border text-navy transition-colors group-hover:border-gold group-hover:text-gold"
            aria-label={`View ${category.name}`}
          >
            <ArrowUpRight className="size-4" />
          </Link>
        </div>
        <p className="mt-2 line-clamp-2 text-sm leading-6 text-muted-foreground">
          {category.description}
        </p>
        <div className="mt-5 flex flex-wrap items-center gap-4 border-t border-border/70 pt-4 text-xs font-medium text-navy/60">
          <span className="flex items-center gap-1.5">
            <Maximize className="size-3.5 text-gold" />
            {category.size} sqm
          </span>
          <span className="flex items-center gap-1.5">
            <BedDouble className="size-3.5 text-gold" />
            {category.bed}
          </span>
          <span className="flex items-center gap-1.5">
            <Users className="size-3.5 text-gold" />
            Up to {category.occupancy}
          </span>
        </div>
      </div>
    </article>
  );
}
