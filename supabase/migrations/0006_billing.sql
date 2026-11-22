do $$
begin
  create type public.folio_type as enum ('guest', 'walk_in', 'event', 'house');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.folio_status as enum ('open', 'closed_paid', 'closed_with_balance', 'written_off', 'void');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.bill_status as enum ('draft', 'posted', 'void');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.payment_provider as enum ('paystack', 'cash', 'pos', 'bank_transfer');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.payment_status as enum ('pending', 'pending_verification', 'successful', 'failed', 'rejected', 'partially_refunded', 'refunded');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.payment_verification_action as enum ('approve', 'reject');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.refund_status as enum ('pending', 'approved', 'processing', 'completed', 'failed', 'rejected');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.gateway_processing_status as enum ('received', 'verified', 'posted', 'duplicate', 'failed', 'ignored');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.payment_exception_type as enum ('late_success', 'duplicate_event', 'amount_mismatch', 'currency_mismatch', 'unknown_payment', 'overpayment', 'verification_failed');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.payment_exception_status as enum ('open', 'investigating', 'resolved', 'ignored');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.financial_account_type as enum ('asset', 'liability', 'equity', 'revenue', 'expense');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.financial_transaction_type as enum ('payment', 'refund', 'charge', 'tax', 'fee', 'adjustment', 'reversal', 'opening_balance');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.financial_transaction_status as enum ('draft', 'posted', 'reversed');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.financial_adjustment_type as enum ('charge', 'credit', 'discount', 'write_off');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.financial_adjustment_status as enum ('pending', 'approved', 'rejected', 'posted');
exception when duplicate_object then null;
end $$;

