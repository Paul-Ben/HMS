"use client";

import { createContext, useContext, useState, type ReactNode } from "react";
import {
  ACTIVITY,
  EXPENSES,
  HOUSEKEEPING,
  INVENTORY,
  ORDERS,
  PAYMENTS,
  RESERVATIONS,
  ROOMS,
  type Activity,
  type Expense,
  type HousekeepingTask,
  type InventoryItem,
  type OrderItem,
  type OrderKind,
  type OrderStatus,
  type Payment,
  type PaymentMethod,
  type Reservation,
  type Room,
  type ServiceOrder,
} from "@/lib/prototype-data";

type PaymentInput = {
  reservationId: string;
  amount: number;
  method: PaymentMethod;
  receivedBy: string;
  note?: string;
};

type NewOrderInput = {
  kind: OrderKind;
  source: string;
  roomNumber?: string;
  guest?: string;
  items: OrderItem[];
  note?: string;
  due?: string;
};

type PrototypeContextValue = {
  rooms: Room[];
  reservations: Reservation[];
  payments: Payment[];
  orders: ServiceOrder[];
  housekeeping: HousekeepingTask[];
  inventory: InventoryItem[];
  expenses: Expense[];
  activity: Activity[];
  checkIn: (reservationId: string, roomNumber: string) => void;
  checkOut: (reservationId: string) => void;
  recordPayment: (input: PaymentInput) => void;
  verifyPayment: (paymentId: string, approve: boolean, note?: string) => void;
  approveExpense: (expenseId: string) => void;
  payExpense: (expenseId: string) => void;
  advanceOrder: (orderId: string) => void;
  advanceHousekeeping: (taskId: string) => void;
  rejectInspection: (taskId: string) => void;
  createOrder: (input: NewOrderInput) => void;
  adjustStock: (itemId: string, delta: number) => void;
  resetDemo: () => void;
};

const PrototypeContext = createContext<PrototypeContextValue | null>(null);

function cloneOrders(source: ServiceOrder[]) {
  return source.map((order) => ({
    ...order,
    items: order.items.map((item) => ({ ...item })),
  }));
}

function nowLabel() {
  return new Date().toLocaleTimeString("en-GB", {
    hour: "2-digit",
    minute: "2-digit",
  });
}

const ORDER_FLOW: OrderStatus[] = ["new", "preparing", "ready", "delivered"];

