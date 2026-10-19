-- =====================================================================
-- 45_user_suspensions.sql  ·  admins suspend users (new table)
--
-- Feature (scenario 19): only businesses could be suspended, so a
-- client who didn't pay could only get a note on the ticket.
--   - user_suspensions: who was suspended, by whom, why, and when it was
--     lifted. Only the user and admins can read it, so the reason stays
--     private (a column on users would be readable by everyone).
--   - A suspended user can still read but can't post, bid, buy, sell,
--     chat or edit: every RPC and every write policy checks
--     is_active_user() / require_active_user(), which now treat a
--     suspension like a closed account.
--   - Their listings and open projects disappear for everyone else,
--     checkout refuses their items, and their pending offers can't be
--     accepted.
--   - v_my_profile shows is_suspended and the reason to the user.
-- =====================================================================

create table public.user_suspensions (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.users (id) on delete restrict,
  reason       text not null check (char_length(btrim(reason)) between 3 and 1000),
  suspended_by uuid not null references public.users (id) on delete restrict,
  suspended_at timestamptz not null default now(),
  lifted_by    uuid references public.users (id) on delete restrict,
  lifted_at    timestamptz,
  constraint user_suspensions_lift_pair check ((lifted_at is null) = (lifted_by is null))
);

comment on table public.user_suspensions is
  'Suspension history. At most one open row (lifted_at null) per user. Readable by that user and admins; written by admin_set_user_suspension().';

create unique index user_suspensions_one_open on public.user_suspensions (user_id) where lifted_at is null;
create index user_suspensions_user_id_idx on public.user_suspensions (user_id, suspended_at desc);
create index user_suspensions_suspended_by_idx on public.user_suspensions (suspended_by);
create index user_suspensions_lifted_by_idx on public.user_suspensions (lifted_by);

alter table public.user_suspensions enable row level security;

create policy user_suspensions_select
  on public.user_suspensions for select
  to authenticated
  using (user_id = (select auth.uid()) or (select private.is_admin()));

revoke all on table public.user_suspensions from anon, authenticated;
grant select on table public.user_suspensions to authenticated;

-- ---------------------------------------------------------------------
-- Helpers: a suspended user counts as inactive
-- ---------------------------------------------------------------------
create or replace function private.suspended_user_ids()
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select s.user_id from public.user_suspensions s where s.lifted_at is null;
$$;

revoke all on function private.suspended_user_ids() from public;
grant execute on function private.suspended_user_ids() to authenticated, service_role;

create or replace function private.is_active_user()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.users u
    where u.id = (select auth.uid())
      and u.deleted_at is null
      and not exists (
        select 1 from public.user_suspensions s
        where s.user_id = u.id and s.lifted_at is null
      )
  );
$$;

create or replace function private.require_active_user()
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'Not signed in' using errcode = '28000';
  end if;
  if not exists (select 1 from public.users where id = v_uid and deleted_at is null) then
    raise exception 'This account is closed or has no profile' using errcode = '42501';
  end if;
  if exists (select 1 from public.user_suspensions where user_id = v_uid and lifted_at is null) then
    raise exception 'This account is suspended' using errcode = '42501';
  end if;
  return v_uid;
end;
$$;

-- A suspended business can't bid, be hired or ask about open projects.
create or replace function private.is_verified_business(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.businesses b
    join public.users u on u.id = b.user_id
    where b.user_id = p_user_id
      and b.verification_status = 'verified'
      and b.deleted_at is null
      and u.deleted_at is null
      and not exists (
        select 1 from public.user_suspensions s
        where s.user_id = p_user_id and s.lifted_at is null
      )
  );
$$;

