export type RoomStatus =
  | "available"
  | "occupied"
  | "dirty"
  | "cleaning"
  | "inspection"
  | "maintenance";

export type RoomCategory = {
  slug: string;
  name: string;
  shortName: string;
  description: string;
  rate: number;
  size: number;
  bed: string;
  occupancy: number;
  image: string;
  gallery: string[];
  amenities: string[];
  tag?: string;
};

export type Room = {
  number: string;
  categorySlug: string;
  floor: string;
  status: RoomStatus;
  guest?: string;
  departure?: string;
};

export type ReservationStatus = "arriving" | "in-house" | "departed" | "confirmed";

export type Reservation = {
  id: string;
  reference: string;
  guest: string;
  email: string;
  phone: string;
  roomNumber: string;
  categorySlug: string;
  checkIn: string;
  checkOut: string;
  nights: number;
  guests: number;
  status: ReservationStatus;
  total: number;
  paid: number;
  balance: number;
  notes?: string;
  vip?: boolean;
  eta?: string;
};

export type PaymentMethod = "Paystack" | "Cash" | "POS" | "Bank transfer";
export type PaymentStatus = "Completed" | "Pending" | "Rejected";

export type Payment = {
  id: string;
  reservationId?: string;
  guest: string;
  roomNumber: string;
  amount: number;
  method: PaymentMethod;
  status: PaymentStatus;
  reference: string;
  date: string;
  receivedBy: string;
};

export type OrderKind = "kitchen" | "bar" | "laundry";
export type OrderStatus = "new" | "preparing" | "ready" | "delivered";

export type OrderItem = {
  name: string;
  qty: number;
  price: number;
  stockId?: string;
  stockQty?: number;
};

export type ServiceOrder = {
  id: string;
  kind: OrderKind;
  source: string;
  roomNumber?: string;
  guest?: string;
  items: OrderItem[];
  status: OrderStatus;
  placedAt: string;
  due?: string;
  note?: string;
  total: number;
  stockDeducted?: boolean;
};

export type HousekeepingStatus = "dirty" | "cleaning" | "inspection" | "clean";

export type HousekeepingTask = {
  id: string;
  roomNumber: string;
  type: "Departure" | "Stayover" | "Deep clean";
  status: HousekeepingStatus;
  assignee: string;
  priority: "High" | "Normal";
  notes?: string;
};

export type InventoryItem = {
  id: string;
  name: string;
  category: "Bar" | "Kitchen" | "Housekeeping" | "Laundry";
  unit: string;
  stock: number;
  reorder: number;
  cost: number;
  location: string;
};

export type Expense = {
  id: string;
  vendor: string;
  category: string;
  amount: number;
  status: "Pending" | "Approved" | "Paid";
  submittedBy: string;
  date: string;
};

export type Activity = {
  id: string;
  text: string;
  time: string;
  tone: "gold" | "green" | "red" | "blue";
};

export const DEMO_TODAY = "2026-11-20";
export const DEMO_DATE_LABEL = "Friday, 20 November 2026";

