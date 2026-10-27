-- =====================================================================
-- 81_admin_blockchain_monitor.sql  ·  the admin's blockchain monitor (GRA-53)
--
-- Admins watch the blockchain sync of migration 49 (ARCHITECTURE.md §9):
--   1. private.admin_blockchain_sync_rows() and v_admin_blockchain_sync:
--      one row per contracted project (a row of blockchain_sync.state),
--      with the project's title, the client's name, the contractor's
--      company and one sync_status:
--        failed    the last run reported NEEDS ATTENTION, or the chain
--                  refused the record: a person has to look; not retried
--        retrying  waiting to run again after a failed attempt
--        waiting   a change waits to be copied (also after a resync)
--        synced    the chain matches the database
--   2. private.admin_blockchain_summary() and v_admin_blockchain_summary:
--      one row of counts per sync_status, the last successful sync and the
--      last run of the cron job blockchain-sync-retry.
--   3. admin_blockchain_resync(p_project_id): marks one project to sync
--      again, through blockchain_sync.resync(). Resyncing every project at
--      once stays out of the app (an open question of GRA-53).
--
-- The blockchain_sync and cron schemas stay closed to signed-in users. The
-- views are security_invoker, like the other admin views, and read through
-- SECURITY DEFINER functions that return no row to anyone but an admin.
-- Read-only except the resync, which only marks the project; the
-- blockchain-sync Edge Function still does every write to the chain.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. One row per contracted project
-- ---------------------------------------------------------------------

create or replace function private.admin_blockchain_sync_rows()
returns table (
  project_id      uuid,
  project_title   text,
  project_status  public.project_status,
  owner_id        uuid,
  owner_name      text,
  contractor_id   uuid,
  contractor_name text,
  sync_status     text,
  version         bigint,
  attempts        integer,
  last_attempt_at timestamptz,
  next_attempt_at timestamptz,
  synced_at       timestamptz,
  last_outcome    text,
  last_message    text
)
language sql
stable
security definer
set search_path to ''
as $$
  select s.project_id,
         p.title,
         p.status,
         p.owner_id,
         nullif(btrim(ou.full_name), ''),
         p.taker_id,
         nullif(btrim(b.company_name), ''),
         case
           when s.dirty and s.last_outcome = 'retry' then 'retrying'
           when s.dirty then 'waiting'
           when s.last_outcome = 'failed' then 'failed'
           when s.last_outcome = 'ok' then 'synced'
           else 'waiting'
         end,
         s.version,
         s.attempts,
         s.last_attempt_at,
         -- Only while something waits; a synced or failed project has none.
         case when s.dirty then s.next_attempt_at end,
         s.synced_at,
         s.last_outcome,
         s.last_message
    from blockchain_sync.state s
    join public.projects p on p.id = s.project_id
    left join public.users ou on ou.id = p.owner_id
    left join public.businesses b on b.user_id = p.taker_id
   where p.taker_id is not null
     and (select private.is_admin());
$$;

revoke all on function private.admin_blockchain_sync_rows() from public, anon;
grant execute on function private.admin_blockchain_sync_rows() to authenticated, service_role;

create or replace view public.v_admin_blockchain_sync
with (security_invoker = true) as
select r.project_id,
       r.project_title,
       r.project_status,
       r.owner_id,
       r.owner_name,
       r.contractor_id,
       r.contractor_name,
       r.sync_status,
       r.version,
       r.attempts,
       r.last_attempt_at,
       r.next_attempt_at,
       r.synced_at,
       r.last_outcome,
       r.last_message
  from private.admin_blockchain_sync_rows() r;

comment on view public.v_admin_blockchain_sync is
  'Admins only: the blockchain sync of each contracted project, with its title, client, contractor and sync_status (failed, retrying, waiting, synced).';

revoke all on public.v_admin_blockchain_sync from public, anon, authenticated;
grant select on public.v_admin_blockchain_sync to authenticated;

-- ---------------------------------------------------------------------
-- 2. The summary: counts, the last sync and the retry job
-- ---------------------------------------------------------------------

create or replace function private.admin_blockchain_summary()
returns table (
  projects              integer,
  synced                integer,
  waiting               integer,
  retrying              integer,
  failed                integer,
  last_synced_at        timestamptz,
  retry_job_active      boolean,
  retry_job_schedule    text,
  retry_job_last_run_at timestamptz,
  retry_job_last_status text
)
language sql
stable
security definer
set search_path to ''
as $$
  with r as (
    select * from private.admin_blockchain_sync_rows()
  ),
  job as (
    select j.jobid, j.active, j.schedule
      from cron.job j
     where j.jobname = 'blockchain-sync-retry'
  ),
  last_run as (
    select d.start_time, d.status
      from cron.job_run_details d
      join job on job.jobid = d.jobid
     order by d.start_time desc
     limit 1
  )
  select (select count(*)::integer from r),
         (select count(*)::integer from r where r.sync_status = 'synced'),
         (select count(*)::integer from r where r.sync_status = 'waiting'),
         (select count(*)::integer from r where r.sync_status = 'retrying'),
         (select count(*)::integer from r where r.sync_status = 'failed'),
         (select max(r.synced_at) from r),
         (select job.active from job),
         (select job.schedule from job),
         (select last_run.start_time from last_run),
         (select last_run.status from last_run)
   where (select private.is_admin());
$$;

revoke all on function private.admin_blockchain_summary() from public, anon;
grant execute on function private.admin_blockchain_summary() to authenticated, service_role;

create or replace view public.v_admin_blockchain_summary
with (security_invoker = true) as
select s.projects,
       s.synced,
       s.waiting,
       s.retrying,
       s.failed,
       s.last_synced_at,
       s.retry_job_active,
       s.retry_job_schedule,
       s.retry_job_last_run_at,
       s.retry_job_last_status
  from private.admin_blockchain_summary() s;

comment on view public.v_admin_blockchain_summary is
  'Admins only (no row for anyone else): contracted projects per sync_status, the last successful sync and the last run of the blockchain-sync-retry job.';

revoke all on public.v_admin_blockchain_summary from public, anon, authenticated;
grant select on public.v_admin_blockchain_summary to authenticated;

-- ---------------------------------------------------------------------
-- 3. Resync one project
-- ---------------------------------------------------------------------

create or replace function public.admin_blockchain_resync(p_project_id uuid)
returns void
language plpgsql
security definer
set search_path to ''
as $$
begin
  perform private.require_admin();

  if p_project_id is null then
    raise exception 'project_required' using errcode = '22023';
  end if;

  if not exists (
    select 1
      from blockchain_sync.state s
      join public.projects p on p.id = s.project_id
     where s.project_id = p_project_id
       and p.taker_id is not null
  ) then
    raise exception 'sync_project_not_found' using errcode = 'P0002';
  end if;

  -- Marks it waiting (a new version, attempts back to 0) and wakes the
  -- blockchain-sync Edge Function.
  perform blockchain_sync.resync(p_project_id);
end;
$$;

revoke all on function public.admin_blockchain_resync(uuid) from public, anon;
grant execute on function public.admin_blockchain_resync(uuid) to authenticated;
