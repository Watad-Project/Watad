-- Blockchain uptime report: last 24 hours, last 7 days, last 30 days and all time.
-- Reads uptime_test.checks only. Checks that failed at Supabase's Edge Function
-- gateway (HTTP 503) never reached the blockchain, so they are shown separately
-- and not counted in the uptime.
create or replace function uptime_test.uptime_report()
returns table(
  period text,
  from_riyadh timestamp,
  to_riyadh timestamp,
  checks bigint,
  healthy bigint,
  failed bigint,
  not_counted_gateway bigint,
  uptime_pct numeric,
  avg_response_s numeric,
  median_response_s numeric,
  p95_response_s numeric,
  note text
)
language sql stable set search_path = '' as $$
  with periods(ord, period, since) as (
    values (1, 'Last 24 hours', now() - interval '24 hours'),
           (2, 'Last 7 days',   now() - interval '7 days'),
           (3, 'Last 30 days',  now() - interval '30 days'),
           (4, 'All time',      '-infinity'::timestamptz)
  )
  select
    p.period,
    (case when p.ord = 4 then (select min(x.sent_at) from uptime_test.checks x) else p.since end) at time zone 'Asia/Riyadh',
    now() at time zone 'Asia/Riyadh',
    count(c.id) filter (where coalesce(c.http_status, 0) <> 503),
    count(c.id) filter (where c.ok),
    count(c.id) filter (where not c.ok and coalesce(c.http_status, 0) <> 503),
    count(c.id) filter (where c.http_status = 503),
    round(100.0 * count(c.id) filter (where c.ok)
          / nullif(count(c.id) filter (where coalesce(c.http_status, 0) <> 503), 0), 2),
    round(avg(extract(epoch from c.chain_answered_at - c.sent_at))::numeric, 2),
    round((percentile_cont(0.5)  within group (order by extract(epoch from c.chain_answered_at - c.sent_at)))::numeric, 2),
    round((percentile_cont(0.95) within group (order by extract(epoch from c.chain_answered_at - c.sent_at)))::numeric, 2),
    case when count(c.id) = 0 then 'No checks in this period (the uptime test is not running)' end
  from periods p
  left join uptime_test.checks c
    on c.sent_at >= p.since and c.collected_at is not null
  group by p.ord, p.period, p.since
  order by p.ord;
$$;

revoke all on function uptime_test.uptime_report() from public, anon, authenticated;;
