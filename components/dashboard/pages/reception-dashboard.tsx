"use client";

import Link from "next/link";
import { useState } from "react";
import { toast } from "sonner";
import {
  BedDouble,
  CalendarCheck,
  CreditCard,
  Eye,
  Landmark,
  LogOut,
  Search,
  UserRound,
  Users,
  Wallet,
} from "lucide-react";
import { formatNaira, formatStayDate } from "@/lib/format";
import {
  CATEGORY_BY_SLUG,
  DEMO_TODAY,
  ROOM_STATUS_META,
  type PaymentMethod,
  type Reservation,
} from "@/lib/prototype-data";
import {
  Avatar,
  DetailRow,
  Modal,
  PageHeader,
  SectionCard,
  StatCard,
  StatusPill,
  type Tone,
} from "@/components/dashboard/dashboard-ui";
import { usePrototype } from "@/components/dashboard/prototype-provider";

type QueueTab = "arrivals" | "in-house" | "departures";
type ModalType = "view" | "checkin" | "payment" | "checkout";
type ModalState = { type: ModalType; reservationId: string } | null;

const STATUS_TONE: Record<Reservation["status"], Tone> = {
  arriving: "gold",
  "in-house": "green",
  departed: "neutral",
  confirmed: "blue",
};

const STATUS_LABEL: Record<Reservation["status"], string> = {
  arriving: "Arriving",
  "in-house": "In house",
  departed: "Departed",
  confirmed: "Confirmed",
};

function defaultRoom(reservation: Reservation, rooms: ReturnType<typeof usePrototype>["rooms"]) {
  const assigned = rooms.find((room) => room.number === reservation.roomNumber);
  if (assigned?.status === "available") return assigned.number;
  return rooms.find((room) => room.status === "available")?.number ?? "";
}

