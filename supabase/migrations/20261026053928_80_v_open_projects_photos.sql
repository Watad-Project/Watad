-- =====================================================================
-- 80_v_open_projects_photos.sql  ·  the project's photos in v_open_projects
--
-- The contractor's «ابحث عن عمل» cards and the send-offer page show the
-- project's first photo (contractor work tabs, GRA-26 / GRA-28). The photos
-- are projects.photo_paths, paths in the public `images` bucket
-- (`<user id>/projects/<file>`); v_my_projects returns them since
-- migration 71, but v_open_projects didn't.
--
-- The view of migration 26, unchanged, plus photo_paths as its last
-- column (create or replace view adds columns only at the end). An empty
-- array, never null, when there are none. The deed stays out: only the
-- owner and admins see it. Its grant (select to authenticated) stays.
-- =====================================================================

create or replace view public.v_open_projects
with (security_invoker = true) as
select p.id,
       p.title,
       p.description,
       p.budget,
       p.city,
       p.district,
       p.created_at,
       p.updated_at,
       p.owner_id,
       ow.display_name as owner_name,
       ow.avatar_path as owner_avatar_path,
       ow.rating_avg as owner_rating_avg,
       ow.rating_count as owner_rating_count,
       private.project_offer_count(p.id) as offer_count,
       my.id as my_offer_id,
       my.amount as my_offer_amount,
       my.status as my_offer_status,
       p.owner_id = (select auth.uid()) as is_mine,
       coalesce(p.photo_paths, '{}'::text[]) as photo_paths
  from public.projects p
  join public.v_public_profiles ow on ow.id = p.owner_id
  left join public.project_offers my
    on my.project_id = p.id
   and my.provider_id = (select auth.uid())
   and my.status = any (array['pending'::public.offer_status, 'accepted'::public.offer_status])
 where p.status = 'open'::public.project_status;

comment on view public.v_open_projects is
  'Open projects with public location, owner card, offer count, the caller''s own offer and the project''s photo paths (public images bucket).';
