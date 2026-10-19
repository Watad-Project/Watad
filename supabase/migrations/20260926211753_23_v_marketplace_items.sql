-- =====================================================================
-- 23_v_marketplace_items.sql  ·  VIEW: marketplace listings with seller
--
-- App (browse):  supabase.from('v_marketplace_items').select().eq('is_active', true)
-- App (my shop): supabase.from('v_marketplace_items').select().eq('is_mine', true)
-- Sellers also see their own inactive listings; deleted ones are hidden.
-- =====================================================================

create view public.v_marketplace_items
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
  (i.seller_id = (select auth.uid())) as is_mine
from public.marketplace_items i
join public.v_public_profiles s on s.id = i.seller_id
where i.deleted_at is null
  and (i.is_active or i.seller_id = (select auth.uid()));

comment on view public.v_marketplace_items is 'Live listings (and the caller''s own inactive ones) with the seller''s public card.';

revoke all on table public.v_marketplace_items from anon, authenticated;
grant select on table public.v_marketplace_items to authenticated;
;