create table public.number_sequences (
  scope text not null,
  prefix text not null,
  year integer not null check (year between 1900 and 9999),
  current_value bigint not null default 0 check (current_value >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (scope, prefix, year)
);

create table public.financial_accounts (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  code text not null,
  name text not null,
  type public.financial_account_type not null,
  normal_balance text not null check (normal_balance in ('debit', 'credit')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  unique (hotel_id, code)
);

create table public.folios (
  id uuid primary key default gen_random_uuid(),
  folio_number text not null unique,
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  reservation_id uuid references public.reservations(id) on delete restrict,
  guest_id uuid references public.guests(id) on delete restrict,
  type public.folio_type not null,
  status public.folio_status not null default 'open',
  currency text not null default 'NGN',
  opened_at timestamptz not null default now(),
  closed_at timestamptz,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid
);

create table public.bills (
  id uuid primary key default gen_random_uuid(),
  folio_id uuid not null references public.folios(id) on delete restrict,
  department_id uuid references public.departments(id) on delete set null,
  source_type text,
  source_id uuid,
  subtotal numeric(14,2) not null default 0 check (subtotal >= 0),
  tax numeric(14,2) not null default 0 check (tax >= 0),
  discount numeric(14,2) not null default 0 check (discount >= 0),
  total numeric(14,2) not null default 0 check (total >= 0),
  status public.bill_status not null default 'draft',
  posted_by uuid,
  posted_at timestamptz,
  voided_by uuid,
  voided_at timestamptz,
  void_reason text,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid
);

create table public.bill_items (
  id uuid primary key default gen_random_uuid(),
  bill_id uuid not null references public.bills(id) on delete restrict,
  folio_id uuid not null references public.folios(id) on delete restrict,
  description text not null,
  category_snapshot text,
  quantity numeric(14,3) not null check (quantity > 0),
  unit_price numeric(14,2) not null check (unit_price >= 0),
  tax_rate numeric(5,2) not null default 0 check (tax_rate between 0 and 100),
  tax_amount numeric(14,2) not null default 0 check (tax_amount >= 0),
  discount numeric(14,2) not null default 0 check (discount >= 0),
  total numeric(14,2) not null check (total >= 0),
  source_type text,
  source_id uuid,
  source_line_id uuid,
  posted_by uuid,
  posted_at timestamptz,
  is_void boolean not null default false,
  void_reason text,
  created_at timestamptz not null default now(),
  created_by uuid,
  check (not is_void or void_reason is not null)
);

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  reference text not null unique,
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  folio_id uuid not null references public.folios(id) on delete restrict,
  reservation_id uuid references public.reservations(id) on delete restrict,
  provider public.payment_provider not null,
  provider_reference text unique,
  amount numeric(14,2) not null check (amount > 0),
  currency text not null default 'NGN',
  status public.payment_status not null default 'pending',
  paid_at timestamptz,
  recorded_by uuid,
  verified_by uuid,
  verified_at timestamptz,
  receipt_number text unique,
  idempotency_key text not null unique,
  internal_notes text,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid
);

create table public.payment_verifications (
  id uuid primary key default gen_random_uuid(),
  payment_id uuid not null references public.payments(id) on delete restrict,
  action public.payment_verification_action not null,
  checker_id uuid not null references public.staff_profiles(id) on delete restrict,
  checked_at timestamptz not null default now(),
  notes text,
  bank_reference text,
  evidence_path text,
  created_at timestamptz not null default now(),
  check (action <> 'reject' or notes is not null)
);

create table public.payment_gateway_events (
  id uuid primary key default gen_random_uuid(),
  provider public.payment_provider not null,
  provider_event_id text not null unique,
  event_type text not null,
  payload jsonb not null default '{}'::jsonb,
  signature_valid boolean not null default false,
  processing_status public.gateway_processing_status not null default 'received',
  error text,
  payment_id uuid references public.payments(id) on delete set null,
  received_at timestamptz not null default now(),
  payload_expires_at timestamptz
);

create table public.refunds (
  id uuid primary key default gen_random_uuid(),
  payment_id uuid not null references public.payments(id) on delete restrict,
  folio_id uuid not null references public.folios(id) on delete restrict,
  amount numeric(14,2) not null check (amount > 0),
  reason text not null,
  status public.refund_status not null default 'pending',
  requested_by uuid references public.profiles(id) on delete set null,
  approved_by uuid references public.profiles(id) on delete set null,
  provider_refund_reference text unique,
  processed_at timestamptz,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid
);

create table public.receipts (
  id uuid primary key default gen_random_uuid(),
  payment_id uuid not null references public.payments(id) on delete restrict,
  receipt_number text not null unique,
  issued_to_snapshot jsonb not null default '{}'::jsonb,
  issued_by uuid references public.profiles(id) on delete set null,
  issued_at timestamptz not null default now(),
  pdf_path text,
  is_duplicate boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.payment_exceptions (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  payment_id uuid references public.payments(id) on delete set null,
  gateway_event_id uuid references public.payment_gateway_events(id) on delete set null,
  type public.payment_exception_type not null,
  status public.payment_exception_status not null default 'open',
  notes text,
  resolved_by uuid references public.profiles(id) on delete set null,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid
);

create table public.financial_transactions (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  type public.financial_transaction_type not null,
  source_type text,
  source_id uuid,
  idempotency_key text not null unique,
  occurred_at timestamptz not null default now(),
  posted_at timestamptz,
  posted_by uuid references public.profiles(id) on delete set null,
  status public.financial_transaction_status not null default 'draft',
  reversal_id uuid references public.financial_transactions(id) on delete restrict,
  memo text,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid
);

create table public.financial_transaction_lines (
  id uuid primary key default gen_random_uuid(),
  financial_transaction_id uuid not null references public.financial_transactions(id) on delete restrict,
  account_id uuid not null references public.financial_accounts(id) on delete restrict,
  debit numeric(14,2),
  credit numeric(14,2),
  department_id uuid references public.departments(id) on delete set null,
  guest_id uuid references public.guests(id) on delete set null,
  folio_id uuid references public.folios(id) on delete set null,
  memo text,
  created_at timestamptz not null default now(),
  constraint one_side_only check (
    (debit is not null and credit is null and debit > 0)
    or (credit is not null and debit is null and credit > 0)
  )
);

create table public.financial_adjustments (
  id uuid primary key default gen_random_uuid(),
  folio_id uuid not null references public.folios(id) on delete restrict,
  type public.financial_adjustment_type not null,
  amount numeric(14,2) not null check (amount > 0),
  reason text not null,
  requester_id uuid references public.profiles(id) on delete set null,
  approver_id uuid references public.profiles(id) on delete set null,
  status public.financial_adjustment_status not null default 'pending',
  ledger_transaction_id uuid references public.financial_transactions(id) on delete set null,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid
);

alter table public.financial_accounts add constraint financial_accounts_created_by_fk foreign key (created_by) references public.profiles(id);
alter table public.financial_accounts add constraint financial_accounts_updated_by_fk foreign key (updated_by) references public.profiles(id);
alter table public.folios add constraint folios_created_by_fk foreign key (created_by) references public.profiles(id);
alter table public.folios add constraint folios_updated_by_fk foreign key (updated_by) references public.profiles(id);
alter table public.bills add constraint bills_posted_by_fk foreign key (posted_by) references public.profiles(id);
alter table public.bills add constraint bills_voided_by_fk foreign key (voided_by) references public.profiles(id);
alter table public.bills add constraint bills_created_by_fk foreign key (created_by) references public.profiles(id);
alter table public.bills add constraint bills_updated_by_fk foreign key (updated_by) references public.profiles(id);
alter table public.bill_items add constraint bill_items_posted_by_fk foreign key (posted_by) references public.profiles(id);
alter table public.bill_items add constraint bill_items_created_by_fk foreign key (created_by) references public.profiles(id);
alter table public.payments add constraint payments_recorded_by_fk foreign key (recorded_by) references public.profiles(id);
alter table public.payments add constraint payments_verified_by_fk foreign key (verified_by) references public.profiles(id);
alter table public.payments add constraint payments_created_by_fk foreign key (created_by) references public.profiles(id);
alter table public.payments add constraint payments_updated_by_fk foreign key (updated_by) references public.profiles(id);
alter table public.refunds add constraint refunds_created_by_fk foreign key (created_by) references public.profiles(id);
alter table public.refunds add constraint refunds_updated_by_fk foreign key (updated_by) references public.profiles(id);
alter table public.payment_exceptions add constraint payment_exceptions_created_by_fk foreign key (created_by) references public.profiles(id);
alter table public.payment_exceptions add constraint payment_exceptions_updated_by_fk foreign key (updated_by) references public.profiles(id);
alter table public.financial_transactions add constraint financial_transactions_created_by_fk foreign key (created_by) references public.profiles(id);
alter table public.financial_transactions add constraint financial_transactions_updated_by_fk foreign key (updated_by) references public.profiles(id);

create index folios_hotel_id_status_idx on public.folios (hotel_id, status);
create index folios_reservation_id_idx on public.folios (reservation_id);
create index folios_guest_id_idx on public.folios (guest_id);
create index bills_folio_id_idx on public.bills (folio_id);
create index bills_department_id_idx on public.bills (department_id);
create index bill_items_bill_id_idx on public.bill_items (bill_id);
create index bill_items_folio_id_idx on public.bill_items (folio_id);
create index payments_folio_id_idx on public.payments (folio_id);
create index payments_hotel_id_status_idx on public.payments (hotel_id, status);
create index payments_paid_at_idx on public.payments (paid_at);
create index payments_reference_trgm_idx on public.payments using gin (reference extensions.gin_trgm_ops);
create index payment_verifications_payment_id_idx on public.payment_verifications (payment_id);
create index payment_gateway_events_payment_id_idx on public.payment_gateway_events (payment_id);
create index payment_gateway_events_status_idx on public.payment_gateway_events (processing_status);
create index refunds_payment_id_idx on public.refunds (payment_id);
create index refunds_folio_id_idx on public.refunds (folio_id);
create index receipts_payment_id_idx on public.receipts (payment_id);
create index payment_exceptions_hotel_id_status_idx on public.payment_exceptions (hotel_id, status);
create index financial_transactions_hotel_id_status_idx on public.financial_transactions (hotel_id, status);
create index financial_transaction_lines_transaction_id_idx on public.financial_transaction_lines (financial_transaction_id);
create index financial_transaction_lines_account_id_idx on public.financial_transaction_lines (account_id);
create index financial_transaction_lines_folio_id_idx on public.financial_transaction_lines (folio_id);
create index financial_adjustments_folio_id_idx on public.financial_adjustments (folio_id);

create trigger number_sequences_set_updated_at before update on public.number_sequences for each row execute function private.set_updated_at();
create trigger financial_accounts_set_updated_at before update on public.financial_accounts for each row execute function private.set_updated_at();
create trigger folios_set_updated_at before update on public.folios for each row execute function private.set_updated_at();
create trigger bills_set_updated_at before update on public.bills for each row execute function private.set_updated_at();
create trigger payments_set_updated_at before update on public.payments for each row execute function private.set_updated_at();
create trigger refunds_set_updated_at before update on public.refunds for each row execute function private.set_updated_at();
create trigger payment_exceptions_set_updated_at before update on public.payment_exceptions for each row execute function private.set_updated_at();
create trigger financial_transactions_set_updated_at before update on public.financial_transactions for each row execute function private.set_updated_at();
create trigger financial_adjustments_set_updated_at before update on public.financial_adjustments for each row execute function private.set_updated_at();

create or replace function private.assert_folio_accepts_charges()
returns trigger
language plpgsql
as $$
declare
  v_status public.folio_status;
begin
  select status into v_status from public.folios where id = new.folio_id;
  if v_status in ('closed_paid', 'void') then
    raise exception 'folio % does not accept charges in status %', new.folio_id, v_status using errcode = '23514';
  end if;
  return new;
end;
$$;

create trigger bills_folio_open_guard before insert or update on public.bills for each row execute function private.assert_folio_accepts_charges();
create trigger bill_items_folio_open_guard before insert or update on public.bill_items for each row execute function private.assert_folio_accepts_charges();

create or replace function private.set_gateway_payload_expiry()
returns trigger
language plpgsql
as $$
begin
  new.payload_expires_at := new.received_at + interval '180 days';
  return new;
end;
$$;

create trigger payment_gateway_events_payload_expiry before insert on public.payment_gateway_events for each row execute function private.set_gateway_payload_expiry();

create or replace function private.assert_balanced_transaction()
returns trigger
language plpgsql
as $$
declare
  v_transaction_id uuid := coalesce(new.financial_transaction_id, old.financial_transaction_id);
  v_debit numeric(14,2);
  v_credit numeric(14,2);
begin
  select coalesce(sum(debit), 0), coalesce(sum(credit), 0)
  into v_debit, v_credit
  from public.financial_transaction_lines
  where financial_transaction_id = v_transaction_id;

  if v_debit <> v_credit then
    raise exception 'unbalanced financial transaction %: debit %, credit %', v_transaction_id, v_debit, v_credit using errcode = '23514';
  end if;
  return null;
end;
$$;

create constraint trigger financial_transaction_lines_balanced
after insert or update or delete on public.financial_transaction_lines
deferrable initially deferred for each row execute function private.assert_balanced_transaction();

create or replace function private.prevent_financial_mutation()
returns trigger
language plpgsql
as $$
begin
  raise exception 'financial transaction lines are append-only' using errcode = '23514';
end;
$$;

create trigger financial_transaction_lines_append_only
before update or delete on public.financial_transaction_lines
for each row execute function private.prevent_financial_mutation();

create or replace function public.allocate_reference(p_scope text, p_prefix text)
returns text
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_year integer := extract(year from now())::integer;
  v_value bigint;
begin
  if p_scope is null or p_prefix is null or length(trim(p_scope)) = 0 or length(trim(p_prefix)) = 0 then
    raise exception 'scope and prefix are required' using errcode = '22023';
  end if;

  insert into public.number_sequences (scope, prefix, year, current_value)
  values (p_scope, p_prefix, v_year, 1)
  on conflict (scope, prefix, year) do update
  set current_value = public.number_sequences.current_value + 1
  returning current_value into v_value;

  return p_prefix || '-' || v_year::text || '-' || lpad(v_value::text, 6, '0');
end;
$$;

revoke all on function public.allocate_reference(text, text) from public, anon, authenticated;
grant execute on function public.allocate_reference(text, text) to service_role;

insert into public.number_sequences (scope, prefix, year, current_value)
values
  ('reservation', 'AUR', extract(year from now())::integer, 0),
  ('folio', 'FOL', extract(year from now())::integer, 0),
  ('payment', 'PAY', extract(year from now())::integer, 0),
  ('receipt', 'RCP', extract(year from now())::integer, 0)
on conflict (scope, prefix, year) do nothing;

alter table public.number_sequences enable row level security;
alter table public.financial_accounts enable row level security;
alter table public.folios enable row level security;
alter table public.bills enable row level security;
alter table public.bill_items enable row level security;
alter table public.payments enable row level security;
alter table public.payment_verifications enable row level security;
alter table public.payment_gateway_events enable row level security;
alter table public.refunds enable row level security;
alter table public.receipts enable row level security;
alter table public.payment_exceptions enable row level security;
alter table public.financial_transactions enable row level security;
alter table public.financial_transaction_lines enable row level security;
alter table public.financial_adjustments enable row level security;

revoke all on public.number_sequences from anon, authenticated;
revoke all on public.financial_accounts from anon, authenticated;
revoke all on public.folios from anon, authenticated;
revoke all on public.bills from anon, authenticated;
revoke all on public.bill_items from anon, authenticated;
revoke all on public.payments from anon, authenticated;
revoke all on public.payment_verifications from anon, authenticated;
revoke all on public.payment_gateway_events from anon, authenticated;
revoke all on public.refunds from anon, authenticated;
revoke all on public.receipts from anon, authenticated;
revoke all on public.payment_exceptions from anon, authenticated;
revoke all on public.financial_transactions from anon, authenticated;
revoke all on public.financial_transaction_lines from anon, authenticated;
revoke all on public.financial_adjustments from anon, authenticated;