export const ROOM_CATEGORIES: RoomCategory[] = [
  {
    slug: "classic-queen",
    name: "Classic Queen",
    shortName: "Classic",
    description:
      "A calm, light-filled retreat with a queen bed, writing desk and a marble shower. Ideal for a short business stay.",
    rate: 68000,
    size: 28,
    bed: "Queen bed",
    occupancy: 2,
    image:
      "https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=1400&q=80",
    gallery: [
      "https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=1600&q=80",
      "https://images.unsplash.com/photo-1620626011761-996317b8d101?auto=format&fit=crop&w=1600&q=80",
      "https://images.unsplash.com/photo-1566665797739-1674de7a421a?auto=format&fit=crop&w=1600&q=80",
    ],
    amenities: ["Rain shower", "Smart TV", "Work desk", "Nespresso", "Wi-Fi", "In-room safe"],
  },
  {
    slug: "deluxe-king",
    name: "Deluxe King",
    shortName: "Deluxe",
    description:
      "Our signature room: a generous king bed, lounge chair and floor-to-ceiling windows overlooking the courtyard.",
    rate: 95000,
    size: 34,
    bed: "King bed",
    occupancy: 2,
    image:
      "https://images.unsplash.com/photo-1611892440504-42a792e24d32?auto=format&fit=crop&w=1400&q=80",
    gallery: [
      "https://images.unsplash.com/photo-1611892440504-42a792e24d32?auto=format&fit=crop&w=1600&q=80",
      "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=1600&q=80",
      "https://images.unsplash.com/photo-1620626011761-996317b8d101?auto=format&fit=crop&w=1600&q=80",
    ],
    amenities: ["King bed", "Rain shower", "Lounge chair", "Smart TV", "Nespresso", "Wi-Fi", "Mini bar"],
    tag: "Most booked",
  },
  {
    slug: "garden-twin",
    name: "Garden Twin",
    shortName: "Garden",
    description:
      "Two plush twin beds, a private balcony and direct access to the garden walk. A favourite for friends and colleagues.",
    rate: 82000,
    size: 30,
    bed: "Two twin beds",
    occupancy: 2,
    image:
      "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=1400&q=80",
    gallery: [
      "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=1600&q=80",
      "https://images.unsplash.com/photo-1566665797739-1674de7a421a?auto=format&fit=crop&w=1600&q=80",
      "https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=1600&q=80",
    ],
    amenities: ["Garden balcony", "Twin beds", "Rain shower", "Smart TV", "Wi-Fi", "In-room safe"],
  },
  {
    slug: "premier-suite",
    name: "Premier Suite",
    shortName: "Suite",
    description:
      "A separate living room, dining nook and a deep soaking tub. Space to host, work and unwind above the city.",
    rate: 165000,
    size: 55,
    bed: "King bed + sofa bed",
    occupancy: 3,
    image:
      "https://images.unsplash.com/photo-1631049307264-da0ec9d70304?auto=format&fit=crop&w=1400&q=80",
    gallery: [
      "https://images.unsplash.com/photo-1631049307264-da0ec9d70304?auto=format&fit=crop&w=1600&q=80",
      "https://images.unsplash.com/photo-1611892440504-42a792e24d32?auto=format&fit=crop&w=1600&q=80",
      "https://images.unsplash.com/photo-1620626011761-996317b8d101?auto=format&fit=crop&w=1600&q=80",
    ],
    amenities: ["Living room", "Soaking tub", "Butler service", "Nespresso", "Smart TV", "Wi-Fi", "Airport transfer"],
    tag: "Aurelia favourite",
  },
  {
    slug: "penthouse",
    name: "The Penthouse",
    shortName: "Penthouse",
    description:
      "The top floor, entirely yours. A wraparound terrace, private dining and panoramic views across the Lagos skyline.",
    rate: 380000,
    size: 110,
    bed: "King bed + guest room",
    occupancy: 4,
    image:
      "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1400&q=80",
    gallery: [
      "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1600&q=80",
      "https://images.unsplash.com/photo-1631049307264-da0ec9d70304?auto=format&fit=crop&w=1600&q=80",
      "https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?auto=format&fit=crop&w=1600&q=80",
    ],
    amenities: ["Private terrace", "Dining for six", "Butler service", "Soaking tub", "Airport transfer", "Wi-Fi"],
    tag: "Signature stay",
  },
];

export const CATEGORY_BY_SLUG = Object.fromEntries(
  ROOM_CATEGORIES.map((category) => [category.slug, category]),
) as Record<string, RoomCategory>;