-- ---------------------------------------------------------------------
-- RPC
-- ---------------------------------------------------------------------
create or replace function public.admin_set_user_suspension(
  p_user_id uuid,
  p_suspended boolean,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := private.require_admin();
begin
  if p_user_id = v_admin then
    raise exception 'You cannot suspend yourself' using errcode = 'P0001';
  end if;
  if not exists (select 1 from public.users where id = p_user_id and deleted_at is null) then
    raise exception 'User not found' using errcode = 'P0002';
  end if;

  if p_suspended then
    if exists (select 1 from public.users where id = p_user_id and role = 'admin') then
      raise exception 'Remove their admin role before suspending them' using errcode = 'P0001';
    end if;
    if coalesce(btrim(p_reason), '') = '' then
      raise exception 'Give a reason; the user will see it' using errcode = '22023';
    end if;
    insert into public.user_suspensions (user_id, reason, suspended_by)
    values (p_user_id, left(btrim(p_reason), 1000), v_admin)
    on conflict (user_id) where lifted_at is null do nothing;
    if not found then
      raise exception 'This user is already suspended' using errcode = 'P0001';
    end if;
  else
    update public.user_suspensions
       set lifted_at = now(), lifted_by = v_admin
     where user_id = p_user_id and lifted_at is null;
    if not found then
      raise exception 'This user is not suspended' using errcode = 'P0001';
    end if;
  end if;
end;
$$;

revoke all on function public.admin_set_user_suspension(uuid, boolean, text) from public, anon;
grant execute on function public.admin_set_user_suspension(uuid, boolean, text) to authenticated;

-- ---------------------------------------------------------------------
-- Write policies: editing also needs an active account
-- ---------------------------------------------------------------------
alter policy users_update_own
  on public.users
  using (id = (select auth.uid()) and (select private.is_active_user()))
  with check (id = (select auth.uid()) and deleted_at is null);

alter policy businesses_update_own
  on public.businesses
  using (user_id = (select auth.uid()) and deleted_at is null and (select private.is_active_user()))
  with check (user_id = (select auth.uid()) and deleted_at is null);

alter policy projects_update_own
  on public.projects
  using (owner_id = (select auth.uid()) and status in ('draft', 'open') and (select private.is_active_user()))
  with check (owner_id = (select auth.uid()) and status in ('draft', 'open'));

alter policy project_offers_update_own_pending
  on public.project_offers
  using (provider_id = (select auth.uid()) and status = 'pending' and (select private.is_active_user()))
  with check (provider_id = (select auth.uid()) and status = 'pending');

alter policy project_reports_update_taker
  on public.project_reports
  using (
    author_id = (select auth.uid())
    and (select private.is_active_user())
    and exists (
      select 1 from public.projects p
      where p.id = project_reports.project_id
        and p.taker_id = (select auth.uid())
        and p.status = 'in_progress'
    )
  )
  with check (author_id = (select auth.uid()));

alter policy reviews_update_own
  on public.reviews
  using (reviewer_id = (select auth.uid()) and (select private.is_active_user()))
  with check (reviewer_id = (select auth.uid()));

-- ---------------------------------------------------------------------
-- Visibility: a suspended user's listings and open projects are hidden
-- from everyone else (the user and admins still see them)
-- ---------------------------------------------------------------------
alter policy marketplace_items_select
  on public.marketplace_items
  using (
    (is_active and deleted_at is null and seller_id not in (select private.suspended_user_ids()))
    or seller_id = (select auth.uid())
    or (select private.is_admin())
  );

alter policy projects_select
  on public.projects
  using (
    (status = 'open' and owner_id not in (select private.suspended_user_ids()))
    or owner_id = (select auth.uid())
    or taker_id = (select auth.uid())
    or id in (select private.my_bid_project_ids())
    or (select private.is_admin())
  );

-- checkout(): same as 05_orders.sql, but refuses items of a suspended seller.
create or replace function public.checkout(p_items jsonb, p_payment_method public.payment_method)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_buyer       uuid := private.require_active_user();
  v_order_id    uuid := gen_random_uuid();
  v_seller      uuid;
  v_total       numeric(14, 2) := 0;
  v_line        record;
  v_price       numeric(12, 2);
  v_name        text;
  v_item_seller uuid;
  v_item_ids    uuid[] := '{}';
  v_names       text[] := '{}';
  v_qtys        integer[] := '{}';
  v_prices      numeric[] := '{}';
begin
  if p_payment_method is null then
    raise exception 'Choose a payment method' using errcode = '22023';
  end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'The cart is empty' using errcode = '22023';
  end if;
  if jsonb_array_length(p_items) > 50 then
    raise exception 'An order can have at most 50 lines' using errcode = '22023';
  end if;

  -- One checkout at a time per buyer, so the unpaid-order cap is exact.
  perform 1 from public.users where id = v_buyer for update;
  if (select count(*) from public.orders
      where buyer_id = v_buyer and status = 'pending_payment') >= 5 then
    raise exception 'You have 5 unpaid orders; pay or cancel one first' using errcode = 'P0001';
  end if;

  for v_line in
    select (e ->> 'item_id')::uuid as item_id,
           sum((e ->> 'quantity')::integer) as quantity
    from jsonb_array_elements(p_items) as e
    group by 1
    order by 1            -- same lock order in every checkout: no deadlocks
  loop
    if v_line.item_id is null or v_line.quantity is null
       or v_line.quantity <= 0 or v_line.quantity > 10000 then
      raise exception 'Every line needs an item_id and a quantity between 1 and 10000'
        using errcode = '22023';
    end if;

    -- Atomic reservation: succeeds only if the stock is there right now,
    -- and the price comes from the listing, never from the client.
    update public.marketplace_items
       set stock_quantity = stock_quantity - v_line.quantity
     where id = v_line.item_id
       and is_active
       and deleted_at is null
       and stock_quantity >= v_line.quantity
    returning price, item_name, seller_id
      into v_price, v_name, v_item_seller;

    if not found then
      raise exception 'Item % is unavailable or does not have enough stock', v_line.item_id
        using errcode = 'P0001';
    end if;
    if v_item_seller = v_buyer then
      raise exception 'You cannot buy your own item' using errcode = 'P0001';
    end if;
    if v_seller is null then
      v_seller := v_item_seller;
    elsif v_seller <> v_item_seller then
      raise exception 'All items in one order must come from the same seller' using errcode = 'P0001';
    end if;

    v_item_ids := v_item_ids || v_line.item_id;
    v_names    := v_names || v_name;
    v_qtys     := v_qtys || v_line.quantity::integer;
    v_prices   := v_prices || v_price;
    v_total    := v_total + v_price * v_line.quantity;
  end loop;

  -- NEW: the seller must be open and not suspended.
  if not exists (select 1 from public.users where id = v_seller and deleted_at is null)
     or exists (select 1 from public.user_suspensions where user_id = v_seller and lifted_at is null) then
    raise exception 'This seller can''t take orders right now' using errcode = 'P0001';
  end if;

  insert into public.orders (id, buyer_id, seller_id, payment_method, total_amount)
  values (v_order_id, v_buyer, v_seller, p_payment_method, v_total);

  insert into public.order_items (order_id, item_id, item_name, quantity, price_at_purchase)
  select v_order_id, t.item_id, t.item_name, t.quantity, t.price
  from unnest(v_item_ids, v_names, v_qtys, v_prices) as t (item_id, item_name, quantity, price);

  return v_order_id;
end;
$$;

-- The user sees their own suspension.
create or replace view public.v_my_profile
with (security_invoker = true)
as
select
  u.id,
  u.full_name,
  u.avatar_path,
  u.role,
  (u.role = 'admin') as is_admin,
  u.created_at,
  u.updated_at,
  (b.user_id is not null and b.deleted_at is null) as is_business,
  b.company_name,
  b.cr_number,
  b.specialized_field,
  b.verification_status,
  b.verified_at,
  (s.id is not null) as is_suspended,
  s.reason as suspension_reason
from public.users u
left join public.businesses b on b.user_id = u.id
left join public.user_suspensions s on s.user_id = u.id and s.lifted_at is null
where u.id = (select auth.uid());
;
