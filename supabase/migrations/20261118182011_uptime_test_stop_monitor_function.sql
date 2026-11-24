-- Stops the nonstop blockchain uptime monitor.
-- Sets the end time to now: no new checks are sent, and the scheduled job
-- removes itself within a few minutes, after it collects the last answer.
create or replace function uptime_test.stop_monitor() returns text
language plpgsql set search_path = '' as $$
declare
  v_end timestamptz;
begin
  if not exists (select 1 from cron.job where jobname = 'watad-uptime-test-24h') then
    return 'The uptime monitor is not running.';
  end if;

  select ends_at into v_end from uptime_test.settings;
  if v_end <= now() then
    return 'The uptime monitor is already stopping. The scheduled job removes itself within a few minutes.';
  end if;

  update uptime_test.settings set ends_at = now();
  return format('Stopped at %s (Riyadh time). No new checks will be sent. The scheduled job removes itself within a few minutes, after it collects the last answer.',
                to_char(now() at time zone 'Asia/Riyadh', 'YYYY-MM-DD HH24:MI'));
end $$;

revoke all on function uptime_test.stop_monitor() from public, anon, authenticated;;
