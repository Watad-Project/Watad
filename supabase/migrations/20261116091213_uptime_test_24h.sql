-- Temporary 24-hour availability test of the blockchain network (report section 5.5.2).
-- Calls the blockchain-sync Edge Function in its read-only check mode every 2 minutes.
-- Writes nothing to app data. The scheduled job removes itself after 24 hours.

create schema if not exists uptime_test;
revoke all on schema uptime_test from public, anon, authenticated;

create table uptime_test.settings (
  id int primary key default 1 check (id = 1),
  starts_at timestamptz not null,
  ends_at timestamptz not null
);

create table uptime_test.checks (
  id bigserial primary key,
  request_id bigint unique,
  sent_at timestamptz not null default clock_timestamp(),
  collected_at timestamptz,
  http_status int,
  ok boolean,
  network_status text,
  orderer text,
  peer_platform text,
  peer_adminorg text,
  in_sync boolean,
  block_height int,
  chain_answered_at timestamptz,
  error text
);

alter table uptime_test.settings enable row level security;
alter table uptime_test.checks enable row level security;
revoke all on all tables in schema uptime_test from public, anon, authenticated;

insert into uptime_test.settings (starts_at, ends_at) values (now(), now() + interval '24 hours');

create or replace function uptime_test.try_jsonb(p text) returns jsonb
language plpgsql immutable set search_path = '' as $$
begin
  return p::jsonb;
exception when others then
  return null;
end $$;

create or replace function uptime_test.run_check() returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_secret text;
  v_req bigint;
  v_end timestamptz;
begin
  -- 1. Collect answers that have arrived
  update uptime_test.checks c set
    collected_at      = now(),
    http_status       = r.status_code,
    ok                = coalesce(r.status_code = 200
                          and j->>'check' = 'ok'
                          and j->'blockchain'->>'status' = 'healthy', false),
    network_status    = j->'blockchain'->>'status',
    orderer           = j->'blockchain'->'nodes'->'orderer'->>'status',
    peer_platform     = j->'blockchain'->'nodes'->'peer0.platform'->>'status',
    peer_adminorg     = j->'blockchain'->'nodes'->'peer0.adminorg'->>'status',
    in_sync           = (j->'blockchain'->'channel'->>'inSync')::boolean,
    block_height      = (j->'blockchain'->'channel'->'peers'->'peer0.platform'->>'height')::int,
    chain_answered_at = (j->'blockchain'->>'timestamp')::timestamptz,
    error             = coalesce(r.error_msg,
                                 case when r.timed_out then 'timed out' end,
                                 case when r.status_code <> 200 then left(r.content::text, 300) end)
  from net._http_response r
  cross join lateral (select uptime_test.try_jsonb(r.content::text) as j) x
  where r.id = c.request_id and c.collected_at is null;

  -- 2. Count a check with no answer after 10 minutes as failed
  update uptime_test.checks
     set collected_at = now(), ok = false, error = 'no response within 10 minutes'
   where collected_at is null and sent_at < now() - interval '10 minutes';

  -- 3. After 24 hours: stop sending, and remove the job once the last answers are in
  select ends_at into v_end from uptime_test.settings;
  if now() >= v_end then
    if not exists (select 1 from uptime_test.checks where collected_at is null)
       or now() >= v_end + interval '12 minutes' then
      perform cron.unschedule('watad-uptime-test-24h');
    end if;
    return;
  end if;

  -- 4. Send the next check (read-only check mode)
  select s.decrypted_secret into v_secret from vault.decrypted_secrets s where s.name = 'blockchain_sync_secret';
  v_req := net.http_post(
    url := 'https://nwgqhlqlpyaffoqfsebd.supabase.co/functions/v1/blockchain-sync',
    body := '{"check": true}'::jsonb,
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-sync-secret', v_secret),
    timeout_milliseconds := 30000);
  insert into uptime_test.checks (request_id, sent_at) values (v_req, clock_timestamp());
end $$;

revoke all on function uptime_test.try_jsonb(text) from public, anon, authenticated;
revoke all on function uptime_test.run_check() from public, anon, authenticated;

select cron.schedule('watad-uptime-test-24h', '*/2 * * * *', 'select uptime_test.run_check()');;
