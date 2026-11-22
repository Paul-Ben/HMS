"use client";

import { toast } from "sonner";
import {
  Check,
  ClipboardCheck,
  RotateCcw,
  Sparkles,
  SprayCan,
  Timer,
  X,
} from "lucide-react";
import {
  ROOM_STATUS_META,
  type HousekeepingStatus,
} from "@/lib/prototype-data";
import {
  EmptyState,
  PageHeader,
  ProgressBar,
  SectionCard,
  StatCard,
  StatusPill,
  type Tone,
} from "@/components/dashboard/dashboard-ui";
import { usePrototype } from "@/components/dashboard/prototype-provider";

const COLUMNS: {
  key: HousekeepingStatus;
  label: string;
  hint: string;
  tone: Tone;
}[] = [
  { key: "dirty", label: "Dirty", hint: "Waiting to start", tone: "clay" },
  { key: "cleaning", label: "Cleaning", hint: "In progress", tone: "gold" },
  { key: "inspection", label: "Inspection", hint: "Supervisor check", tone: "blue" },
  { key: "clean", label: "Clean", hint: "Ready to sell", tone: "green" },
];

export function HousekeepingDashboard() {
  const { housekeeping, rooms, advanceHousekeeping, rejectInspection } =
    usePrototype();

  const byStatus = (status: HousekeepingStatus) =>
    housekeeping.filter((task) => task.status === status);
  const availableRooms = rooms.filter((room) => room.status === "available");
  const dirtyRooms = rooms.filter((room) => room.status === "dirty");
  const floors = Array.from(new Set(rooms.map((room) => room.floor)));

  function handleAdvance(taskId: string, roomNumber: string, nextLabel: string) {
    advanceHousekeeping(taskId);
    toast.success(`Room ${roomNumber} ${nextLabel}.`);
  }

  function handleReject(taskId: string, roomNumber: string) {
    rejectInspection(taskId);
    toast.error(`Room ${roomNumber} returned to cleaning.`);
  }

  return (
    <div className="space-y-6">
      <PageHeader
        eyebrow="Housekeeping"
        title="Every room, ready on time."
        description="Move rooms through the turnover board and release them back to the front desk only after inspection."
        badge={<StatusPill label="Shift · Mercy Adeyemi" tone="green" />}
        actions={
          <div className="inline-flex items-center gap-2 rounded-full border border-border bg-white px-4 py-2 text-[11px] font-semibold text-navy">
            <Timer className="size-3.5 text-gold" />
            Turnover target · 28 min
          </div>
        }
      />

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard
          label="To start"
          value={String(byStatus("dirty").length)}
          detail={`${dirtyRooms.length} rooms marked dirty`}
          icon={SprayCan}
          tone="red"
        />
        <StatCard
          label="Cleaning now"
          value={String(byStatus("cleaning").length)}
          detail="Assigned to the floor team"
          icon={Sparkles}
          tone="gold"
        />
        <StatCard
          label="Awaiting inspection"
          value={String(byStatus("inspection").length)}
          detail="Supervisor sign-off needed"
          icon={ClipboardCheck}
          tone="blue"
        />
        <StatCard
          label="Rooms ready"
          value={String(availableRooms.length)}
          detail={`${rooms.length} rooms in the hotel`}
          icon={Check}
          tone="green"
        />
      </div>

      <SectionCard
        title="Turnover board"
        description="Dirty → cleaning → inspection → clean. Only the supervisor can release a room."
        bodyClassName="p-4"
      >
        <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
          {COLUMNS.map((column) => {
            const tasks = byStatus(column.key);
            return (
              <div
                key={column.key}
                className="rounded-xl bg-ivory/60 p-2.5 ring-1 ring-border/60"
              >
                <div className="flex items-center justify-between px-1.5 py-1">
                  <div className="flex items-center gap-2">
                    <StatusPill label={column.label} tone={column.tone} />
                    <span className="text-[10px] font-semibold text-muted-foreground">
                      {tasks.length}
                    </span>
                  </div>
                  <span className="text-[8px] text-muted-foreground">{column.hint}</span>
                </div>

                <div className="mt-2 space-y-2">
                  {tasks.map((task) => (
                    <div
                      key={task.id}
                      className="rounded-lg border border-border/70 bg-white p-3 shadow-sm"
                    >
                      <div className="flex items-start justify-between gap-2">
                        <div>
                          <p className="font-heading text-2xl leading-none text-navy">
                            {task.roomNumber}
                          </p>
                          <p className="mt-1 text-[10px] text-muted-foreground">
                            {task.type} · {task.assignee}
                          </p>
                        </div>
                        <StatusPill
                          label={task.priority}
                          tone={task.priority === "High" ? "clay" : "neutral"}
                        />
                      </div>

                      {task.notes && (
                        <p className="mt-2 rounded-md bg-ivory/80 px-2 py-1.5 text-[9px] leading-4 text-muted-foreground">
                          {task.notes}
                        </p>
                      )}

                      <div className="mt-2.5 flex items-center gap-1.5">
                        {task.status === "dirty" && (
                          <button
                            type="button"
                            onClick={() =>
                              handleAdvance(task.id, task.roomNumber, "started")
                            }
                            className="inline-flex h-7 flex-1 items-center justify-center gap-1 rounded-full bg-navy text-[9px] font-semibold text-white hover:bg-navy-800"
                          >
                            <SprayCan className="size-3" />
                            Start
                          </button>
                        )}
                        {task.status === "cleaning" && (
                          <button
                            type="button"
                            onClick={() =>
                              handleAdvance(task.id, task.roomNumber, "sent for inspection")
                            }
                            className="inline-flex h-7 flex-1 items-center justify-center gap-1 rounded-full bg-gold text-[9px] font-semibold text-navy hover:bg-gold-soft"
                          >
                            <ClipboardCheck className="size-3" />
                            Send to inspection
                          </button>
                        )}
                        {task.status === "inspection" && (
                          <>
                            <button
                              type="button"
                              onClick={() =>
                                handleAdvance(task.id, task.roomNumber, "approved and released")
                              }
                              className="inline-flex h-7 flex-1 items-center justify-center gap-1 rounded-full bg-emerald-600 text-[9px] font-semibold text-white hover:bg-emerald-700"
                            >
                              <Check className="size-3" />
                              Pass
                            </button>
                            <button
                              type="button"
                              onClick={() => handleReject(task.id, task.roomNumber)}
                              className="inline-flex h-7 items-center justify-center gap-1 rounded-full border border-red-200 px-2.5 text-[9px] font-semibold text-red-600 hover:bg-red-50"
                            >
                              <X className="size-3" />
                              Reject
                            </button>
                          </>
                        )}
                        {task.status === "clean" && (
                          <div className="flex h-7 w-full items-center justify-center gap-1 rounded-full bg-emerald-50 text-[9px] font-semibold text-emerald-700">
                            <Check className="size-3" />
                            Room released
                          </div>
                        )}
                      </div>
                    </div>
                  ))}

                  {tasks.length === 0 && (
                    <EmptyState
                      icon={column.key === "clean" ? Check : RotateCcw}
                      title={`No ${column.label.toLowerCase()} rooms`}
                      description={column.hint}
                    />
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </SectionCard>

      <div className="grid gap-5 lg:grid-cols-[1.3fr_0.9fr]">
        <SectionCard
          title="Room grid"
          description="Live status by floor. Clean rooms are immediately sellable."
        >
          <div className="space-y-5">
            {floors.map((floor) => {
              const floorRooms = rooms.filter((room) => room.floor === floor);
              return (
                <div key={floor}>
                  <div className="flex items-center justify-between">
                    <p className="text-[10px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                      {floor}
                    </p>
                    <p className="text-[9px] text-muted-foreground">
                      {floorRooms.filter((room) => room.status === "available").length}{" "}
                      ready
                    </p>
                  </div>
                  <div className="mt-2 grid grid-cols-4 gap-2 sm:grid-cols-6 lg:grid-cols-5 xl:grid-cols-7">
                    {floorRooms.map((room) => {
                      const meta = ROOM_STATUS_META[room.status];
                      return (
                        <div
                          key={room.number}
                          className="rounded-lg border border-border/70 bg-white px-2 py-2 text-center"
                          title={`${room.number} · ${meta.label}${room.guest ? ` · ${room.guest}` : ""}`}
                        >
                          <p className="text-[11px] font-bold text-navy">{room.number}</p>
                          <span className={`mx-auto mt-1 block size-1.5 rounded-full ${meta.dot}`} />
                          <p className="mt-1 truncate text-[8px] text-muted-foreground">
                            {meta.label}
                          </p>
                        </div>
                      );
                    })}
                  </div>
                </div>
              );
            })}
          </div>
        </SectionCard>

        <div className="space-y-5">
          <SectionCard title="Supervisor notes" description="Today's priorities">
            <div className="space-y-3">
              <div className="rounded-xl bg-red-50 p-3">
                <p className="text-xs font-semibold text-navy">
                  Room 108 · high priority
                </p>
                <p className="mt-1 text-[10px] leading-5 text-muted-foreground">
                  Early arrival expected. Please turn this room before 13:00.
                </p>
              </div>
              <div className="rounded-xl bg-ivory p-3">
                <p className="text-xs font-semibold text-navy">
                  Room 301 · inspection
                </p>
                <p className="mt-1 text-[10px] leading-5 text-muted-foreground">
                  Check the balcony and replace the bath mat before releasing.
                </p>
              </div>
              <div className="rounded-xl bg-gold/10 p-3">
                <p className="text-xs font-semibold text-navy">
                  Linen stock
                </p>
                <p className="mt-1 text-[10px] leading-5 text-muted-foreground">
                  Bath towels are healthy. Bed sheets are above reorder point.
                </p>
              </div>
            </div>
          </SectionCard>

          <SectionCard title="Inspection standard" description="Before releasing a room">
            <div className="space-y-2.5">
              {[
                "Bed dressed and creased, pillows squared",
                "Bathroom dry, amenities restocked",
                "Minibar checked and folio updated",
                "Air conditioning set to 22°C",
                "Final photo captured for the room log",
              ].map((item) => (
                <div key={item} className="flex items-start gap-2.5 text-[10px] leading-5 text-muted-foreground">
                  <Check className="mt-0.5 size-3 shrink-0 text-emerald-600" />
                  {item}
                </div>
              ))}
            </div>
            <div className="mt-4">
              <div className="flex items-center justify-between text-[10px]">
                <span className="text-muted-foreground">Rooms ready</span>
                <span className="font-bold text-navy">
                  {availableRooms.length}/{rooms.length}
                </span>
              </div>
              <ProgressBar
                value={(availableRooms.length / rooms.length) * 100}
                tone="green"
                className="mt-1.5"
              />
            </div>
          </SectionCard>
        </div>
      </div>
    </div>
  );
}
