-- The admin dashboard (GRA-43): the platform's numbers in one row.
--
-- Each count uses the same rule as the screen it summarizes:
-- * active users: not deleted and not suspended (private.is_active_user()),
--   admins left out;
-- * clients: users with no businesses row who aren't admins (a client is a
--   user without a business, ARCHITECTURE.md §2);
-- * pending licenses and deeds: the rows of v_admin_verification_queue and
--   v_admin_deed_queue, so the dashboard always matches the review tab;
-- * open tickets: help_reports still `open` (GRA-44's «مفتوحة»).
--
-- security_invoker, like the other admin views: admins can read every row
-- of these tables, and anyone else gets no row at all.

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
    where h.status = 'open') as open_reports
where (select private.is_admin());

revoke all on public.v_admin_dashboard from public, anon;
grant select on public.v_admin_dashboard to authenticated;
