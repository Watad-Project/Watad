-- =====================================================================
-- 28_v_project_offers.sql  ·  VIEW: offers with the provider's card
--
-- App (owner):    supabase.from('v_project_offers').select().eq('project_id', id)
-- App (provider): supabase.from('v_project_offers').select().eq('is_mine', true)
-- Owners see every offer on their project; providers see only their own.
-- Accept with supabase.rpc('accept_offer', params: {'p_offer_id': id,
-- 'p_expected_amount': amountShown}).
-- =====================================================================

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
;
