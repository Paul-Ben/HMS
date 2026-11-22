"use client";

import { useSyncExternalStore } from "react";
import {
  Area,
  AreaChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { formatNaira } from "@/lib/format";

const COLLECTIONS = [
  { day: "07 Nov", rooms: 148000, other: 18000 },
  { day: "08 Nov", rooms: 186000, other: 24000 },
  { day: "09 Nov", rooms: 172000, other: 21000 },
  { day: "10 Nov", rooms: 205000, other: 32000 },
  { day: "11 Nov", rooms: 198000, other: 26000 },
  { day: "12 Nov", rooms: 258500, other: 41000 },
  { day: "13 Nov", rooms: 226000, other: 38000 },
  { day: "14 Nov", rooms: 312000, other: 56000 },
  { day: "15 Nov", rooms: 348000, other: 62000 },
  { day: "16 Nov", rooms: 284000, other: 44000 },
  { day: "17 Nov", rooms: 392000, other: 58000 },
  { day: "18 Nov", rooms: 336000, other: 49000 },
  { day: "19 Nov", rooms: 358000, other: 72000 },
  { day: "20 Nov", rooms: 284500, other: 38000 },
];

const subscribe = () => () => {};
const getSnapshot = () => true;
const getServerSnapshot = () => false;

export function CollectionsChart() {
  const mounted = useSyncExternalStore(
    subscribe,
    getSnapshot,
    getServerSnapshot,
  );

  return (
    <div className="h-[286px] w-full">
      {mounted ? (
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart
            data={COLLECTIONS}
            margin={{ top: 8, right: 4, left: -18, bottom: 0 }}
          >
            <defs>
              <linearGradient id="roomsFill" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#c7a76c" stopOpacity={0.38} />
                <stop offset="100%" stopColor="#c7a76c" stopOpacity={0.02} />
              </linearGradient>
              <linearGradient id="otherFill" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#14304a" stopOpacity={0.22} />
                <stop offset="100%" stopColor="#14304a" stopOpacity={0.01} />
              </linearGradient>
            </defs>
            <CartesianGrid vertical={false} stroke="#e5ddcf" strokeDasharray="3 6" />
            <XAxis
              dataKey="day"
              tick={{ fontSize: 10, fill: "#64707d" }}
              axisLine={false}
              tickLine={false}
              interval={1}
              dy={8}
            />
            <YAxis
              tick={{ fontSize: 10, fill: "#64707d" }}
              axisLine={false}
              tickLine={false}
              tickFormatter={(value: number) => `${Math.round(value / 1000)}k`}
            />
            <Tooltip
              cursor={{ stroke: "#c7a76c", strokeDasharray: "4 4" }}
              contentStyle={{
                borderRadius: 12,
                border: "1px solid #e5ddcf",
                fontSize: 11,
                boxShadow: "0 12px 30px -18px rgba(16,38,58,0.35)",
              }}
              formatter={(value) => [formatNaira(Number(value)), ""]}
            />
            <Area
              type="monotone"
              dataKey="rooms"
              name="Rooms"
              stroke="#c7a76c"
              strokeWidth={2}
              fill="url(#roomsFill)"
            />
            <Area
              type="monotone"
              dataKey="other"
              name="F&B & other"
              stroke="#14304a"
              strokeWidth={2}
              fill="url(#otherFill)"
            />
          </AreaChart>
        </ResponsiveContainer>
      ) : (
        <div className="h-full w-full animate-pulse rounded-xl bg-ivory/60" />
      )}
    </div>
  );
}
