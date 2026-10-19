-- =====================================================================
-- 25_v_order_items.sql  ·  VIEW: the lines of an order
--
-- App: supabase.from('v_order_items').select().eq('order_id', orderId)
-- getSubtotal() = subtotal. Name and price are purchase-time snapshots.
-- =====================================================================

create view public.v_order_items
with (security_invoker = true)
as
select
  oi.order_id,
  o.status as order_status,
  oi.item_id,
  oi.item_name,
  oi.quantity,
  oi.price_at_purchase,
  oi.subtotal,
  oi.created_at
from public.order_items oi
join public.orders o on o.id = oi.order_id;

comment on view public.v_order_items is 'Order lines visible to the order''s buyer, seller and admins.';

revoke all on table public.v_order_items from anon, authenticated;
grant select on table public.v_order_items to authenticated;
;
