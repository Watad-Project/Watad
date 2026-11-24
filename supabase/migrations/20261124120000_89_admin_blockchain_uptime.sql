-- =====================================================================
-- 89_admin_blockchain_uptime.sql  ·  the blockchain's uptime for the admin (GRA-75)
--
-- The uptime monitor (the uptime_test migrations of 2026-11-16 to
-- 2026-11-18) checks the blockchain network every 2 minutes through the
-- blockchain-sync Edge Function's read-only check mode, and keeps every
-- check in uptime_test.checks. That schema stays closed to signed-in users;
-- the admin reads it here:
--   private.admin_blockchain_uptime() and v_admin_blockchain_uptime: one
--   row, admins only (no row for anyone else), like
--   v_admin_blockchain_summary (migration 81):
--     checks_24h, healthy_24h  the checks of the last 24 hours that have
--                              an answer, and how many found the network
--                              healthy
--     uptime_pct_24h           healthy_24h / checks_24h, in percent with 2
--                              decimals; null when there was no check
--     last_check_at            when the last answered check was sent
--     last_check_ok            whether it found the network healthy
--     monitor_running          the 2-minute job is scheduled and active,
--                              and the monitor has no end time behind it
-- A check that failed at Supabase's Edge Function gateway (HTTP 503) never
-- reached the blockchain, so it isn't counted, as in
-- uptime_test.uptime_report(). Read-only.
-- =====================================================================

create or replace function private.admin_blockchain_uptime()
returns table (
  checks_24h      integer,
  healthy_24h     integer,
  uptime_pct_24h  numeric,
  last_check_at   timestamptz,
  last_check_ok   boolean,
  monitor_running boolean
)
language sql
stable
security definer
set search_path to ''
as $$
  with answered as (
    select c.sent_at, c.ok
      from uptime_test.checks c
     where c.collected_at is not null
       and coalesce(c.http_status, 0) <> 503
  ),
  day as (
    select a.ok from answered a where a.sent_at >= now() - interval '24 hours'
  ),
  last_check as (
    select a.sent_at, a.ok from answered a order by a.sent_at desc limit 1
  )
  select (select count(*)::integer from day),
         (select count(*)::integer from day where day.ok),
         (select round(100.0 * count(*) filter (where day.ok)
                       / nullif(count(*), 0), 2)
            from day),
         (select last_check.sent_at from last_check),
         (select last_check.ok from last_check),
         exists (select 1 from cron.job j
                  where j.jobname = 'watad-uptime-test-24h' and j.active)
           and coalesce((select s.ends_at > now() from uptime_test.settings s),
                        false)
   where (select private.is_admin());
$$;

revoke all on function private.admin_blockchain_uptime() from public, anon;
grant execute on function private.admin_blockchain_uptime() to authenticated, service_role;

create or replace view public.v_admin_blockchain_uptime
with (security_invoker = true) as
select u.checks_24h,
       u.healthy_24h,
       u.uptime_pct_24h,
       u.last_check_at,
       u.last_check_ok,
       u.monitor_running
  from private.admin_blockchain_uptime() u;

comment on view public.v_admin_blockchain_uptime is
  'Admins only (no row for anyone else): the blockchain network''s uptime over the last 24 hours from the uptime monitor, its last check and whether the monitor runs.';

revoke all on public.v_admin_blockchain_uptime from public, anon, authenticated;
grant select on public.v_admin_blockchain_uptime to authenticated;
