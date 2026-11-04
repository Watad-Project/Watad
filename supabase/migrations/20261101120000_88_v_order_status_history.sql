-- =====================================================================
-- 88_v_order_status_history.sql  ·  the order timeline (GRA-69)
--
-- Feature (GRA-69, and the seller's side in GRA-71): the order details
-- page shows each status an order went through, with its time. The
-- changes are in status_history (migration 16), written by the trigger
-- orders_status_history, but the app reads only views (golden rule 3)
-- and no view exposed them.
--
--   1. v_order_status_history: order_id, old_status, new_status and
--      changed_at of the rows that belong to an order. No note (English
--      server text, never shown in the app) and no changed_by.
--   2. security_invoker, so the RLS of status_history decides the rows:
--      the order's buyer and seller, and admins (status_history_select).
--
-- Changes no rows and notifies nobody.
-- =====================================================================

create view public.v_order_status_history
with (security_invoker = true) as
select sh.order_id,
       sh.old_status,
       sh.new_status,
       sh.changed_at
  from public.status_history sh
 where sh.order_id is not null;

comment on view public.v_order_status_history is
  'Status changes of the orders the caller can see (buyer, seller, admins). Order by changed_at. Read-only.';

revoke all on public.v_order_status_history from public, anon, authenticated;
grant select on public.v_order_status_history to authenticated;