export const ROOMS: Room[] = [
  { number: "101", categorySlug: "classic-queen", floor: "First floor", status: "available" },
  { number: "102", categorySlug: "classic-queen", floor: "First floor", status: "occupied", guest: "Grace Adeleke", departure: "2026-11-20" },
  { number: "103", categorySlug: "classic-queen", floor: "First floor", status: "available" },
  { number: "104", categorySlug: "classic-queen", floor: "First floor", status: "available" },
  { number: "105", categorySlug: "classic-queen", floor: "First floor", status: "maintenance" },
  { number: "106", categorySlug: "classic-queen", floor: "First floor", status: "available" },
  { number: "108", categorySlug: "classic-queen", floor: "First floor", status: "dirty" },
  { number: "201", categorySlug: "deluxe-king", floor: "Second floor", status: "available" },
  { number: "202", categorySlug: "deluxe-king", floor: "Second floor", status: "available" },
  { number: "203", categorySlug: "deluxe-king", floor: "Second floor", status: "occupied", guest: "Elizabeth Cole", departure: "2026-11-21" },
  { number: "204", categorySlug: "deluxe-king", floor: "Second floor", status: "available" },
  { number: "205", categorySlug: "deluxe-king", floor: "Second floor", status: "available" },
  { number: "206", categorySlug: "deluxe-king", floor: "Second floor", status: "occupied", guest: "Michael Obi", departure: "2026-11-20" },
  { number: "208", categorySlug: "deluxe-king", floor: "Second floor", status: "dirty" },
  { number: "301", categorySlug: "garden-twin", floor: "Third floor", status: "inspection" },
  { number: "302", categorySlug: "garden-twin", floor: "Third floor", status: "available" },
  { number: "303", categorySlug: "garden-twin", floor: "Third floor", status: "occupied", guest: "Halima Bello", departure: "2026-11-23" },
  { number: "304", categorySlug: "garden-twin", floor: "Third floor", status: "available" },
  { number: "305", categorySlug: "garden-twin", floor: "Third floor", status: "occupied", guest: "Ibrahim Musa", departure: "2026-11-22" },
  { number: "306", categorySlug: "garden-twin", floor: "Third floor", status: "dirty" },
  { number: "401", categorySlug: "premier-suite", floor: "Fourth floor", status: "available" },
  { number: "402", categorySlug: "premier-suite", floor: "Fourth floor", status: "occupied", guest: "Ngozi Nwosu", departure: "2026-11-22" },
  { number: "403", categorySlug: "premier-suite", floor: "Fourth floor", status: "available" },
  { number: "404", categorySlug: "premier-suite", floor: "Fourth floor", status: "occupied", guest: "David Okon", departure: "2026-11-22" },
  { number: "PH1", categorySlug: "penthouse", floor: "Penthouse", status: "available" },
];