export function ReceptionDashboard() {
  const {
    rooms,
    reservations,
    payments,
    recordPayment,
    checkIn,
    checkOut,
  } = usePrototype();
  const [tab, setTab] = useState<QueueTab>("arrivals");
  const [query, setQuery] = useState("");
  const [modal, setModal] = useState<ModalState>(null);
  const [selectedRoom, setSelectedRoom] = useState("");
  const [amount, setAmount] = useState("");
  const [method, setMethod] = useState<PaymentMethod>("Cash");
  const [note, setNote] = useState("");

  const arrivals = reservations.filter((reservation) => reservation.status === "arriving");
  const inHouse = reservations.filter((reservation) => reservation.status === "in-house");
  const departures = inHouse.filter(
    (reservation) => reservation.checkOut === DEMO_TODAY,
  );
  const outstanding = reservations
    .filter((reservation) => reservation.status !== "departed")
    .reduce((sum, reservation) => sum + reservation.balance, 0);
  const pendingTransfers = payments.filter((payment) => payment.status === "Pending");
  const pendingTransferValue = pendingTransfers.reduce(
    (sum, payment) => sum + payment.amount,
    0,
  );

  const queue = tab === "arrivals" ? arrivals : tab === "in-house" ? inHouse : departures;
  const filtered = queue.filter((reservation) => {
    const term = query.trim().toLowerCase();
    if (!term) return true;
    return (
      reservation.guest.toLowerCase().includes(term) ||
      reservation.email.toLowerCase().includes(term) ||
      reservation.roomNumber.toLowerCase().includes(term) ||
      reservation.reference.toLowerCase().includes(term)
    );
  });

  const selected = modal
    ? reservations.find((reservation) => reservation.id === modal.reservationId) ?? null
    : null;
  const selectedCategory = selected
    ? CATEGORY_BY_SLUG[selected.categorySlug]
    : null;
  const availableRooms = rooms.filter((room) => room.status === "available");
  const selectedPayments = selected
    ? payments.filter((payment) => payment.reservationId === selected.id)
    : [];

  function openModal(type: ModalType, reservation: Reservation) {
    setModal({ type, reservationId: reservation.id });
    setSelectedRoom(defaultRoom(reservation, rooms));
    setAmount(String(reservation.balance > 0 ? reservation.balance : ""));
    setMethod("Cash");
    setNote("");
  }

  function closeModal() {
    setModal(null);
  }

  function handleCheckIn() {
    if (!selected) return;
    if (!selectedRoom) {
      toast.error("Select a ready room to check in.");
      return;
    }
    checkIn(selected.id, selectedRoom);
    toast.success(`${selected.guest} checked into Room ${selectedRoom}.`);
    closeModal();
  }

  function handlePayment() {
    if (!selected) return;
    const value = Number(amount);
    if (!Number.isFinite(value) || value <= 0) {
      toast.error("Enter a valid payment amount.");
      return;
    }
    if (value > selected.balance) {
      toast.error("Payment cannot exceed the outstanding balance.");
      return;
    }
    recordPayment({
      reservationId: selected.id,
      amount: value,
      method,
      receivedBy: "Ifeoma Nwankwo",
      note: note.trim() || undefined,
    });
    if (method === "Bank transfer") {
      toast.success("Transfer recorded. Accounts must verify it before the folio updates.");
    } else {
      toast.success(`${formatNaira(value)} recorded for ${selected.guest}.`);
    }
    closeModal();
  }

  function handleCheckOut() {
    if (!selected) return;
    checkOut(selected.id);
    toast.success(
      `${selected.guest} checked out. Room ${selected.roomNumber} is now dirty and housekeeping has been notified.`,
    );
    closeModal();
  }

  return (
    <div className="space-y-6">
      <PageHeader
        eyebrow="Front desk"
        title="Arrivals, guests and departures."
        description="Check guests in, take payments and close folios. Transfers are recorded now and verified later by accounts."
        badge={<StatusPill label="Shift · Ifeoma Nwankwo" tone="green" />}
        actions={
          <>
            <Link
              href="/book"
              className="inline-flex h-9 items-center gap-2 rounded-full bg-navy px-4 text-[11px] font-semibold text-white transition-colors hover:bg-navy-800"
            >
              <CalendarCheck className="size-3.5" />
              New booking
            </Link>
            <button
              type="button"
              onClick={() => setTab("arrivals")}
              className="inline-flex h-9 items-center gap-2 rounded-full border border-border bg-white px-4 text-[11px] font-semibold text-navy transition-colors hover:border-gold"
            >
              <Users className="size-3.5 text-gold" />
              {arrivals.length} arrivals
            </button>
          </>
        }
      />

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard
          label="Arrivals today"
          value={String(arrivals.length)}
          detail={`${arrivals.filter((reservation) => reservation.balance > 0).length} with a balance`}
          icon={CalendarCheck}
          tone="navy"
        />
        <StatCard
          label="In house"
          value={String(inHouse.length)}
          detail={`${departures.length} departing today`}
          icon={Users}
          tone="green"
        />
        <StatCard
          label="Departures"
          value={String(departures.length)}
          detail={`${departures.filter((reservation) => reservation.balance > 0).length} with a balance`}
          icon={LogOut}
          tone="gold"
        />
        <StatCard
          label="Outstanding"
          value={formatNaira(outstanding)}
          detail={`${reservations.filter((reservation) => reservation.balance > 0 && reservation.status !== "departed").length} open folios`}
          icon={Wallet}
          tone="red"
        />
      </div>

      <SectionCard
        title="Guest queue"
        description="Select a guest to view the folio, take a payment or check them in."
        action={
          <div className="relative">
            <Search className="pointer-events-none absolute top-1/2 left-3 size-3.5 -translate-y-1/2 text-muted-foreground" />
            <input
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="Search guest, room or reference"
              className="h-9 w-full min-w-[220px] rounded-full border border-border bg-white pr-3 pl-8 text-[11px] outline-none placeholder:text-muted-foreground/70 focus-visible:border-gold sm:w-64"
            />
          </div>
        }
        bodyClassName="p-0"
      >
        <div className="flex gap-1 overflow-x-auto border-b border-border/70 px-4 pt-3">
          {(
            [
              { key: "arrivals", label: "Arrivals", count: arrivals.length },
              { key: "in-house", label: "In house", count: inHouse.length },
              { key: "departures", label: "Departures", count: departures.length },
            ] as { key: QueueTab; label: string; count: number }[]
          ).map((item) => (
            <button
              key={item.key}
              type="button"
              onClick={() => setTab(item.key)}
              className={`relative flex items-center gap-2 px-3 pb-3 text-[11px] font-semibold transition-colors ${
                tab === item.key ? "text-navy" : "text-muted-foreground hover:text-navy"
              }`}
            >
              {item.label}
              <span
                className={`rounded-full px-1.5 py-0.5 text-[9px] ${
                  tab === item.key ? "bg-gold/20 text-[#8a6b32]" : "bg-muted text-muted-foreground"
                }`}
              >
                {item.count}
              </span>
              {tab === item.key && (
                <span className="absolute right-0 bottom-0 left-0 h-0.5 rounded-full bg-gold" />
              )}
            </button>
          ))}
        </div>

        <div className="overflow-x-auto">
          <table className="table-clean w-full min-w-[860px]">
            <thead>
              <tr className="border-b border-border/60 text-left">
                <th className="px-5 py-2.5 text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                  Guest
                </th>
                <th className="px-3 py-2.5 text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                  Room
                </th>
                <th className="px-3 py-2.5 text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                  Stay
                </th>
                <th className="px-3 py-2.5 text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                  Status
                </th>
                <th className="px-3 py-2.5 text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                  Balance
                </th>
                <th className="px-5 py-2.5 text-right text-[9px] font-bold tracking-[0.14em] text-muted-foreground uppercase">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border/60">
              {filtered.map((reservation) => {
                const category = CATEGORY_BY_SLUG[reservation.categorySlug];
                const room = rooms.find((item) => item.number === reservation.roomNumber);
                const departing = reservation.status === "in-house" && reservation.checkOut === DEMO_TODAY;
                return (
                  <tr key={reservation.id} className="hover:bg-ivory/40">
                    <td className="px-5 py-3">
                      <div className="flex items-center gap-2.5">
                        <Avatar name={reservation.guest} />
                        <div>
                          <div className="flex items-center gap-1.5">
                            <p className="text-xs font-semibold text-navy">{reservation.guest}</p>
                            {reservation.vip && (
                              <span className="rounded bg-gold/15 px-1 py-0.5 text-[7px] font-bold tracking-[0.08em] text-[#8a6b32] uppercase">
                                VIP
                              </span>
                            )}
                          </div>
                          <p className="text-[10px] text-muted-foreground">
                            {reservation.reference}
                          </p>
                        </div>
                      </div>
                    </td>
                    <td className="px-3 py-3">
                      <p className="text-xs font-semibold text-navy">
                        {reservation.roomNumber}
                      </p>
                      <p className="text-[9px] text-muted-foreground">
                        {category?.shortName}
                        {room ? ` · ${ROOM_STATUS_META[room.status].label}` : ""}
                      </p>
                    </td>
                    <td className="px-3 py-3">
                      <p className="text-[10px] text-navy">
                        {formatStayDate(reservation.checkIn)} →{" "}
                        {formatStayDate(reservation.checkOut)}
                      </p>
                      <p className="text-[9px] text-muted-foreground">
                        {reservation.nights} nights · {reservation.guests} guests
                      </p>
                    </td>
                    <td className="px-3 py-3">
                      <StatusPill
                        label={departing ? "Departing" : STATUS_LABEL[reservation.status]}
                        tone={departing ? "clay" : STATUS_TONE[reservation.status]}
                      />
                    </td>
                    <td className="px-3 py-3">
                      <p className="text-xs font-semibold text-navy">
                        {formatNaira(reservation.balance)}
                      </p>
                      <p className="text-[9px] text-muted-foreground">
                        of {formatNaira(reservation.total)}
                      </p>
                    </td>
                    <td className="px-5 py-3">
                      <div className="flex items-center justify-end gap-1.5">
                        <button
                          type="button"
                          onClick={() => openModal("view", reservation)}
                          className="flex size-8 items-center justify-center rounded-full border border-border text-muted-foreground transition-colors hover:border-gold hover:text-navy"
                          aria-label={`View ${reservation.guest}`}
                        >
                          <Eye className="size-3.5" />
                        </button>
                        {reservation.status === "arriving" && (
                          <button
                            type="button"
                            onClick={() => openModal("checkin", reservation)}
                            className="inline-flex h-8 items-center gap-1 rounded-full bg-navy px-3 text-[10px] font-semibold text-white transition-colors hover:bg-navy-800"
                          >
                            Check in
                          </button>
                        )}
                        {reservation.balance > 0 && reservation.status !== "departed" && (
                          <button
                            type="button"
                            onClick={() => openModal("payment", reservation)}
                            className="inline-flex h-8 items-center gap-1 rounded-full border border-gold/40 bg-gold/10 px-3 text-[10px] font-semibold text-[#8a6b32] transition-colors hover:bg-gold/20"
                          >
                            <CreditCard className="size-3" />
                            Pay
                          </button>
                        )}
                        {departing && (
                          <button
                            type="button"
                            onClick={() => openModal("checkout", reservation)}
                            className="inline-flex h-8 items-center gap-1 rounded-full border border-clay/30 bg-clay/10 px-3 text-[10px] font-semibold text-clay transition-colors hover:bg-clay/20"
                          >
                            Check out
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                );
              })}
              {filtered.length === 0 && (
                <tr>
                  <td colSpan={6} className="px-5 py-12 text-center">
                    <UserRound className="mx-auto size-5 text-muted-foreground" />
                    <p className="mt-2 text-xs font-semibold text-navy">No guests in this queue</p>
                    <p className="mt-1 text-[10px] text-muted-foreground">
                      {query ? "Try a different search term." : "Everything is up to date."}
                    </p>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </SectionCard>

      <div className="grid gap-5 lg:grid-cols-[1.25fr_0.9fr]">
        <SectionCard
          title="Room rack"
          description={`${availableRooms.length} rooms ready to sell · ${rooms.length} total`}
          action={
            <div className="flex flex-wrap items-center gap-2">
              {(["available", "occupied", "dirty", "inspection"] as const).map((status) => (
                <span key={status} className="flex items-center gap-1 text-[9px] text-muted-foreground">
                  <span className={`size-1.5 rounded-full ${ROOM_STATUS_META[status].dot}`} />
                  {ROOM_STATUS_META[status].label}
                </span>
              ))}
            </div>
          }
        >
          <div className="grid grid-cols-4 gap-2 sm:grid-cols-6 lg:grid-cols-5 xl:grid-cols-6">
            {rooms.map((room) => {
              const meta = ROOM_STATUS_META[room.status];
              return (
                <div
                  key={room.number}
                  className="rounded-lg border border-border/70 bg-white px-2 py-2.5 text-center"
                  title={`${room.floor} · ${meta.label}${room.guest ? ` · ${room.guest}` : ""}`}
                >
                  <p className="text-[11px] font-bold text-navy">{room.number}</p>
                  <span className="mt-1 inline-flex items-center gap-1 text-[8px] text-muted-foreground">
                    <span className={`size-1.5 rounded-full ${meta.dot}`} />
                    {meta.label}
                  </span>
                </div>
              );
            })}
          </div>
        </SectionCard>

        <div className="space-y-5">
          <SectionCard
            title="Pending transfers"
            description="Awaiting accounts verification"
            action={
              <Link
                href="/dashboard/accountant"
                className="text-[10px] font-bold tracking-[0.08em] text-gold uppercase hover:text-navy"
              >
                Accounts
              </Link>
            }
          >
            <div className="flex items-center justify-between rounded-xl bg-gold/10 px-4 py-3">
              <div className="flex items-center gap-3">
                <span className="flex size-9 items-center justify-center rounded-full bg-white text-gold ring-1 ring-gold/20">
                  <Landmark className="size-4" />
                </span>
                <div>
                  <p className="text-lg font-heading text-navy">{pendingTransfers.length}</p>
                  <p className="text-[9px] font-semibold tracking-[0.08em] text-muted-foreground uppercase">
                    transfers
                  </p>
                </div>
              </div>
              <p className="text-sm font-semibold text-navy">
                {formatNaira(pendingTransferValue)}
              </p>
            </div>
            <div className="mt-3 space-y-2">
              {pendingTransfers.slice(0, 3).map((payment) => (
                <div key={payment.id} className="flex items-center justify-between text-[10px]">
                  <span className="text-muted-foreground">{payment.guest}</span>
                  <span className="font-semibold text-navy">{formatNaira(payment.amount)}</span>
                </div>
              ))}
            </div>
            <p className="mt-3 text-[10px] leading-4 text-muted-foreground">
              Front desk records the transfer. Accounts verifies the credit before
              it is applied to the folio.
            </p>
          </SectionCard>

          <SectionCard title="Front desk notes" description="Shift handover">
            <div className="space-y-2.5 text-[10px] leading-5 text-muted-foreground">
              <p>
                <span className="font-semibold text-navy">Anniversary setup:</span>{" "}
                Room 401 — sparkling water and a card, please.
              </p>
              <p>
                <span className="font-semibold text-navy">Late arrival:</span>{" "}
                Tunde Balogun, Room 205, ETA 19:30. Key prepared.
              </p>
              <p>
                <span className="font-semibold text-navy">VIP:</span> Fatima
                Yusuf, Penthouse, arrives 13:30. Butler already briefed.
              </p>
            </div>
          </SectionCard>
        </div>
      </div>

      <Modal
        open={Boolean(modal && selected)}
        onClose={closeModal}
        title={
          modal?.type === "view"
            ? "Guest profile"
            : modal?.type === "checkin"
              ? "Check in guest"
              : modal?.type === "payment"
                ? "Record payment"
                : "Check out guest"
        }
        description={
          selected
            ? `${selected.guest} · Room ${selected.roomNumber} · ${selected.reference}`
            : undefined
        }
        size="md"
      >
        {selected && modal?.type === "view" && (
          <div>
            <div className="flex items-start justify-between gap-4">
              <div className="flex items-center gap-3">
                <Avatar name={selected.guest} className="size-11" />
                <div>
                  <div className="flex items-center gap-2">
                    <p className="font-heading text-2xl text-navy">{selected.guest}</p>
                    {selected.vip && <StatusPill label="VIP" tone="gold" />}
                  </div>
                  <p className="mt-0.5 text-[11px] text-muted-foreground">
                    {selected.email}
                  </p>
                  <p className="text-[11px] text-muted-foreground">{selected.phone}</p>
                </div>
              </div>
              <StatusPill label={STATUS_LABEL[selected.status]} tone={STATUS_TONE[selected.status]} />
            </div>

            <div className="mt-4 grid grid-cols-2 gap-3">
              <div className="rounded-xl bg-ivory p-3">
                <p className="field-label">Stay</p>
                <p className="mt-1 text-xs font-semibold text-navy">
                  {formatStayDate(selected.checkIn)} → {formatStayDate(selected.checkOut)}
                </p>
                <p className="text-[10px] text-muted-foreground">
                  {selected.nights} nights · {selected.guests} guests
                </p>
              </div>
              <div className="rounded-xl bg-ivory p-3">
                <p className="field-label">Room</p>
                <p className="mt-1 text-xs font-semibold text-navy">
                  {selected.roomNumber} · {selectedCategory?.shortName}
                </p>
                <p className="text-[10px] text-muted-foreground">
                  {selectedCategory?.bed}
                </p>
              </div>
            </div>

            <div className="mt-3 rounded-xl border border-border/70 bg-white p-4">
              <p className="field-label">Folio</p>
              <div className="mt-2 divide-y divide-border/60">
                <DetailRow label="Total charges" value={formatNaira(selected.total)} />
                <DetailRow label="Paid to date" value={formatNaira(selected.paid)} />
                <DetailRow label="Balance" value={formatNaira(selected.balance)} strong />
              </div>
              {selectedPayments.length > 0 && (
                <div className="mt-3 border-t border-border/60 pt-3">
                  <p className="text-[10px] font-semibold tracking-[0.08em] text-muted-foreground uppercase">
                    Payments
                  </p>
                  <div className="mt-2 space-y-2">
                    {selectedPayments.map((payment) => (
                      <div key={payment.id} className="flex items-center justify-between text-[10px]">
                        <span className="text-muted-foreground">
                          {payment.method} · {payment.reference}
                        </span>
                        <div className="flex items-center gap-2">
                          <span className="font-semibold text-navy">
                            {formatNaira(payment.amount)}
                          </span>
                          <StatusPill
                            label={payment.status}
                            tone={payment.status === "Completed" ? "green" : payment.status === "Pending" ? "gold" : "red"}
                          />
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>

            {selected.notes && (
              <div className="mt-3 rounded-xl bg-gold/10 p-3">
                <p className="text-[10px] font-semibold tracking-[0.08em] text-[#8a6b32] uppercase">
                  Notes
                </p>
                <p className="mt-1 text-[11px] leading-5 text-navy">{selected.notes}</p>
              </div>
            )}

            <div className="mt-5 flex flex-wrap justify-end gap-2">
              {selected.status === "arriving" && (
                <button
                  type="button"
                  onClick={() => openModal("checkin", selected)}
                  className="h-10 rounded-full bg-navy px-5 text-xs font-semibold text-white hover:bg-navy-800"
                >
                  Check in
                </button>
              )}
              {selected.balance > 0 && (
                <button
                  type="button"
                  onClick={() => openModal("payment", selected)}
                  className="h-10 rounded-full bg-gold px-5 text-xs font-semibold text-navy hover:bg-gold-soft"
                >
                  Record payment
                </button>
              )}
            </div>
          </div>
        )}

        {selected && modal?.type === "checkin" && (
          <div>
            <div className="flex items-center gap-3 rounded-xl bg-ivory p-4">
              <Avatar name={selected.guest} className="size-11" />
              <div className="min-w-0 flex-1">
                <p className="text-sm font-semibold text-navy">{selected.guest}</p>
                <p className="mt-0.5 text-[11px] text-muted-foreground">
                  {selected.nights} nights · {selected.guests} guests · {selectedCategory?.shortName}
                </p>
              </div>
              {selected.vip && <StatusPill label="VIP" tone="gold" />}
            </div>

            <label className="mt-4 flex flex-col gap-2">
              <span className="field-label">Assign a ready room</span>
              <select
                value={selectedRoom}
                onChange={(event) => setSelectedRoom(event.target.value)}
                className="input-luxe appearance-none"
              >
                <option value="">Select a room</option>
                {availableRooms.map((room) => (
                  <option key={room.number} value={room.number}>
                    Room {room.number} · {CATEGORY_BY_SLUG[room.categorySlug]?.name}
                  </option>
                ))}
              </select>
            </label>

            <div className="mt-4 divide-y divide-border/60 rounded-xl border border-border/70 px-4">
              <DetailRow label="Arrival" value={`${formatStayDate(selected.checkIn)} · ${selected.eta}`} />
              <DetailRow label="Departure" value={formatStayDate(selected.checkOut)} />
              <DetailRow label="Balance" value={formatNaira(selected.balance)} strong />
            </div>

            {selected.balance > 0 && (
              <p className="mt-3 rounded-lg bg-gold/10 px-3 py-2 text-[10px] leading-5 text-[#8a6b32]">
                This guest still has an outstanding balance. You can check them in
                and take payment now or at departure.
              </p>
            )}

            <div className="mt-5 flex flex-wrap justify-end gap-2">
              <button
                type="button"
                onClick={() => openModal("payment", selected)}
                className="h-10 rounded-full border border-border px-5 text-xs font-semibold text-navy hover:border-gold"
              >
                Take payment
              </button>
              <button
                type="button"
                onClick={handleCheckIn}
                disabled={!selectedRoom}
                className="h-10 rounded-full bg-navy px-5 text-xs font-semibold text-white hover:bg-navy-800 disabled:cursor-not-allowed disabled:opacity-50"
              >
                Confirm check-in
              </button>
            </div>
          </div>
        )}

        {selected && modal?.type === "payment" && (
          <div>
            <div className="flex items-center justify-between rounded-xl bg-ivory p-4">
              <div>
                <p className="field-label">Outstanding</p>
                <p className="mt-1 font-heading text-3xl text-navy">
                  {formatNaira(selected.balance)}
                </p>
                <p className="mt-0.5 text-[10px] text-muted-foreground">
                  {selected.guest} · Room {selected.roomNumber}
                </p>
              </div>
              <CreditCard className="size-7 text-gold" />
            </div>

            <div className="mt-4 grid gap-4 sm:grid-cols-2">
              <label className="flex flex-col gap-2">
                <span className="field-label">Amount</span>
                <input
                  type="number"
                  min={1}
                  max={selected.balance}
                  value={amount}
                  onChange={(event) => setAmount(event.target.value)}
                  className="input-luxe"
                />
              </label>
              <label className="flex flex-col gap-2">
                <span className="field-label">Method</span>
                <select
                  value={method}
                  onChange={(event) => setMethod(event.target.value as PaymentMethod)}
                  className="input-luxe appearance-none"
                >
                  <option value="Cash">Cash</option>
                  <option value="POS">POS</option>
                  <option value="Bank transfer">Bank transfer</option>
                  <option value="Paystack">Paystack link</option>
                </select>
              </label>
            </div>

            <label className="mt-4 flex flex-col gap-2">
              <span className="field-label">Note (optional)</span>
              <input
                value={note}
                onChange={(event) => setNote(event.target.value)}
                placeholder="Reference or desk note"
                className="input-luxe"
              />
            </label>

            {method === "Bank transfer" && (
              <p className="mt-3 rounded-lg bg-gold/10 px-3 py-2 text-[10px] leading-5 text-[#8a6b32]">
                Bank transfers are recorded as pending and do not reduce the
                guest balance until accounts verifies the credit.
              </p>
            )}

            <div className="mt-5 flex justify-end gap-2">
              <button
                type="button"
                onClick={closeModal}
                className="h-10 rounded-full border border-border px-5 text-xs font-semibold text-navy hover:border-gold"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handlePayment}
                className="h-10 rounded-full bg-gold px-5 text-xs font-semibold text-navy hover:bg-gold-soft"
              >
                Record payment
              </button>
            </div>
          </div>
        )}

        {selected && modal?.type === "checkout" && (
          <div>
            <div className="flex items-center gap-3 rounded-xl bg-ivory p-4">
              <span className="flex size-10 items-center justify-center rounded-full bg-white text-clay ring-1 ring-border">
                <BedDouble className="size-4" />
              </span>
              <div>
                <p className="text-sm font-semibold text-navy">{selected.guest}</p>
                <p className="mt-0.5 text-[11px] text-muted-foreground">
                  Room {selected.roomNumber} · departing today
                </p>
              </div>
            </div>

            <div className="mt-4 divide-y divide-border/60 rounded-xl border border-border/70 px-4">
              <DetailRow label="Folio total" value={formatNaira(selected.total)} />
              <DetailRow label="Paid to date" value={formatNaira(selected.paid)} />
              <DetailRow label="Balance" value={formatNaira(selected.balance)} strong />
            </div>

            {selected.balance > 0 ? (
              <div className="mt-3 rounded-xl bg-red-50 p-3">
                <p className="text-xs font-semibold text-red-700">
                  This folio still has an outstanding balance.
                </p>
                <p className="mt-1 text-[10px] leading-5 text-red-600/80">
                  Settle it now, or check out and leave the balance open for
                  finance to invoice. The room will be released to housekeeping.
                </p>
                <button
                  type="button"
                  onClick={() => openModal("payment", selected)}
                  className="mt-2 text-[10px] font-bold tracking-[0.08em] text-red-700 uppercase hover:text-navy"
                >
                  Take payment first
                </button>
              </div>
            ) : (
              <p className="mt-3 rounded-lg bg-emerald-50 px-3 py-2 text-[10px] leading-5 text-emerald-700">
                Folio is fully settled. Checkout will release the room to
                housekeeping.
              </p>
            )}

            <div className="mt-5 flex justify-end gap-2">
              <button
                type="button"
                onClick={closeModal}
                className="h-10 rounded-full border border-border px-5 text-xs font-semibold text-navy hover:border-gold"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleCheckOut}
                className="h-10 rounded-full bg-navy px-5 text-xs font-semibold text-white hover:bg-navy-800"
              >
                Check out
              </button>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}
