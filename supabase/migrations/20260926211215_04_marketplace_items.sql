-- =====================================================================
-- 04_marketplace_items.sql  ·  things users sell
--
-- Review fixes here:
--   #4  seller_id is always the signed-in user (default + no grant).
--   #7  stock can never go below zero (check); the only way stock is
--       taken is the atomic update inside checkout() (file 05).
--   #8  listings are soft-deleted so past orders keep their item.
--   #11 price >= 0, stock >= 0.
--   #13 timestamps.
-- =====================================================================

create table public.marketplace_items (
  id             uuid primary key default gen_random_uuid(),
  seller_id      uuid not null default auth.uid()
                 references public.users (id) on delete restrict,
  item_name      text not null check (char_length(btrim(item_name)) between 2 and 150),
  description    text check (description is null or char_length(description) <= 2000),
  price          numeric(12, 2) not null check (price >= 0),
  stock_quantity integer not null default 0 check (stock_quantity >= 0),
  is_active      boolean not null default true,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  deleted_at     timestamptz
);

comment on table public.marketplace_items is
  'Listings. Sellers edit their own; stock is only reduced by checkout(). Delete = set deleted_at.';

create index marketplace_items_seller_id_idx on public.marketplace_items (seller_id);
create index marketplace_items_live_idx on public.marketplace_items (created_at desc)
  where is_active and deleted_at is null;

create trigger marketplace_items_set_updated_at
  before update on public.marketplace_items
  for each row execute function private.set_updated_at();

-- A deleted listing is never active.
create or replace function private.marketplace_items_deactivate_deleted()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.deleted_at is not null then
    new.is_active := false;
  end if;
  return new;
end;
$$;

revoke all on function private.marketplace_items_deactivate_deleted() from public;

create trigger marketplace_items_deactivate_deleted
  before insert or update on public.marketplace_items
  for each row execute function private.marketplace_items_deactivate_deleted();

-- ---------------------------------------------------------------------
-- Row level security + column grants
-- ---------------------------------------------------------------------
alter table public.marketplace_items enable row level security;

-- Live listings are public to signed-in users; sellers also see their
-- own inactive/deleted rows (needed so a soft delete can be saved).
create policy marketplace_items_select
  on public.marketplace_items for select
  to authenticated
  using (
    (is_active and deleted_at is null)
    or seller_id = (select auth.uid())
    or (select private.is_admin())
  );

create policy marketplace_items_insert_own
  on public.marketplace_items for insert
  to authenticated
  with check (seller_id = (select auth.uid()) and (select private.is_active_user()));

-- updatePrice() and restocking are plain updates by the seller.
create policy marketplace_items_update_own
  on public.marketplace_items for update
  to authenticated
  using (seller_id = (select auth.uid()) and (select private.is_active_user()))
  with check (seller_id = (select auth.uid()));

revoke all on table public.marketplace_items from anon, authenticated;
grant select on table public.marketplace_items to authenticated;
grant insert (item_name, description, price, stock_quantity, is_active)
  on table public.marketplace_items to authenticated;
grant update (item_name, description, price, stock_quantity, is_active, deleted_at)
  on table public.marketplace_items to authenticated;
;