export const RESERVATIONS: Reservation[] = [
  {
    id: "res-1042",
    reference: "AUR-2026-1042",
    guest: "Adaeze Okafor",
    email: "adaeze.okafor@example.com",
    phone: "+234 803 555 0142",
    roomNumber: "401",
    categorySlug: "premier-suite",
    checkIn: "2026-11-20",
    checkOut: "2026-11-23",
    nights: 3,
    guests: 2,
    status: "arriving",
    total: 495000,
    paid: 148500,
    balance: 346500,
    notes: "Anniversary stay. Prefers a high floor and sparkling water on arrival.",
    vip: true,
    eta: "14:00",
  },
  {
    id: "res-1043",
    reference: "AUR-2026-1043",
    guest: "Tunde Balogun",
    email: "tunde.balogun@example.com",
    phone: "+234 806 555 0188",
    roomNumber: "205",
    categorySlug: "deluxe-king",
    checkIn: "2026-11-20",
    checkOut: "2026-11-22",
    nights: 2,
    guests: 1,
    status: "arriving",
    total: 190000,
    paid: 190000,
    balance: 0,
    notes: "Paid in full via Paystack. Late arrival expected.",
    eta: "19:30",
  },
  {
    id: "res-1044",
    reference: "AUR-2026-1044",
    guest: "Sarah Mitchell",
    email: "sarah.mitchell@example.com",
    phone: "+44 7700 900 144",
    roomNumber: "302",
    categorySlug: "garden-twin",
    checkIn: "2026-11-20",
    checkOut: "2026-11-24",
    nights: 4,
    guests: 2,
    status: "arriving",
    total: 328000,
    paid: 98400,
    balance: 229600,
    notes: "Two guests, separate beds. Quiet room away from the lift.",
    eta: "15:15",
  },
  {
    id: "res-1045",
    reference: "AUR-2026-1045",
    guest: "Chinedu Eze",
    email: "chinedu.eze@example.com",
    phone: "+234 811 555 0104",
    roomNumber: "104",
    categorySlug: "classic-queen",
    checkIn: "2026-11-20",
    checkOut: "2026-11-21",
    nights: 1,
    guests: 1,
    status: "arriving",
    total: 68000,
    paid: 0,
    balance: 68000,
    notes: "Walk-in converted to reservation. Paying at the desk.",
    eta: "16:00",
  },
  {
    id: "res-1046",
    reference: "AUR-2026-1046",
    guest: "Fatima Yusuf",
    email: "fatima.yusuf@example.com",
    phone: "+234 802 555 0177",
    roomNumber: "PH1",
    categorySlug: "penthouse",
    checkIn: "2026-11-20",
    checkOut: "2026-11-22",
    nights: 2,
    guests: 2,
    status: "arriving",
    total: 760000,
    paid: 760000,
    balance: 0,
    notes: "Repeat guest. Butler service confirmed. Dinner reservation at 20:00.",
    vip: true,
    eta: "13:30",
  },
  {
    id: "res-1047",
    reference: "AUR-2026-1047",
    guest: "James Adeyemi",
    email: "james.adeyemi@example.com",
    phone: "+234 805 555 0121",
    roomNumber: "201",
    categorySlug: "deluxe-king",
    checkIn: "2026-11-20",
    checkOut: "2026-11-23",
    nights: 3,
    guests: 1,
    status: "arriving",
    total: 285000,
    paid: 85500,
    balance: 199500,
    notes: "Deposit paid. Balance transfer is pending verification.",
    eta: "14:45",
  },
  {
    id: "res-2001",
    reference: "AUR-2026-0988",
    guest: "Grace Adeleke",
    email: "grace.adeleke@example.com",
    phone: "+234 803 555 0110",
    roomNumber: "102",
    categorySlug: "classic-queen",
    checkIn: "2026-11-18",
    checkOut: "2026-11-20",
    nights: 2,
    guests: 1,
    status: "in-house",
    total: 204000,
    paid: 76500,
    balance: 127500,
    notes: "Departing today. Breakfast and laundry on the folio.",
  },
  {
    id: "res-2002",
    reference: "AUR-2026-0991",
    guest: "Elizabeth Cole",
    email: "elizabeth.cole@example.com",
    phone: "+44 7700 900 212",
    roomNumber: "203",
    categorySlug: "deluxe-king",
    checkIn: "2026-11-18",
    checkOut: "2026-11-21",
    nights: 3,
    guests: 2,
    status: "in-house",
    total: 190000,
    paid: 147500,
    balance: 42500,
    notes: "Laundry collected this morning. Late breakfast charge on folio.",
  },
  {
    id: "res-2003",
    reference: "AUR-2026-0994",
    guest: "Michael Obi",
    email: "michael.obi@example.com",
    phone: "+234 809 555 0165",
    roomNumber: "206",
    categorySlug: "deluxe-king",
    checkIn: "2026-11-17",
    checkOut: "2026-11-20",
    nights: 3,
    guests: 1,
    status: "in-house",
    total: 171000,
    paid: 171000,
    balance: 0,
    notes: "Departing today. Express checkout requested.",
  },
  {
    id: "res-2004",
    reference: "AUR-2026-0999",
    guest: "Ibrahim Musa",
    email: "ibrahim.musa@example.com",
    phone: "+234 807 555 0192",
    roomNumber: "305",
    categorySlug: "garden-twin",
    checkIn: "2026-11-19",
    checkOut: "2026-11-22",
    nights: 3,
    guests: 1,
    status: "in-house",
    total: 164000,
    paid: 164000,
    balance: 0,
    notes: "Extended stay by one night, already paid.",
  },
  {
    id: "res-2005",
    reference: "AUR-2026-1002",
    guest: "Halima Bello",
    email: "halima.bello@example.com",
    phone: "+234 802 555 0150",
    roomNumber: "303",
    categorySlug: "garden-twin",
    checkIn: "2026-11-19",
    checkOut: "2026-11-23",
    nights: 4,
    guests: 2,
    status: "in-house",
    total: 246000,
    paid: 246000,
    balance: 0,
    notes: "No housekeeping before 11:00.",
  },
  {
    id: "res-2006",
    reference: "AUR-2026-1005",
    guest: "Ngozi Nwosu",
    email: "ngozi.nwosu@example.com",
    phone: "+234 806 555 0198",
    roomNumber: "402",
    categorySlug: "premier-suite",
    checkIn: "2026-11-18",
    checkOut: "2026-11-22",
    nights: 4,
    guests: 2,
    status: "in-house",
    total: 330000,
    paid: 330000,
    balance: 0,
    notes: "Suite is fully settled. Dinner charged to a company account.",
  },
  {
    id: "res-2007",
    reference: "AUR-2026-1008",
    guest: "David Okon",
    email: "david.okon@example.com",
    phone: "+234 810 555 0186",
    roomNumber: "404",
    categorySlug: "premier-suite",
    checkIn: "2026-11-19",
    checkOut: "2026-11-22",
    nights: 3,
    guests: 2,
    status: "in-house",
    total: 374000,
    paid: 285000,
    balance: 89000,
    notes: "Balance transfer submitted. Awaiting accountant verification.",
  },
];

