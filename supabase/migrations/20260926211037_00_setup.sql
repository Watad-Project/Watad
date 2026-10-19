-- =====================================================================
-- 00_setup.sql  ·  Watad database — shared setup (run first)
--
-- Creates the "private" schema, every enum type, and the generic
-- trigger function the table files use.
--
-- Review fixes here: #11 (statuses, roles, payment methods and report
-- types are enums, not free text).
-- =====================================================================

-- Functions the app must never call directly live in "private".
-- The Data API only exposes "public", so nothing in here is reachable
-- over REST/RPC; RLS policies and views can still use it.
create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated, service_role;

-- ---------------------------------------------------------------------
-- Enum types
-- ---------------------------------------------------------------------

-- Staff permissions only. Whether someone is a business is decided by
-- the businesses table alone (one source of truth for roles).
create type public.app_role as enum ('user', 'admin');

create type public.verification_status as enum (
  'unverified', 'pending', 'verified', 'rejected', 'suspended'
);

create type public.project_status as enum (
  'draft', 'open', 'in_progress', 'completed', 'cancelled'
);

create type public.offer_status as enum (
  'pending', 'accepted', 'rejected', 'withdrawn'
);

create type public.payment_status as enum (
  'pending', 'processing', 'paid', 'failed', 'refunded', 'cancelled'
);

create type public.order_status as enum (
  'pending_payment', 'paid', 'shipped', 'delivered', 'cancelled', 'refunded'
);

-- How the buyer paid. Card numbers never go anywhere near the database;
-- the gateway gives us a brand and the last four digits (see orders).
create type public.payment_method as enum (
  'mada', 'credit_card', 'apple_pay', 'stc_pay', 'bank_transfer'
);

create type public.report_type as enum (
  'fraud', 'scam', 'harassment', 'spam', 'inappropriate_content',
  'payment_issue', 'technical_issue', 'other'
);

create type public.report_status as enum (
  'open', 'in_review', 'resolved', 'dismissed'
);

-- ---------------------------------------------------------------------
-- Generic trigger: keep updated_at current (review fix #13)
-- ---------------------------------------------------------------------
create or replace function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

revoke all on function private.set_updated_at() from public;
;
