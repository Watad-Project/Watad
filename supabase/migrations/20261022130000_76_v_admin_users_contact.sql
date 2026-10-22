-- Admin user management (GRA-45): an admin sees how to reach a user and
-- who they are: their email, phone and ID/iqama number.
--
-- This changes a rule, approved by a maintainer (Ameer, 2026-10-22): until
-- now admins saw the ID number only of someone waiting for review, and
-- never the phone (migration 65, ARCHITECTURE.md §3). Now every admin sees
-- all three, for every user, in v_admin_users only.
--
-- * email: from Supabase Auth (auth.users), which the app can't read.
-- * phone and ID number: from user_identity (owner-only); null for a user
--   who never finished sign-up, and for a closed account (the row is
--   deleted then).
--
-- Like private.admin_national_id() (migration 65), each lookup is security
-- definer and returns nothing unless the caller is an admin. Personal data:
-- never log it.

create or replace function private.admin_user_email(p_user_id uuid)
returns text
language sql
stable
security definer
set search_path to ''
as $$
  select a.email::text
    from auth.users a
   where a.id = p_user_id
     and (select private.is_admin());
$$;

revoke all on function private.admin_user_email(uuid) from public, anon;
grant execute on function private.admin_user_email(uuid) to authenticated;

create or replace function private.admin_user_phone(p_user_id uuid)
returns text
language sql
stable
security definer
set search_path to ''
as $$
  select i.phone
    from public.user_identity i
   where i.user_id = p_user_id
     and (select private.is_admin());
$$;

revoke all on function private.admin_user_phone(uuid) from public, anon;
grant execute on function private.admin_user_phone(uuid) to authenticated;

-- Migration 75's view, plus email, phone and national_id (last: a replaced
-- view may only add columns at the end).
create or replace view public.v_admin_users
with (security_invoker = true)
as
select
  u.id,
  u.full_name,
  u.avatar_path,
  u.role,
  u.created_at as member_since,
  u.deleted_at is not null as is_deleted,
  u.id = (select auth.uid()) as is_me,
  pr.last_seen_at,
  coalesce(pr.online_until > now(), false) as is_online,
  (b.user_id is not null and b.deleted_at is null) as is_business,
  b.company_name,
  b.specialized_field,
  b.city as business_city,
  case when b.deleted_at is null then b.verification_status end
    as verification_status,
  s.id is not null as is_suspended,
  s.reason as suspension_reason,
  s.suspended_at,
  sb.full_name as suspended_by_name,
  (select count(*)::integer
     from public.projects p where p.owner_id = u.id) as client_project_count,
  (select count(*)::integer
     from public.projects p where p.taker_id = u.id) as contractor_project_count,
  (select count(*)::integer
     from public.marketplace_items i
    where i.seller_id = u.id and i.deleted_at is null) as listing_count,
  (select count(*)::integer
     from public.help_reports h
    where h.target_user_id = u.id
      and h.status in ('open', 'in_review')) as open_report_count,
  private.admin_user_email(u.id) as email,
  private.admin_user_phone(u.id) as phone,
  private.admin_national_id(u.id) as national_id
from public.users u
left join public.businesses b on b.user_id = u.id
left join public.user_presence pr on pr.user_id = u.id
left join public.user_suspensions s
  on s.user_id = u.id and s.lifted_at is null
left join public.users sb on sb.id = s.suspended_by
where (select private.is_admin());

revoke all on public.v_admin_users from public, anon;
grant select on public.v_admin_users to authenticated;
