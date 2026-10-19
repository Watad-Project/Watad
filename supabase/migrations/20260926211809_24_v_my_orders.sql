-- =====================================================================
-- 24_v_my_orders.sql  ·  VIEW: orders the signed-in user bought or sold
--
-- App: supabase.from('v_my_orders').select().eq('my_role', 'buyer')
--        .order('created_at', ascending: false)
-- calculateTotal() = total_amount (fixed at checkout from DB prices).
-- =====================================================================

create view public.v_my_orders
with (security_invoker = true)
as
select
  o.id,
  o.status,
  o.payment_method,
  o.total_amount,
  o.currency,
  o.card_brand,
  o.card_last4,
  o.paid_at,
  o.created_at,
  o.updated_at,
  case when o.buyer_id = (select auth.uid()) then 'buyer' else 'seller' end as my_role,
  o.buyer_id,
  bu.full_name as buyer_name,
  bu.avatar_path as buyer_avatar_path,
  o.seller_id,
  su.full_name as seller_name,
  su.avatar_path as seller_avatar_path,
  li.line_count,
  li.unit_count,
  (o.status = 'delivered' and not exists (
     select 1 from public.reviews r
     where r.order_id = o.id and r.reviewer_id = (select auth.uid())
  )) as can_review
from public.orders o
join public.users bu on bu.id = o.buyer_id
join public.users su on su.id = o.seller_id
left join lateral (
  select count(*)::integer as line_count,
         coalesce(sum(oi.quantity), 0)::integer as unit_count
  from public.order_items oi
  where oi.order_id = o.id
) li on true
where o.buyer_id = (select auth.uid())
   or o.seller_id = (select auth.uid());

comment on view public.v_my_orders is 'Caller''s orders as buyer or seller, with counterparty names, line counts and can_review.';

revoke all on table public.v_my_orders from anon, authenticated;
grant select on table public.v_my_orders to authenticated;
;
