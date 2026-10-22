-- Admin user management (GRA-45): every user as an admin sees them.
--
-- One row per user, closed accounts included, returned to admins only:
-- * the profile: name, photo, role, member since, last seen and online
--   (the rule of v_public_profiles, migration 66), closed or not, and
--   is_me for the admin reading it;
-- * the business, when there is one: company, specialty, city and its
--   verification status (any status, not only verified);
-- * the open suspension, when there is one: reason, since when, by whom;
-- * activity: projects as a client (owner) and as a contractor (taker),
--   marketplace listings not deleted, and reports about them still open or
--   in review.
--
-- No ID number and no phone (user_identity): admins see the ID number only
-- of someone waiting for review (ARCHITECTURE.md §3).
--
-- security_invoker, like the other admin views: admins can read every row
-- of these tables, and anyone else gets no row at all.

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
      and h.status in ('open', 'in_review')) as open_report_count
from public.users u
left join public.businesses b on b.user_id = u.id
left join public.user_presence pr on pr.user_id = u.id
left join public.user_suspensions s
  on s.user_id = u.id and s.lifted_at is null
left join public.users sb on sb.id = s.suspended_by
where (select private.is_admin());

revoke all on public.v_admin_users from public, anon;
grant select on public.v_admin_users to authenticated;
