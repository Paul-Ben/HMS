import { differenceInCalendarDays, format, parseISO } from "date-fns";

const naira = new Intl.NumberFormat("en-NG", {
  style: "currency",
  currency: "NGN",
  maximumFractionDigits: 0,
});

const nairaPrecise = new Intl.NumberFormat("en-NG", {
  style: "currency",
  currency: "NGN",
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
});

export function formatNaira(value: number) {
  return naira.format(value);
}

export function formatNairaPrecise(value: number) {
  return nairaPrecise.format(value);
}

export function formatStayDate(value: string) {
  return format(parseISO(value), "d MMM yyyy");
}

export function formatShortDate(value: string) {
  return format(parseISO(value), "EEE, d MMM");
}

export function formatTime(value: string) {
  return value;
}

export function nightsBetween(checkIn: string, checkOut: string) {
  return Math.max(1, differenceInCalendarDays(parseISO(checkOut), parseISO(checkIn)));
}

export function initials(name: string) {
  return name
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase())
    .join("");
}

export function pluralize(count: number, singular: string, plural?: string) {
  return count === 1 ? singular : plural ?? `${singular}s`;
}
