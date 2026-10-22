-- Admin marketplace management (GRA-46): every listing as an admin sees it.
--
-- v_marketplace_items returns only active items (and the seller's own), so
-- an admin couldn't see hidden or removed ones. This view returns every
-- item not deleted by its seller, to admins only, with:
-- * the seller: name, photo, verified business, rating (from
--   v_public_profiles, like v_marketplace_items);
-- * status, one of them, in this order: `removed` (by an admin), `hidden`
--   (by the seller: not active), `out_of_stock`, `live`;
-- * the removal: when, by which admin, and the reason the seller reads;
-- * counts: the orders with this item, and the reports about it still open
--   or in review.
--
-- security_invoker, like the other admin views: admins can read every row
-- of these tables, and anyone else gets no row at all.

create or replace view public.v_admin_marketplace_items
with (security_invoker = true)
as
select
  i.id,
  i.item_name,
  i.description,
  i.price,
  i.stock_quantity,
  i.is_active,
  case
    when i.removed_at is not null then 'removed'
    when not i.is_active then 'hidden'
    when i.stock_quantity <= 0 then 'out_of_stock'
    else 'live'
  end as status,
  i.created_at,
  i.updated_at,
  i.seller_id,
  s.display_name as seller_name,
  s.avatar_path as seller_avatar_path,
  s.is_verified_business as seller_is_verified_business,
  s.rating_avg as seller_rating_avg,
  s.rating_count as seller_rating_count,
  i.removed_at,
  i.removal_reason,
  rb.full_name as removed_by_name,
  (select count(distinct oi.order_id)::integer
     from public.order_items oi
    where oi.item_id = i.id) as order_count,
  (select count(*)::integer
     from public.help_reports h
    where h.target_item_id = i.id
      and h.status in ('open', 'in_review')) as open_report_count
from public.marketplace_items i
join public.v_public_profiles s on s.id = i.seller_id
left join public.users rb on rb.id = i.removed_by
where i.deleted_at is null
  and (select private.is_admin());

revoke all on public.v_admin_marketplace_items from public, anon;
grant select on public.v_admin_marketplace_items to authenticated;
