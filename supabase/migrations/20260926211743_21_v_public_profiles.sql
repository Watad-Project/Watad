-- =====================================================================
-- 21_v_public_profiles.sql  ·  VIEW: what anyone may see about a user
--
-- App: supabase.from('v_public_profiles').select().eq('id', userId).single()
-- No role, no CR number, no dates beyond "member since". Closed
-- accounts show as "Deleted user".
-- =====================================================================

create view public.v_public_profiles
with (security_invoker = true)
as
select
  u.id,
  u.full_name as display_name,
  u.avatar_path,
  (u.deleted_at is not null) as is_deleted,
  u.created_at as member_since,
  (b.user_id is not null and b.deleted_at is null) as is_business,
  b.company_name,
  b.specialized_field,
  coalesce(b.verification_status = 'verified' and b.deleted_at is null, false) as is_verified_business,
  r.rating_avg,
  r.rating_count
from public.users u
left join public.businesses b on b.user_id = u.id
left join lateral (
  select round(avg(rv.rating), 2) as rating_avg,
         count(*)::integer as rating_count
  from public.reviews rv
  where rv.target_user_id = u.id
) r on true;

comment on view public.v_public_profiles is 'Public card for any user: name, avatar, business badge, rating.';

revoke all on table public.v_public_profiles from anon, authenticated;
grant select on table public.v_public_profiles to authenticated;
;
