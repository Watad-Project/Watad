-- =====================================================================
-- 59_restore_v_project_offers.sql  ·  restore the view of migration 28
--
-- After 2026-10-14, v_project_offers was replaced outside any migration.
-- The replacement:
--   1. had no security_invoker, so it ran with the owner's rights and
--      skipped the RLS of project_offers: every caller saw every offer;
--   2. was granted to anon, so anyone with the public key could read all
--      offers without signing in;
--   3. made up contractor_rating and duration_months from the amount, and
--      a contractor name ('مقاول معتمد') when there was none;
--   4. dropped project_title, project_status, the provider_* columns and
--      decided_at.
-- This restores migration 28's definition and grants exactly.
-- =====================================================================

drop view if exists public.v_project_offers;

create view public.v_project_offers
with (security_invoker = true)
as
select
  po.id,
  po.project_id,
  p.title as project_title,
  p.status as project_status,
  po.provider_id,
  pr.company_name as provider_company_name,
  pr.specialized_field as provider_specialized_field,
  pr.is_verified_business as provider_is_verified,
  pr.avatar_path as provider_avatar_path,
  pr.rating_avg as provider_rating_avg,
  pr.rating_count as provider_rating_count,
  po.amount,
  po.message,
  po.status,
  po.created_at,
  po.updated_at,
  po.decided_at,
  (po.provider_id = (select auth.uid())) as is_mine
from public.project_offers po
join public.projects p on p.id = po.project_id
join public.v_public_profiles pr on pr.id = po.provider_id;

comment on view public.v_project_offers is 'Offers visible to the caller (own offers, or all offers on own projects) with provider badge and rating.';

revoke all on table public.v_project_offers from anon, authenticated;
grant select on table public.v_project_offers to authenticated;