export const PAYMENTS: Payment[] = [
  {
    id: "PAY-1001",
    reservationId: "res-1042",
    guest: "Adaeze Okafor",
    roomNumber: "401",
    amount: 148500,
    method: "Paystack",
    status: "Completed",
    reference: "PSK_8F2A-1042",
    date: "2026-11-12 09:14",
    receivedBy: "Paystack",
  },
  {
    id: "PAY-1002",
    reservationId: "res-1043",
    guest: "Tunde Balogun",
    roomNumber: "205",
    amount: 190000,
    method: "Paystack",
    status: "Completed",
    reference: "PSK_7CD1-1043",
    date: "2026-11-14 18:02",
    receivedBy: "Paystack",
  },
  {
    id: "PAY-1003",
    reservationId: "res-1044",
    guest: "Sarah Mitchell",
    roomNumber: "302",
    amount: 98400,
    method: "Paystack",
    status: "Completed",
    reference: "PSK_2B94-1044",
    date: "2026-11-15 11:40",
    receivedBy: "Paystack",
  },
  {
    id: "PAY-1004",
    reservationId: "res-1047",
    guest: "James Adeyemi",
    roomNumber: "201",
    amount: 85500,
    method: "Bank transfer",
    status: "Pending",
    reference: "TRF-90211",
    date: "2026-11-20 09:42",
    receivedBy: "Ifeoma Nwankwo",
  },
  {
    id: "PAY-1005",
    reservationId: "res-2006",
    guest: "Ngozi Nwosu",
    roomNumber: "402",
    amount: 60000,
    method: "Cash",
    status: "Completed",
    reference: "CSH-4410",
    date: "2026-11-18 16:20",
    receivedBy: "Ifeoma Nwankwo",
  },
  {
    id: "PAY-1006",
    reservationId: "res-2001",
    guest: "Grace Adeleke",
    roomNumber: "102",
    amount: 45000,
    method: "POS",
    status: "Completed",
    reference: "POS-7728",
    date: "2026-11-19 13:08",
    receivedBy: "Ifeoma Nwankwo",
  },
  {
    id: "PAY-1007",
    reservationId: "res-2003",
    guest: "Michael Obi",
    roomNumber: "206",
    amount: 36000,
    method: "Bank transfer",
    status: "Pending",
    reference: "TRF-90218",
    date: "2026-11-20 10:15",
    receivedBy: "Ifeoma Nwankwo",
  },
  {
    id: "PAY-1008",
    reservationId: "res-1046",
    guest: "Fatima Yusuf",
    roomNumber: "PH1",
    amount: 760000,
    method: "Paystack",
    status: "Completed",
    reference: "PSK_9A44-1046",
    date: "2026-11-10 07:55",
    receivedBy: "Paystack",
  },
  {
    id: "PAY-1009",
    reservationId: "res-2007",
    guest: "David Okon",
    roomNumber: "404",
    amount: 50000,
    method: "Bank transfer",
    status: "Pending",
    reference: "TRF-90225",
    date: "2026-11-20 08:55",
    receivedBy: "Ifeoma Nwankwo",
  },
  {
    id: "PAY-1010",
    reservationId: "res-2002",
    guest: "Elizabeth Cole",
    roomNumber: "203",
    amount: 42500,
    method: "Cash",
    status: "Completed",
    reference: "CSH-4427",
    date: "2026-11-19 20:10",
    receivedBy: "Ifeoma Nwankwo",
  },
  {
    id: "PAY-1011",
    reservationId: "res-2005",
    guest: "Halima Bello",
    roomNumber: "303",
    amount: 246000,
    method: "Paystack",
    status: "Completed",
    reference: "PSK_4F10-1002",
    date: "2026-11-17 14:30",
    receivedBy: "Paystack",
  },
  {
    id: "PAY-1012",
    reservationId: "res-2004",
    guest: "Ibrahim Musa",
    roomNumber: "305",
    amount: 164000,
    method: "POS",
    status: "Completed",
    reference: "POS-7742",
    date: "2026-11-16 19:12",
    receivedBy: "Ifeoma Nwankwo",
  },
  {
    id: "PAY-1013",
    reservationId: "res-2001",
    guest: "Grace Adeleke",
    roomNumber: "102",
    amount: 31500,
    method: "Cash",
    status: "Completed",
    reference: "CSH-4431",
    date: "2026-11-20 08:30",
    receivedBy: "Ifeoma Nwankwo",
  },
];

