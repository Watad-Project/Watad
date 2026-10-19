-- =====================================================================
-- 61_contractors_directory.sql  ·  the client's list of contractors
--
-- The client's home suggests contractors and lists them all (GRA-23),
-- with filters by city, rating and completed projects, and contractors
-- in the client's own city first. The database had no city for a
-- business, and nobody could count another user's completed projects
-- (projects are private to their parties).
--
--   1. businesses.city: the contractor's city, set by the contractor at
--      the specialty step from the location picker (GRA-16, GRA-19).
--   2. private.completed_project_count(user): how many projects the user
--      completed as the contractor. Only the number leaves the function.
--   3. v_contractors: verified contractors with their city, rating,
--      completed projects, and is_in_my_city (their city is the city of
--      the caller's latest saved address).
--
-- Safe to run more than once.
-- =====================================================================

-- 1. A business's city, written by its owner.
alter table public.businesses
  add column if not exists city text;

grant insert (city), update (city) on public.businesses to authenticated;

-- 2. Completed projects of a contractor, without exposing the projects.
create or replace function private.completed_project_count(p_user_id uuid)
returns integer
language sql
stable
security definer
set search_path to ''
as $$
  select count(*)::integer
  from public.projects
  where taker_id = p_user_id
    and status = 'completed';
$$;

revoke all on function private.completed_project_count(uuid) from public, anon;
grant execute on function private.completed_project_count(uuid) to authenticated;

-- 3. The contractors a client can find.
create or replace view public.v_contractors
with (security_invoker = true) as
select
  p.id,
  p.company_name,
  p.avatar_path,
  p.specialized_field,
  b.city,
  p.rating_avg,
  p.rating_count,
  private.completed_project_count(p.id) as completed_project_count,
  coalesce(b.city is not null and b.city = mine.city, false) as is_in_my_city,
  p.member_since
from public.v_public_profiles p
join public.businesses b on b.user_id = p.id
-- The caller's city: their latest saved address (addresses are private,
-- so this only ever reads the caller's own).
left join lateral (
  select a.city
  from public.addresses a
  where a.owner_id = (select auth.uid())
  order by a.created_at desc
  limit 1
) mine on true
where p.is_verified_business
  and not p.is_deleted;

revoke all on public.v_contractors from public, anon;
grant select on public.v_contractors to authenticated;
