-- The admin dashboard shows who is online now, next to the active users
-- (migration 73).
--
-- online_users: users with the app open, by the same rule as
-- v_public_profiles.is_online and private.is_online() (migration 66):
-- `online_until` still in the future. Admins are left out, like
-- active_users. The app refreshes it every time the dashboard shows.
--
-- The view is migration 73's with online_users added last (a replaced view
-- may only add columns at the end).

create or replace view public.v_admin_dashboard
with (security_invoker = true)
as
select
  (select count(*)::integer
     from public.users u
    where u.deleted_at is null
      and u.role <> 'admin'
      and not exists (
        select 1 from public.user_suspensions s
        where s.user_id = u.id and s.lifted_at is null
      )) as active_users,
  (select count(*)::integer
     from public.users u
    where u.deleted_at is null
      and u.role <> 'admin'
      and not exists (select 1 from public.businesses b where b.user_id = u.id)
  ) as clients,
  (select count(*)::integer
     from public.businesses b
    where b.deleted_at is null) as businesses,
  (select count(*)::integer
     from public.businesses b
    where b.deleted_at is null
      and b.verification_status = 'verified') as verified_businesses,
  (select count(*)::integer from public.projects) as projects,
  (select count(*)::integer
     from public.projects p where p.status = 'draft') as projects_draft,
  (select count(*)::integer
     from public.projects p where p.status = 'open') as projects_open,
  (select count(*)::integer
     from public.projects p where p.status = 'in_progress') as projects_in_progress,
  (select count(*)::integer
     from public.projects p where p.status = 'completed') as projects_completed,
  (select count(*)::integer
     from public.projects p where p.status = 'cancelled') as projects_cancelled,
  (select count(*)::integer
     from public.marketplace_items i
    where i.deleted_at is null) as market_items,
  (select count(*)::integer
     from public.marketplace_items i
    where i.deleted_at is null
      and i.is_active
      and i.removed_at is null) as market_items_live,
  (select count(*)::integer
     from public.businesses b
    where b.verification_status = 'pending'
      and b.deleted_at is null) as pending_licenses,
  (select count(*)::integer
     from public.projects p
    where p.deed_status = 'under_review'
      and p.deed_storage_path is not null) as pending_deeds,
  (select count(*)::integer
     from public.help_reports h
    where h.status = 'open') as open_reports,
  (select count(*)::integer
     from public.users u
     join public.user_presence p on p.user_id = u.id
    where u.deleted_at is null
      and u.role <> 'admin'
      and p.online_until > now()) as online_users
where (select private.is_admin());

revoke all on public.v_admin_dashboard from public, anon;
grant select on public.v_admin_dashboard to authenticated;
