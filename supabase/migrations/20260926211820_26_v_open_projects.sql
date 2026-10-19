-- =====================================================================
-- 26_v_open_projects.sql  ·  VIEW: the job board
--
-- App: supabase.from('v_open_projects').select().eq('city', 'Riyadh')
--        .order('created_at', ascending: false)
-- Shows city/district only, never the street address. offer_count is a
-- number; businesses never see each other's offers. my_offer_* is the
-- caller's own live offer, if any.
-- =====================================================================

create view public.v_open_projects
with (security_invoker = true)
as
select
  p.id,
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
  (p.owner_id = (select auth.uid())) as is_mine
from public.projects p
join public.v_public_profiles ow on ow.id = p.owner_id
left join public.project_offers my
  on my.project_id = p.id
 and my.provider_id = (select auth.uid())
 and my.status in ('pending', 'accepted')
where p.status = 'open';

comment on view public.v_open_projects is 'Open projects with public location, owner card, offer count and the caller''s own offer.';

revoke all on table public.v_open_projects from anon, authenticated;
grant select on table public.v_open_projects to authenticated;
;
