-- =====================================================================
-- 06_order_items.sql  ·  lines of an order
--
-- Review fixes here:
--   #2  written only by checkout(): price_at_purchase and item_name are
--       copied from the listing, never taken from the client.
--   #8  ON DELETE RESTRICT to the order and the item.
--   #11 quantity > 0, price >= 0.
--   #12 real primary key (order_id, item_id).
-- =====================================================================

create table public.order_items (
  order_id          uuid not null references public.orders (id) on delete restrict,
  item_id           uuid not null references public.marketplace_items (id) on delete restrict,
  -- Snapshot, so the order still reads right after the listing changes.
  item_name         text not null,
  quantity          integer not null check (quantity > 0),
  price_at_purchase numeric(12, 2) not null check (price_at_purchase >= 0),
  -- getSubtotal()
  subtotal          numeric(14, 2) generated always as (quantity * price_at_purchase) stored,
  created_at        timestamptz not null default now(),
  primary key (order_id, item_id)
);

comment on table public.order_items is
  'Read-only for clients. Price and name are snapshots taken by checkout().';

create index order_items_item_id_idx on public.order_items (item_id);

-- ---------------------------------------------------------------------
-- Row level security (read-only for clients)
-- ---------------------------------------------------------------------
alter table public.order_items enable row level security;

create policy order_items_select
  on public.order_items for select
  to authenticated
  using (
    (select private.is_admin())
    or exists (
      select 1 from public.orders o
      where o.id = order_items.order_id
        and (o.buyer_id = (select auth.uid()) or o.seller_id = (select auth.uid()))
    )
  );

revoke all on table public.order_items from anon, authenticated;
grant select on table public.order_items to authenticated;
;
