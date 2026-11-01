-- =====================================================================
-- 86_profile_cr_lock_and_city.sql  ·  the edit profile screen (GRA-60)
--
-- Feature (GRA-60, opened from the account tabs of GRA-59): a user edits
-- their name and photo, and a contractor their business: company name,
-- specialty, city and commercial registration (CR) number.
--
--   1. private.businesses_lock_cr_number(): once a business is verified,
--      its CR number can't change: the admin verified the business with
--      that number. The app shows it read-only then; this trigger is the
--      safety net. It raises cr_number_locked with 42501 (the caller may
--      not do it, APP_ARCHITECTURE.md §13). In every other status the
--      number stays editable; changing it, or the company name, while
--      the business is pending still sends it back to unverified
--      (private.businesses_reset_verification(), migration 02). No
--      server function writes cr_number, so nothing is exempt.
--   2. v_my_profile gains the business's city (migration 61) as its last
--      column, so the edit screen shows the city the contractor saved.
--      Otherwise it is migration 45's view, unchanged.
--
-- Changes no rows and notifies nobody.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. A verified business keeps its CR number
-- ---------------------------------------------------------------------
create or replace function private.businesses_lock_cr_number()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.cr_number is distinct from old.cr_number
     and old.verification_status = 'verified' then
    raise exception 'cr_number_locked' using errcode = '42501';
  end if;
  return new;
end;
$$;

revoke all on function private.businesses_lock_cr_number() from public, anon, authenticated;

-- BEFORE triggers fire in name order, so this one runs before
-- businesses_reset_verification and businesses_set_updated_at: a locked
-- change is refused before anything else touches the row. It reads
-- old.verification_status, which no trigger changes, so it would refuse
-- in any order; the name only keeps the refusal first.
create trigger businesses_lock_cr_number
  before update on public.businesses
  for each row execute function private.businesses_lock_cr_number();

-- ---------------------------------------------------------------------
-- 2. v_my_profile: the business's city
-- ---------------------------------------------------------------------
-- Migration 45's view, with b.city added last: a view can only gain
-- columns after its last one.
create or replace view public.v_my_profile
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
  b.verified_at,
  (s.id is not null) as is_suspended,
  s.reason as suspension_reason,
  b.city
from public.users u
left join public.businesses b on b.user_id = u.id
left join public.user_suspensions s on s.user_id = u.id and s.lifted_at is null
where u.id = (select auth.uid());

revoke all on table public.v_my_profile from public, anon, authenticated;
grant select on table public.v_my_profile to authenticated;