export const ORDERS: ServiceOrder[] = [
  {
    id: "K-1041",
    kind: "kitchen",
    source: "Room 203",
    roomNumber: "203",
    guest: "Elizabeth Cole",
    items: [
      { name: "Grilled tilapia", qty: 1, price: 28000, stockId: "INV-06", stockQty: 1 },
      { name: "Jollof rice", qty: 1, price: 12000, stockId: "INV-05", stockQty: 1 },
    ],
    status: "preparing",
    placedAt: "12:18",
    note: "No chilli on the side.",
    total: 40000,
  },
  {
    id: "K-1042",
    kind: "kitchen",
    source: "Table 4",
    guest: "Walk-in",
    items: [
      { name: "Aurelia burger", qty: 2, price: 18000, stockId: "INV-07", stockQty: 1 },
      { name: "Sweet potato fries", qty: 2, price: 6000 },
    ],
    status: "new",
    placedAt: "12:26",
    total: 48000,
  },
  {
    id: "K-1043",
    kind: "kitchen",
    source: "Room 305",
    roomNumber: "305",
    guest: "Ibrahim Musa",
    items: [{ name: "Chicken suya", qty: 1, price: 22000, stockId: "INV-07", stockQty: 1 }],
    status: "ready",
    placedAt: "12:02",
    total: 22000,
  },
  {
    id: "K-1044",
    kind: "kitchen",
    source: "Room 404",
    roomNumber: "404",
    guest: "David Okon",
    items: [
      { name: "Seafood pasta", qty: 1, price: 26000 },
      { name: "Caesar salad", qty: 1, price: 14000 },
    ],
    status: "new",
    placedAt: "12:29",
    note: "Dressing on the side.",
    total: 40000,
  },
  {
    id: "K-1045",
    kind: "kitchen",
    source: "Room 303",
    roomNumber: "303",
    guest: "Halima Bello",
    items: [
      { name: "Jollof rice", qty: 1, price: 12000, stockId: "INV-05", stockQty: 1 },
      { name: "Grilled chicken", qty: 1, price: 16000, stockId: "INV-07", stockQty: 1 },
    ],
    status: "delivered",
    placedAt: "11:38",
    total: 28000,
    stockDeducted: true,
  },
  {
    id: "K-1046",
    kind: "kitchen",
    source: "Table 7",
    guest: "Walk-in",
    items: [
      { name: "Coconut rice", qty: 2, price: 14000 },
      { name: "Prawn skewers", qty: 1, price: 24000 },
    ],
    status: "preparing",
    placedAt: "12:21",
    total: 52000,
  },
  {
    id: "B-2031",
    kind: "bar",
    source: "Room 206",
    roomNumber: "206",
    guest: "Michael Obi",
    items: [
      { name: "Aurelia Sunset", qty: 2, price: 9500, stockId: "INV-01", stockQty: 0.2 },
      { name: "House red glass", qty: 1, price: 7000, stockId: "INV-02", stockQty: 0.2 },
    ],
    status: "ready",
    placedAt: "12:12",
    total: 26000,
  },
  {
    id: "B-2032",
    kind: "bar",
    source: "Lounge 2",
    guest: "Walk-in",
    items: [{ name: "Espresso martini", qty: 2, price: 11000, stockId: "INV-02", stockQty: 0.2 }],
    status: "preparing",
    placedAt: "12:24",
    total: 22000,
  },
  {
    id: "B-2033",
    kind: "bar",
    source: "Room 203",
    roomNumber: "203",
    guest: "Elizabeth Cole",
    items: [{ name: "Sparkling water", qty: 2, price: 2500, stockId: "INV-04", stockQty: 2 }],
    status: "new",
    placedAt: "12:27",
    total: 5000,
  },
  {
    id: "B-2034",
    kind: "bar",
    source: "Room 404",
    roomNumber: "404",
    guest: "David Okon",
    items: [{ name: "Premium whisky", qty: 1, price: 15000, stockId: "INV-02", stockQty: 0.2 }],
    status: "delivered",
    placedAt: "11:50",
    total: 15000,
    stockDeducted: true,
  },
  {
    id: "B-2035",
    kind: "bar",
    source: "Pool deck",
    guest: "Walk-in",
    items: [{ name: "Chapman", qty: 2, price: 6000, stockId: "INV-03", stockQty: 2 }],
    status: "new",
    placedAt: "12:31",
    total: 12000,
  },
  {
    id: "L-501",
    kind: "laundry",
    source: "Room 203",
    roomNumber: "203",
    guest: "Elizabeth Cole",
    items: [{ name: "6 × Shirts", qty: 6, price: 1500, stockId: "INV-11", stockQty: 0.2 }],
    status: "preparing",
    placedAt: "09:10",
    due: "18:00 today",
    total: 9000,
    note: "Light starch. Return on hangers.",
  },
  {
    id: "L-502",
    kind: "laundry",
    source: "Room 305",
    roomNumber: "305",
    guest: "Ibrahim Musa",
    items: [{ name: "2 × Suits", qty: 2, price: 3500, stockId: "INV-11", stockQty: 0.2 }],
    status: "new",
    placedAt: "10:02",
    due: "Tomorrow, 10:00",
    total: 7000,
    note: "Dry clean only.",
  },
  {
    id: "L-503",
    kind: "laundry",
    source: "Room 404",
    roomNumber: "404",
    guest: "David Okon",
    items: [{ name: "4 × Trousers", qty: 4, price: 1500, stockId: "INV-11", stockQty: 0.2 }],
    status: "ready",
    placedAt: "08:40",
    due: "15:00 today",
    total: 6000,
  },
  {
    id: "L-504",
    kind: "laundry",
    source: "Room 102",
    roomNumber: "102",
    guest: "Grace Adeleke",
    items: [{ name: "3 × Dresses", qty: 3, price: 2500, stockId: "INV-11", stockQty: 0.2 }],
    status: "delivered",
    placedAt: "Yesterday",
    due: "09:00 today",
    total: 7500,
    stockDeducted: true,
  },
  {
    id: "L-505",
    kind: "laundry",
    source: "Room 303",
    roomNumber: "303",
    guest: "Halima Bello",
    items: [{ name: "5 × Items", qty: 5, price: 1100, stockId: "INV-11", stockQty: 0.2 }],
    status: "preparing",
    placedAt: "11:15",
    due: "18:00 today",
    total: 5500,
  },
];

