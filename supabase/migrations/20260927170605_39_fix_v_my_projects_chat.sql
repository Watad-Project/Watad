-- =====================================================================
-- 39_fix_v_my_projects_chat.sql
--
-- Bug (scenario 22, medium): v_my_projects.chat_id could point at a
-- losing bidder's chat. The view took the oldest project chat the
-- caller was in; if the owner had talked to another business before
-- hiring, messages from the project page went to that business.
--
-- Now chat_id is the chat that contains both the owner and the taker.
-- A project with no taker yet (draft or open) has no chat_id.
--
-- Replaces the definition in 27_v_my_projects.sql; columns and grants
-- are unchanged.
-- =====================================================================

create or replace view public.v_my_projects
with (security_invoker = true)
as
select
  p.id,
  p.title,
  p.description,
  p.status,
  p.budget,
  p.city,
  p.district,
  private.project_site_address(p.id) as site_address,
  case when p.owner_id = (select auth.uid()) then p.address_id end as address_id,
  p.created_at,
  p.updated_at,
  p.completed_at,
  case when p.owner_id = (select auth.uid()) then 'owner' else 'taker' end as my_role,
  p.owner_id,
  ow.full_name as owner_name,
  ow.avatar_path as owner_avatar_path,
  p.taker_id,
  tb.company_name as taker_company_name,
  tu.avatar_path as taker_avatar_path,
  ao.id as accepted_offer_id,
  ao.amount as agreed_amount,
  coalesce(pay.total_paid, 0) as total_paid,
  coalesce(pay.total_scheduled, 0) as total_scheduled,
  case when p.owner_id = (select auth.uid()) then private.project_offer_count(p.id) end as pending_offer_count,
  -- FIX: the chat between the owner and the taker, not simply the oldest
  -- project chat the caller is in.
  (select c.id
     from public.chats c
    where c.project_id = p.id
      and c.id in (select private.my_chat_ids())
      and exists (select 1 from public.chat_members m where m.chat_id = c.id and m.user_id = p.owner_id)
      and exists (select 1 from public.chat_members m where m.chat_id = c.id and m.user_id = p.taker_id)
    order by c.created_at
    limit 1) as chat_id,
  (p.status = 'completed' and not exists (
     select 1 from public.reviews r
     where r.project_id = p.id and r.reviewer_id = (select auth.uid())
  )) as can_review
from public.projects p
join public.users ow on ow.id = p.owner_id
left join public.businesses tb on tb.user_id = p.taker_id
left join public.users tu on tu.id = p.taker_id
left join public.project_offers ao on ao.project_id = p.id and ao.status = 'accepted'
left join lateral (
  select sum(pp.amount) filter (where pp.status = 'paid') as total_paid,
         sum(pp.amount) filter (where pp.status in ('pending', 'processing', 'paid')) as total_scheduled
  from public.project_payments pp
  where pp.project_id = p.id
) pay on true
where p.owner_id = (select auth.uid())
   or p.taker_id = (select auth.uid());
;