export function PrototypeProvider({ children }: { children: ReactNode }) {
  const [rooms, setRooms] = useState<Room[]>(() => ROOMS.map((room) => ({ ...room })));
  const [reservations, setReservations] = useState<Reservation[]>(() =>
    RESERVATIONS.map((reservation) => ({ ...reservation })),
  );
  const [payments, setPayments] = useState<Payment[]>(() =>
    PAYMENTS.map((payment) => ({ ...payment })),
  );
  const [orders, setOrders] = useState<ServiceOrder[]>(() => cloneOrders(ORDERS));
  const [housekeeping, setHousekeeping] = useState<HousekeepingTask[]>(() =>
    HOUSEKEEPING.map((task) => ({ ...task })),
  );
  const [inventory, setInventory] = useState<InventoryItem[]>(() =>
    INVENTORY.map((item) => ({ ...item })),
  );
  const [expenses, setExpenses] = useState<Expense[]>(() =>
    EXPENSES.map((expense) => ({ ...expense })),
  );
  const [activity, setActivity] = useState<Activity[]>(() =>
    ACTIVITY.map((item) => ({ ...item })),
  );

  function addActivity(text: string, tone: Activity["tone"] = "blue") {
    setActivity((current) => [
      { id: `ACT-${Date.now()}`, text, time: "Just now", tone },
      ...current,
    ]);
  }

  function checkIn(reservationId: string, roomNumber: string) {
    const reservation = reservations.find((item) => item.id === reservationId);
    if (!reservation) return;

    setReservations((current) =>
      current.map((item) =>
        item.id === reservationId
          ? { ...item, status: "in-house", roomNumber }
          : item,
      ),
    );
    setRooms((current) =>
      current.map((room) =>
        room.number === roomNumber
          ? {
              ...room,
              status: "occupied",
              guest: reservation.guest,
              departure: reservation.checkOut,
            }
          : room,
      ),
    );
    addActivity(
      `${reservation.guest} checked into Room ${roomNumber}`,
      "green",
    );
  }

  function checkOut(reservationId: string) {
    const reservation = reservations.find((item) => item.id === reservationId);
    if (!reservation) return;

    setReservations((current) =>
      current.map((item) =>
        item.id === reservationId ? { ...item, status: "departed" } : item,
      ),
    );
    setRooms((current) =>
      current.map((room) =>
        room.number === reservation.roomNumber
          ? {
              ...room,
              status: "dirty",
              guest: undefined,
              departure: undefined,
            }
          : room,
      ),
    );
    setHousekeeping((current) => {
      const existing = current.find(
        (task) =>
          task.roomNumber === reservation.roomNumber && task.status !== "clean",
      );
      if (existing) {
        return current.map((task) =>
          task.id === existing.id ? { ...task, status: "dirty" } : task,
        );
      }
      return [
        {
          id: `HK-${Date.now()}`,
          roomNumber: reservation.roomNumber,
          type: "Departure",
          status: "dirty",
          assignee: "Unassigned",
          priority: "High",
          notes: `Departure turnover for ${reservation.guest}.`,
        },
        ...current,
      ];
    });
    addActivity(
      `${reservation.guest} checked out of Room ${reservation.roomNumber} · housekeeping notified`,
      "blue",
    );
  }

  function recordPayment(input: PaymentInput) {
    const reservation = reservations.find((item) => item.id === input.reservationId);
    if (!reservation || input.amount <= 0) return;

    const isPending = input.method === "Bank transfer";
    const referencePrefix =
      input.method === "Bank transfer"
        ? "TRF"
        : input.method === "Cash"
          ? "CSH"
          : input.method === "POS"
            ? "POS"
            : "PSK";
    const reference = `${referencePrefix}-${Date.now().toString().slice(-5)}`;

    const payment: Payment = {
      id: `PAY-${Date.now().toString().slice(-6)}`,
      reservationId: input.reservationId,
      guest: reservation.guest,
      roomNumber: reservation.roomNumber,
      amount: input.amount,
      method: input.method,
      status: isPending ? "Pending" : "Completed",
      reference,
      date: `20 Nov 2026 · ${nowLabel()}`,
      receivedBy: input.receivedBy,
    };

    setPayments((current) => [payment, ...current]);

    if (!isPending) {
      setReservations((current) =>
        current.map((item) => {
          if (item.id !== input.reservationId) return item;
          const paid = item.paid + input.amount;
          return { ...item, paid, balance: Math.max(0, item.total - paid) };
        }),
      );
      addActivity(
        `${input.method} payment of ₦${input.amount.toLocaleString("en-NG")} recorded for ${reservation.guest}`,
        "green",
      );
    } else {
      addActivity(
        `Transfer of ₦${input.amount.toLocaleString("en-NG")} submitted for ${reservation.guest} · awaiting verification`,
        "gold",
      );
    }
  }

  function verifyPayment(paymentId: string, approve: boolean, note?: string) {
    const payment = payments.find((item) => item.id === paymentId);
    if (!payment || payment.status !== "Pending") return;

    setPayments((current) =>
      current.map((item) =>
        item.id === paymentId
          ? { ...item, status: approve ? "Completed" : "Rejected" }
          : item,
      ),
    );

    if (approve && payment.reservationId) {
      setReservations((current) =>
        current.map((item) => {
          if (item.id !== payment.reservationId) return item;
          const paid = item.paid + payment.amount;
          return { ...item, paid, balance: Math.max(0, item.total - paid) };
        }),
      );
    }

    addActivity(
      `Transfer ${approve ? "verified" : "rejected"} for ${payment.guest} · ₦${payment.amount.toLocaleString("en-NG")}${note ? ` · ${note}` : ""}`,
      approve ? "green" : "red",
    );
  }

  function approveExpense(expenseId: string) {
    const expense = expenses.find((item) => item.id === expenseId);
    if (!expense) return;
    setExpenses((current) =>
      current.map((item) =>
        item.id === expenseId ? { ...item, status: "Approved" } : item,
      ),
    );
    addActivity(`Expense approved · ${expense.vendor} · ₦${expense.amount.toLocaleString("en-NG")}`, "green");
  }

  function payExpense(expenseId: string) {
    const expense = expenses.find((item) => item.id === expenseId);
    if (!expense) return;
    setExpenses((current) =>
      current.map((item) =>
        item.id === expenseId ? { ...item, status: "Paid" } : item,
      ),
    );
    addActivity(`Expense paid · ${expense.vendor} · ₦${expense.amount.toLocaleString("en-NG")}`, "blue");
  }

  function advanceOrder(orderId: string) {
    const order = orders.find((item) => item.id === orderId);
    if (!order || order.status === "delivered") return;

    const nextStatus = ORDER_FLOW[ORDER_FLOW.indexOf(order.status) + 1];
    const shouldDeduct =
      nextStatus === "delivered" && !order.stockDeducted;

    setOrders((current) =>
      current.map((item) =>
        item.id === orderId
          ? {
              ...item,
              status: nextStatus,
              stockDeducted: shouldDeduct ? true : item.stockDeducted,
            }
          : item,
      ),
    );

    if (nextStatus === "delivered" && shouldDeduct) {
      const nextInventory = inventory.map((item) => {
        const needed = order.items
          .filter((orderItem) => orderItem.stockId === item.id)
          .reduce(
            (sum, orderItem) =>
              sum + (orderItem.stockQty ?? 0) * orderItem.qty,
            0,
          );
        if (needed <= 0) return item;
        return {
          ...item,
          stock: Math.max(0, Number((item.stock - needed).toFixed(2))),
        };
      });
      setInventory(nextInventory);

      const becameLow = nextInventory.find((item) => {
        const previous = inventory.find((entry) => entry.id === item.id);
        return previous && previous.stock >= previous.reorder && item.stock < item.reorder;
      });
      if (becameLow) {
        addActivity(
          `Low stock alert · ${becameLow.name} dropped below its reorder point`,
          "red",
        );
      }
    }

    if (nextStatus === "delivered" && order.roomNumber) {
      const roomReservation = reservations.find(
        (reservation) =>
          reservation.roomNumber === order.roomNumber &&
          reservation.status === "in-house",
      );
      if (roomReservation) {
        setReservations((current) =>
          current.map((reservation) =>
            reservation.id === roomReservation.id
              ? {
                  ...reservation,
                  total: reservation.total + order.total,
                  balance: reservation.balance + order.total,
                }
              : reservation,
          ),
        );
        addActivity(
          `₦${order.total.toLocaleString("en-NG")} charged to Room ${order.roomNumber} folio · ${order.id}`,
          "gold",
        );
      }
    }

    const label =
      order.kind === "kitchen"
        ? "Kitchen ticket"
        : order.kind === "bar"
          ? "Bar order"
          : "Laundry request";
    addActivity(
      `${label} ${order.id} moved to ${nextStatus}${order.roomNumber ? ` · Room ${order.roomNumber}` : ""}`,
      nextStatus === "delivered" ? "green" : "blue",
    );
  }

  function advanceHousekeeping(taskId: string) {
    const task = housekeeping.find((item) => item.id === taskId);
    if (!task) return;

    const nextStatus: HousekeepingTask["status"] =
      task.status === "dirty"
        ? "cleaning"
        : task.status === "cleaning"
          ? "inspection"
          : "clean";

    setHousekeeping((current) =>
      current.map((item) =>
        item.id === taskId ? { ...item, status: nextStatus } : item,
      ),
    );
    setRooms((current) =>
      current.map((room) =>
        room.number === task.roomNumber
          ? {
              ...room,
              status: nextStatus === "clean" ? "available" : nextStatus,
            }
          : room,
      ),
    );
    addActivity(
      `Room ${task.roomNumber} ${nextStatus === "clean" ? "released as clean" : `moved to ${nextStatus}`}`,
      nextStatus === "clean" ? "green" : "blue",
    );
  }

  function rejectInspection(taskId: string) {
    const task = housekeeping.find((item) => item.id === taskId);
    if (!task) return;
    setHousekeeping((current) =>
      current.map((item) =>
        item.id === taskId ? { ...item, status: "cleaning" } : item,
      ),
    );
    setRooms((current) =>
      current.map((room) =>
        room.number === task.roomNumber ? { ...room, status: "cleaning" } : room,
      ),
    );
    addActivity(`Room ${task.roomNumber} failed inspection · returned to cleaning`, "red");
  }

  function createOrder(input: NewOrderInput) {
    const prefixMap: Record<OrderKind, string> = {
      kitchen: "K",
      bar: "B",
      laundry: "L",
    };
    const baseMap: Record<OrderKind, number> = {
      kitchen: 1041,
      bar: 2031,
      laundry: 501,
    };
    const existing = orders.filter((order) => order.kind === input.kind).length;
    const total = input.items.reduce(
      (sum, item) => sum + item.price * item.qty,
      0,
    );
    const order: ServiceOrder = {
      id: `${prefixMap[input.kind]}-${baseMap[input.kind] + existing}`,
      kind: input.kind,
      source: input.roomNumber ? `Room ${input.roomNumber}` : input.source,
      roomNumber: input.roomNumber,
      guest: input.guest,
      items: input.items,
      status: "new",
      placedAt: nowLabel(),
      due: input.due,
      note: input.note,
      total,
    };
    setOrders((current) => [order, ...current]);
    addActivity(
      `New ${input.kind} order ${order.id} · ${order.source} · ₦${total.toLocaleString("en-NG")}`,
      "gold",
    );
  }

  function adjustStock(itemId: string, delta: number) {
    const item = inventory.find((entry) => entry.id === itemId);
    if (!item || delta === 0) return;
    const nextStock = Math.max(0, Number((item.stock + delta).toFixed(2)));
    setInventory((current) =>
      current.map((entry) =>
        entry.id === itemId ? { ...entry, stock: nextStock } : entry,
      ),
    );
    addActivity(
      `Stock ${delta > 0 ? "received" : "issued"} · ${item.name} · ${delta > 0 ? "+" : ""}${delta} ${item.unit}`,
      delta > 0 ? "green" : "blue",
    );
    if (item.stock >= item.reorder && nextStock < item.reorder) {
      addActivity(`Low stock alert · ${item.name} below reorder point`, "red");
    }
  }

  function resetDemo() {
    setRooms(ROOMS.map((room) => ({ ...room })));
    setReservations(RESERVATIONS.map((reservation) => ({ ...reservation })));
    setPayments(PAYMENTS.map((payment) => ({ ...payment })));
    setOrders(cloneOrders(ORDERS));
    setHousekeeping(HOUSEKEEPING.map((task) => ({ ...task })));
    setInventory(INVENTORY.map((item) => ({ ...item })));
    setExpenses(EXPENSES.map((expense) => ({ ...expense })));
    setActivity(ACTIVITY.map((item) => ({ ...item })));
  }

  return (
    <PrototypeContext.Provider
      value={{
        rooms,
        reservations,
        payments,
        orders,
        housekeeping,
        inventory,
        expenses,
        activity,
        checkIn,
        checkOut,
        recordPayment,
        verifyPayment,
        approveExpense,
        payExpense,
        advanceOrder,
        advanceHousekeeping,
        rejectInspection,
        createOrder,
        adjustStock,
        resetDemo,
      }}
    >
      {children}
    </PrototypeContext.Provider>
  );
}

export function usePrototype() {
  const context = useContext(PrototypeContext);
  if (!context) {
    throw new Error("usePrototype must be used inside PrototypeProvider");
  }
  return context;
}