export const HOUSEKEEPING: HousekeepingTask[] = [
  {
    id: "HK-701",
    roomNumber: "108",
    type: "Departure",
    status: "dirty",
    assignee: "Mercy Adeyemi",
    priority: "High",
    notes: "Priority turnover for an early arrival.",
  },
  {
    id: "HK-702",
    roomNumber: "208",
    type: "Stayover",
    status: "dirty",
    assignee: "Blessing Eze",
    priority: "Normal",
    notes: "Guest requested fresh towels only.",
  },
  {
    id: "HK-703",
    roomNumber: "306",
    type: "Departure",
    status: "cleaning",
    assignee: "Grace Nnamdi",
    priority: "High",
  },
  {
    id: "HK-704",
    roomNumber: "301",
    type: "Stayover",
    status: "inspection",
    assignee: "Esther Bello",
    priority: "Normal",
    notes: "Waiting for supervisor inspection.",
  },
];

export const INVENTORY: InventoryItem[] = [
  { id: "INV-01", name: "Premium gin", category: "Bar", unit: "bottles", stock: 12, reorder: 6, cost: 28000, location: "Main bar" },
  { id: "INV-02", name: "Single malt whisky", category: "Bar", unit: "bottles", stock: 8, reorder: 6, cost: 42000, location: "Main bar" },
  { id: "INV-03", name: "Tonic water", category: "Bar", unit: "cans", stock: 48, reorder: 24, cost: 700, location: "Store" },
  { id: "INV-04", name: "Sparkling water", category: "Bar", unit: "bottles", stock: 4, reorder: 12, cost: 1200, location: "Main bar" },
  { id: "INV-05", name: "Basmati rice", category: "Kitchen", unit: "kg", stock: 25, reorder: 10, cost: 1800, location: "Dry store" },
  { id: "INV-06", name: "Fresh tilapia", category: "Kitchen", unit: "kg", stock: 8, reorder: 10, cost: 6500, location: "Cold room" },
  { id: "INV-07", name: "Chicken", category: "Kitchen", unit: "kg", stock: 32, reorder: 15, cost: 4200, location: "Cold room" },
  { id: "INV-08", name: "Eggs", category: "Kitchen", unit: "crates", stock: 8, reorder: 20, cost: 3800, location: "Cold room" },
  { id: "INV-09", name: "Bed sheets", category: "Housekeeping", unit: "pieces", stock: 40, reorder: 20, cost: 8500, location: "Linen room" },
  { id: "INV-10", name: "Bath towels", category: "Housekeeping", unit: "pieces", stock: 76, reorder: 30, cost: 4500, location: "Linen room" },
  { id: "INV-11", name: "Laundry detergent", category: "Laundry", unit: "litres", stock: 14, reorder: 10, cost: 3200, location: "Laundry" },
  { id: "INV-12", name: "Coffee beans", category: "Kitchen", unit: "kg", stock: 9, reorder: 5, cost: 18000, location: "Dry store" },
];

