-- =====================================================================
-- 44_admin_remove_listing.sql  ·  admins take a listing off the market
--
-- Feature (scenario 19): after a scam report an admin could resolve the
-- ticket, but the listing stayed for sale.
--   - admin_remove_listing(item, reason) hides the listing and records
--     who removed it and why; the seller sees the reason.
--   - Unpaid orders for that listing are cancelled, so nobody pays for
--     it (a payment already in flight comes back as 'needs_refund').
--   - The seller can no longer edit or switch a removed listing back on.
--   - checkout() already refuses inactive listings.
-- =====================================================================

alter table public.marketplace_items
  add column removed_at     timestamptz,
  add column removed_by     uuid references public.users (id) on delete restrict,
  add column removal_reason text check (removal_reason is null or char_length(removal_reason) <= 1000);

create index marketplace_items_removed_by_idx on public.marketplace_items (removed_by);

-- A deleted or removed listing is never active.
create or replace function private.marketplace_items_deactivate_deleted()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.deleted_at is not null or new.removed_at is not null then
    new.is_active := false;
  end if;
  return new;
end;
$$;

create or replace function public.admin_remove_listing(p_item_id uuid, p_reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin    uuid := private.require_admin();
  v_order_id uuid;
begin
  if coalesce(btrim(p_reason), '') = '' then
    raise exception 'Give a reason; the seller will see it' using errcode = '22023';
  end if;

  update public.marketplace_items
     set is_active = false,
         removed_at = now(),
         removed_by = v_admin,
         removal_reason = left(btrim(p_reason), 1000)
   where id = p_item_id and removed_at is null;
  if not found then
    if exists (select 1 from public.marketplace_items where id = p_item_id) then
      raise exception 'This listing is already removed' using errcode = 'P0001';
    end if;
    raise exception 'Listing not found' using errcode = 'P0002';
  end if;

  -- Nobody should pay for a removed listing.
  for v_order_id in
    select o.id
    from public.orders o
    join public.order_items oi on oi.order_id = o.id
    where oi.item_id = p_item_id and o.status = 'pending_payment'
    for update of o
  loop
    perform private.cancel_order_internal(v_order_id, 'listing removed by admin');
  end loop;
end;
$$;

revoke all on function public.admin_remove_listing(uuid, text) from public, anon;
grant execute on function public.admin_remove_listing(uuid, text) to authenticated;

-- The seller can no longer change a removed listing.
drop policy marketplace_items_update_own on public.marketplace_items;
create policy marketplace_items_update_own
  on public.marketplace_items for update
  to authenticated
  using (seller_id = (select auth.uid()) and (select private.is_active_user()) and removed_at is null)
  with check (seller_id = (select auth.uid()) and removed_at is null);

-- Sellers see why a listing was removed.
create or replace view public.v_marketplace_items
with (security_invoker = true)
as
select
  i.id,
  i.item_name,
  i.description,
  i.price,
  i.stock_quantity,
  (i.stock_quantity > 0) as in_stock,
  i.is_active,
  i.created_at,
  i.updated_at,
  i.seller_id,
  s.display_name as seller_name,
  s.avatar_path as seller_avatar_path,
  s.is_verified_business as seller_is_verified_business,
  s.rating_avg as seller_rating_avg,
  s.rating_count as seller_rating_count,
  (i.seller_id = (select auth.uid())) as is_mine,
  i.removed_at,
  i.removal_reason
from public.marketplace_items i
join public.v_public_profiles s on s.id = i.seller_id
where i.deleted_at is null
  and (i.is_active or i.seller_id = (select auth.uid()));
;
