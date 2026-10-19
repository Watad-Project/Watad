-- =====================================================================
-- 05_orders.sql  ·  marketplace orders (one seller per order)
--
-- Review fixes here:
--   #2  clients cannot insert or update orders at all. checkout()
--       takes prices from the database, and only the payment webhook
--       (record_payment_event, file 17) can mark an order paid.
--       gateway_reference + idempotency_key stop double charging.
--   #7  stock is reserved atomically; unpaid orders expire and give
--       their stock back; a buyer can hold at most 5 unpaid orders.
--   #8  ON DELETE RESTRICT everywhere: order history can't vanish.
--   #11 enum status / payment_method; totals >= 0.
--   #14 only the card brand and last 4 digits are ever stored.
-- =====================================================================

create table public.orders (
  id                uuid primary key default gen_random_uuid(),
  buyer_id          uuid not null references public.users (id) on delete restrict,
  seller_id         uuid not null references public.users (id) on delete restrict,
  status            public.order_status not null default 'pending_payment',
  payment_method    public.payment_method not null,
  total_amount      numeric(14, 2) not null check (total_amount >= 0),
  currency          char(3) not null default 'SAR' check (currency ~ '^[A-Z]{3}$'),
  -- Sent to the gateway when the payment is created, so a retried
  -- request can't charge twice.
  idempotency_key   uuid not null default gen_random_uuid() unique,
  -- The gateway's payment id, set by the server (file 17).
  gateway_reference text unique
                    check (gateway_reference is null or char_length(gateway_reference) <= 200),
  card_brand        text check (card_brand is null or char_length(card_brand) <= 30),
  card_last4        char(4) check (card_last4 is null or card_last4 ~ '^[0-9]{4}$'),
  paid_at           timestamptz,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  constraint orders_buyer_is_not_seller check (buyer_id <> seller_id)
);

comment on table public.orders is
  'Read-only for clients. Created by checkout(); paid only by the payment webhook; see status_history for the timeline.';

create index orders_buyer_id_idx on public.orders (buyer_id, created_at desc);
create index orders_seller_id_idx on public.orders (seller_id, created_at desc);
create index orders_unpaid_idx on public.orders (created_at) where status = 'pending_payment';

create trigger orders_set_updated_at
  before update on public.orders
  for each row execute function private.set_updated_at();

-- ---------------------------------------------------------------------
-- Internal: cancel an unpaid order and return its stock
-- ---------------------------------------------------------------------
create or replace function private.cancel_order_internal(p_order_id uuid, p_note text default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform set_config('app.status_note', coalesce(p_note, ''), true);
  update public.orders
     set status = 'cancelled'
   where id = p_order_id and status = 'pending_payment';
  if not found then
    return;
  end if;
  -- order_items is created in file 06; plpgsql resolves it at run time.
  update public.marketplace_items m
     set stock_quantity = m.stock_quantity + oi.quantity
    from public.order_items oi
   where oi.order_id = p_order_id
     and oi.item_id = m.id;
end;
$$;

revoke all on function private.cancel_order_internal(uuid, text) from public;

-- ---------------------------------------------------------------------
-- RPCs
-- ---------------------------------------------------------------------

-- supabase.rpc('checkout', params: {
--   'p_items': [{'item_id': '...', 'quantity': 2}, ...],
--   'p_payment_method': 'mada' })  -> new order id
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

  if not exists (select 1 from public.users where id = v_seller and deleted_at is null) then
    raise exception 'The seller''s account is closed' using errcode = 'P0001';
  end if;

  insert into public.orders (id, buyer_id, seller_id, payment_method, total_amount)
  values (v_order_id, v_buyer, v_seller, p_payment_method, v_total);

  insert into public.order_items (order_id, item_id, item_name, quantity, price_at_purchase)
  select v_order_id, t.item_id, t.item_name, t.quantity, t.price
  from unnest(v_item_ids, v_names, v_qtys, v_prices) as t (item_id, item_name, quantity, price);

  return v_order_id;
end;
$$;

-- Buyer or seller cancels an order that has not been paid.
create or replace function public.cancel_order(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid   uuid := private.require_active_user();
  v_order public.orders;
begin
  select * into v_order from public.orders where id = p_order_id for update;
  if not found or v_uid not in (v_order.buyer_id, v_order.seller_id) then
    raise exception 'Order not found' using errcode = 'P0002';
  end if;
  if v_order.status <> 'pending_payment' then
    raise exception 'Only unpaid orders can be cancelled; a paid order needs a refund' using errcode = 'P0001';
  end if;
  if v_order.gateway_reference is not null then
    raise exception 'A payment is in progress for this order' using errcode = 'P0001';
  end if;
  perform private.cancel_order_internal(
    p_order_id,
    case when v_uid = v_order.buyer_id then 'cancelled by buyer' else 'cancelled by seller' end);
end;
$$;

-- Seller: paid -> shipped
create or replace function public.mark_order_shipped(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_active_user();
begin
  update public.orders
     set status = 'shipped'
   where id = p_order_id and seller_id = v_uid and status = 'paid';
  if not found then
    raise exception 'Only the seller can ship an order, and only once it is paid' using errcode = 'P0001';
  end if;
end;
$$;

-- Buyer: paid/shipped -> delivered (this unlocks reviews)
create or replace function public.confirm_order_delivered(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_active_user();
begin
  update public.orders
     set status = 'delivered'
   where id = p_order_id and buyer_id = v_uid and status in ('paid', 'shipped');
  if not found then
    raise exception 'Only the buyer can confirm delivery, and only once the order is paid' using errcode = 'P0001';
  end if;
end;
$$;

-- Server-only housekeeping: cancel unpaid orders and release their
-- stock. Run every few minutes (pg_cron or a scheduled Edge Function).
create or replace function public.expire_stale_orders(p_older_than interval default interval '30 minutes')
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id    uuid;
  v_count integer := 0;
begin
  for v_id in
    select o.id from public.orders o
    where o.status = 'pending_payment'
      and ((o.gateway_reference is null and o.created_at < now() - p_older_than)
           or o.created_at < now() - interval '1 day')
    for update skip locked
  loop
    perform private.cancel_order_internal(v_id, 'payment window expired');
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;

revoke all on function public.checkout(jsonb, public.payment_method) from public, anon;
revoke all on function public.cancel_order(uuid) from public, anon;
revoke all on function public.mark_order_shipped(uuid) from public, anon;
revoke all on function public.confirm_order_delivered(uuid) from public, anon;
revoke all on function public.expire_stale_orders(interval) from public, anon, authenticated;
grant execute on function public.checkout(jsonb, public.payment_method) to authenticated;
grant execute on function public.cancel_order(uuid) to authenticated;
grant execute on function public.mark_order_shipped(uuid) to authenticated;
grant execute on function public.confirm_order_delivered(uuid) to authenticated;
grant execute on function public.expire_stale_orders(interval) to service_role;

-- ---------------------------------------------------------------------
-- Row level security (read-only for clients)
-- ---------------------------------------------------------------------
alter table public.orders enable row level security;

create policy orders_select
  on public.orders for select
  to authenticated
  using (
    buyer_id = (select auth.uid())
    or seller_id = (select auth.uid())
    or (select private.is_admin())
  );

revoke all on table public.orders from anon, authenticated;
grant select on table public.orders to authenticated;
;
