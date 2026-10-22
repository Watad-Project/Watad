-- =====================================================================
-- 71_v_my_projects_photos.sql  ·  the project's photos in v_my_projects
--
-- The client's «مشاريعي» cards show the project's first photo (and the
-- striped placeholder without one). The photos are projects.photo_paths,
-- paths in the public `images` bucket (`<user id>/projects/<file>`), sent
-- with the project (ARCHITECTURE.md §3a); v_my_projects didn't return them.
--
-- The view of migration 64, unchanged, plus photo_paths as its last
-- column (create or replace view adds columns only at the end). Both sides
-- of a project see them; an empty array, never null, when there are none.
-- Its grant (select to authenticated) stays as it was.
-- =====================================================================

create or replace view public.v_my_projects
with (security_invoker = true) as
select p.id,
       p.title,
       p.description,
       p.status,
       p.budget,
       p.city,
       p.district,
       private.project_site_address(p.id) as site_address,
       case when p.owner_id = (select auth.uid()) then p.address_id else null::uuid end as address_id,
       p.created_at,
       p.updated_at,
       p.completed_at,
       case when p.owner_id = (select auth.uid()) then 'owner'::text else 'taker'::text end as my_role,
       p.owner_id,
       ow.full_name as owner_name,
       ow.avatar_path as owner_avatar_path,
       p.taker_id,
       tb.company_name as taker_company_name,
       tu.avatar_path as taker_avatar_path,
       ao.id as accepted_offer_id,
       ao.amount as agreed_amount,
       coalesce(pay.total_paid, 0::numeric) as total_paid,
       coalesce(pay.total_scheduled, 0::numeric) as total_scheduled,
       case when p.owner_id = (select auth.uid()) then private.project_offer_count(p.id) else null::integer end as pending_offer_count,
       (select c.id
          from public.chats c
         where c.project_id = p.id
           and c.id in (select private.my_chat_ids())
           and exists (select 1 from public.chat_members m where m.chat_id = c.id and m.user_id = p.owner_id)
           and exists (select 1 from public.chat_members m where m.chat_id = c.id and m.user_id = p.taker_id)
         order by c.created_at
         limit 1) as chat_id,
       p.status = 'completed'::public.project_status
         and not exists (select 1 from public.reviews r
                          where r.project_id = p.id and r.reviewer_id = (select auth.uid())) as can_review,
       case when p.owner_id = (select auth.uid()) then p.deed_status end as deed_status,
       case when p.owner_id = (select auth.uid()) then p.deed_rejection_reason end as deed_rejection_reason,
       coalesce(p.photo_paths, '{}'::text[]) as photo_paths
  from public.projects p
  join public.users ow on ow.id = p.owner_id
  left join public.businesses tb on tb.user_id = p.taker_id
  left join public.users tu on tu.id = p.taker_id
  left join public.project_offers ao on ao.project_id = p.id and ao.status = 'accepted'::public.offer_status
  left join lateral (
    select sum(pp.amount) filter (where pp.status = 'paid'::public.payment_status) as total_paid,
           sum(pp.amount) filter (where pp.status = any (array['pending'::public.payment_status, 'processing'::public.payment_status, 'paid'::public.payment_status])) as total_scheduled
      from public.project_payments pp
     where pp.project_id = p.id
  ) pay on true
 where p.owner_id = (select auth.uid()) or p.taker_id = (select auth.uid());

