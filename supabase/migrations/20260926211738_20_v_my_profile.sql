-- =====================================================================
-- 20_v_my_profile.sql  ·  VIEW: the signed-in user's own profile
--
-- App: supabase.from('v_my_profile').select().single()
-- All views run with the caller's permissions (security_invoker), so
-- every RLS rule on the underlying tables still applies.
-- =====================================================================

create view public.v_my_profile
with (security_invoker = true)
as
select
  u.id,
  u.full_name,
  u.avatar_path,
  u.role,
  (u.role = 'admin') as is_admin,
  u.created_at,
  u.updated_at,
  (b.user_id is not null and b.deleted_at is null) as is_business,
  b.company_name,
  b.cr_number,
  b.specialized_field,
  b.verification_status,
  b.verified_at
from public.users u
left join public.businesses b on b.user_id = u.id
where u.id = (select auth.uid());

comment on view public.v_my_profile is 'Signed-in user''s profile plus their business profile, if any.';

revoke all on table public.v_my_profile from anon, authenticated;
grant select on table public.v_my_profile to authenticated;
;