export const EXPENSES: Expense[] = [
  { id: "EXP-301", vendor: "Lagos Fresh Produce", category: "Kitchen supplies", amount: 145000, status: "Pending", submittedBy: "Ngozi Peters", date: "2026-11-20" },
  { id: "EXP-302", vendor: "City Power Diesel", category: "Utilities", amount: 380000, status: "Approved", submittedBy: "Facilities", date: "2026-11-19" },
  { id: "EXP-303", vendor: "LaundryCare Ltd", category: "Laundry supplies", amount: 92000, status: "Paid", submittedBy: "Mercy Adeyemi", date: "2026-11-18" },
  { id: "EXP-304", vendor: "Aqua Pure", category: "Water", amount: 48000, status: "Pending", submittedBy: "Facilities", date: "2026-11-20" },
];

export const ACTIVITY: Activity[] = [
  { id: "ACT-1", text: "Deposit received for Adaeze Okafor · ₦148,500", time: "09:14", tone: "green" },
  { id: "ACT-2", text: "Transfer submitted by Ifeoma Nwankwo · awaiting verification", time: "09:42", tone: "gold" },
  { id: "ACT-3", text: "Room 306 checked out · housekeeping notified", time: "10:06", tone: "blue" },
  { id: "ACT-4", text: "Low stock alert · Fresh tilapia below reorder point", time: "10:22", tone: "red" },
  { id: "ACT-5", text: "Laundry collected from Room 203", time: "10:48", tone: "blue" },
  { id: "ACT-6", text: "Payment verified for Ngozi Nwosu · ₦60,000 cash", time: "11:05", tone: "green" },
];

export const ROOM_STATUS_META: Record<
  RoomStatus,
  { label: string; dot: string; chip: string }
> = {
  available: {
    label: "Available",
    dot: "bg-emerald-500",
    chip: "bg-emerald-50 text-emerald-700 ring-emerald-200",
  },
  occupied: {
    label: "Occupied",
    dot: "bg-navy",
    chip: "bg-navy/5 text-navy ring-navy/15",
  },
  dirty: {
    label: "Dirty",
    dot: "bg-clay",
    chip: "bg-clay/10 text-clay ring-clay/20",
  },
  cleaning: {
    label: "Cleaning",
    dot: "bg-amber-500",
    chip: "bg-amber-50 text-amber-700 ring-amber-200",
  },
  inspection: {
    label: "Inspection",
    dot: "bg-sky-500",
    chip: "bg-sky-50 text-sky-700 ring-sky-200",
  },
  maintenance: {
    label: "Maintenance",
    dot: "bg-zinc-400",
    chip: "bg-zinc-100 text-zinc-600 ring-zinc-200",
  },
};

export const ORDER_STATUS_LABEL: Record<OrderStatus, string> = {
  new: "New",
  preparing: "Preparing",
  ready: "Ready",
  delivered: "Delivered",
};

export const LAUNDRY_STATUS_LABEL: Record<OrderStatus, string> = {
  new: "Requested",
  preparing: "Processing",
  ready: "Ready",
  delivered: "Delivered",
};

export function orderTotal(items: OrderItem[]) {
  return items.reduce((sum, item) => sum + item.price * item.qty, 0);
}

export function categoryFor(slug: string) {
  return CATEGORY_BY_SLUG[slug] ?? ROOM_CATEGORIES[0];
}

export const AVAILABLE_ROOMS = ROOMS.filter((room) => room.status === "available").length;
