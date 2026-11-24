-- Starts the nonstop blockchain uptime monitor (the opposite of stop_monitor).
-- Removes the end time and makes sure the 2-minute scheduled job exists.
create or replace function uptime_test.start_monitor() returns text
language plpgsql set search_path = '' as $$
declare
  v_end timestamptz;
  v_job boolean;
begin
  select ends_at into v_end from uptime_test.settings;
  v_job := exists (select 1 from cron.job where jobname = 'watad-uptime-test-24h');

  if v_job and v_end = 'infinity' then
    return 'The uptime monitor is already running. Nothing changed.';
  end if;

  update uptime_test.settings set ends_at = 'infinity';

  if not v_job then
    perform cron.schedule('watad-uptime-test-24h', '*/2 * * * *', 'select uptime_test.run_check()');
  end if;

  return format('Started at %s (Riyadh time). A check is sent every 2 minutes, nonstop. The first one goes out within 2 minutes.',
                to_char(now() at time zone 'Asia/Riyadh', 'YYYY-MM-DD HH24:MI'));
end $$;

revoke all on function uptime_test.start_monitor() from public, anon, authenticated;;
