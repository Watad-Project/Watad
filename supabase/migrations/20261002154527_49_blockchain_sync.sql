create extension if not exists pg_net;
create extension if not exists pg_cron with schema pg_catalog;

create schema if not exists blockchain_sync;
revoke all on schema blockchain_sync from public, anon, authenticated;

create table if not exists blockchain_sync.state (
  project_id      uuid        primary key,
  version         bigint      not null default 1,
  dirty           boolean     not null default true,
  next_attempt_at timestamptz not null default now(),
  claimed_until   timestamptz,
  attempts        integer     not null default 0,
  last_attempt_at timestamptz,
  synced_at       timestamptz,
  last_outcome    text check (last_outcome in ('ok', 'retry', 'failed')),
  last_message    text
);
alter table blockchain_sync.state enable row level security;
create index if not exists blockchain_sync_state_due on blockchain_sync.state (next_attempt_at) where dirty;
revoke all on all tables in schema blockchain_sync from public, anon, authenticated;

do $$
begin
  if not exists (select 1 from vault.secrets where name = 'blockchain_sync_secret') then
    perform vault.create_secret(
      replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''),
      'blockchain_sync_secret',
      'Shared secret between the database and the blockchain-sync Edge Function');
  end if;
end $$;

create or replace function blockchain_sync.check_secret(p_secret text)
returns boolean language sql stable security definer set search_path = '' as $$
  select coalesce((select s.decrypted_secret = p_secret
                     from vault.decrypted_secrets s where s.name = 'blockchain_sync_secret'), false)
$$;

create or replace function blockchain_sync.kick()
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_secret text;
begin
  if not exists (select 1 from blockchain_sync.state s
                  where s.dirty and s.next_attempt_at <= now()
                    and (s.claimed_until is null or s.claimed_until < now())) then
    return;
  end if;
  select s.decrypted_secret into v_secret from vault.decrypted_secrets s where s.name = 'blockchain_sync_secret';
  perform net.http_post(
    url := 'https://nwgqhlqlpyaffoqfsebd.supabase.co/functions/v1/blockchain-sync',
    body := '{}'::jsonb,
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-sync-secret', v_secret),
    timeout_milliseconds := 120000);
end $$;

create or replace function blockchain_sync.mark(p_project_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_was_dirty boolean;
begin
  if p_project_id is null then return; end if;
  if not exists (select 1 from public.projects p where p.id = p_project_id and p.taker_id is not null) then return; end if;

  select s.dirty into v_was_dirty from blockchain_sync.state s where s.project_id = p_project_id for update;
  insert into blockchain_sync.state (project_id) values (p_project_id)
  on conflict (project_id) do update
     set version = blockchain_sync.state.version + 1, dirty = true, next_attempt_at = now(), attempts = 0;
  if v_was_dirty is distinct from true then
    perform blockchain_sync.kick();
  end if;
exception when others then
  raise warning 'blockchain_sync.mark(%) failed: %', p_project_id, sqlerrm;
end $$;

create or replace function blockchain_sync.on_project_change()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'INSERT' or new.taker_id is distinct from old.taker_id or new.owner_id is distinct from old.owner_id then
    perform blockchain_sync.mark(new.id);
  end if;
  return null;
exception when others then
  raise warning 'blockchain_sync.on_project_change failed: %', sqlerrm;
  return null;
end $$;

create or replace function blockchain_sync.on_offer_change()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.status = 'accepted' or (tg_op = 'UPDATE' and old.status = 'accepted') then
    if tg_op = 'INSERT' or old.status is distinct from new.status or old.amount is distinct from new.amount then
      perform blockchain_sync.mark(new.project_id);
    end if;
  end if;
  return null;
exception when others then
  raise warning 'blockchain_sync.on_offer_change failed: %', sqlerrm;
  return null;
end $$;

create or replace function blockchain_sync.on_task_change()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'DELETE' then
    perform blockchain_sync.mark(old.project_id);
  elsif tg_op = 'INSERT' then
    perform blockchain_sync.mark(new.project_id);
  elsif old.description is distinct from new.description
     or old.start_date   is distinct from new.start_date
     or old.finish_date  is distinct from new.finish_date
     or old.status       is distinct from new.status
     or old.project_id   is distinct from new.project_id then
    perform blockchain_sync.mark(new.project_id);
    if old.project_id is distinct from new.project_id then
      perform blockchain_sync.mark(old.project_id);
    end if;
  end if;
  return null;
exception when others then
  raise warning 'blockchain_sync.on_task_change failed: %', sqlerrm;
  return null;
end $$;

create or replace function blockchain_sync.on_payment_change()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'DELETE' then
    if old.status = 'paid' then perform blockchain_sync.mark(old.project_id); end if;
  elsif tg_op = 'INSERT' then
    if new.status = 'paid' then perform blockchain_sync.mark(new.project_id); end if;
  elsif (old.status = 'paid' or new.status = 'paid')
    and (old.status      is distinct from new.status
      or old.amount      is distinct from new.amount
      or old.paid_at     is distinct from new.paid_at
      or old.description is distinct from new.description) then
    perform blockchain_sync.mark(new.project_id);
  end if;
  return null;
exception when others then
  raise warning 'blockchain_sync.on_payment_change failed: %', sqlerrm;
  return null;
end $$;

create or replace function blockchain_sync.on_user_change()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  r record;
begin
  if new.full_name is distinct from old.full_name then
    for r in select p.id from public.projects p where p.owner_id = new.id or p.taker_id = new.id loop
      perform blockchain_sync.mark(r.id);
    end loop;
  end if;
  return null;
exception when others then
  raise warning 'blockchain_sync.on_user_change failed: %', sqlerrm;
  return null;
end $$;

create or replace function blockchain_sync.on_business_change()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  r record;
begin
  if new.company_name is distinct from old.company_name then
    for r in select p.id from public.projects p where p.taker_id = new.user_id loop
      perform blockchain_sync.mark(r.id);
    end loop;
  end if;
  return null;
exception when others then
  raise warning 'blockchain_sync.on_business_change failed: %', sqlerrm;
  return null;
end $$;

drop trigger if exists blockchain_sync_projects   on public.projects;
drop trigger if exists blockchain_sync_offers     on public.project_offers;
drop trigger if exists blockchain_sync_tasks      on public.project_tasks;
drop trigger if exists blockchain_sync_payments   on public.project_payments;
drop trigger if exists blockchain_sync_users      on public.users;
drop trigger if exists blockchain_sync_businesses on public.businesses;

create trigger blockchain_sync_projects   after insert or update on public.projects
  for each row execute function blockchain_sync.on_project_change();
create trigger blockchain_sync_offers     after insert or update on public.project_offers
  for each row execute function blockchain_sync.on_offer_change();
create trigger blockchain_sync_tasks      after insert or update or delete on public.project_tasks
  for each row execute function blockchain_sync.on_task_change();
create trigger blockchain_sync_payments   after insert or update or delete on public.project_payments
  for each row execute function blockchain_sync.on_payment_change();
create trigger blockchain_sync_users      after update of full_name on public.users
  for each row execute function blockchain_sync.on_user_change();
create trigger blockchain_sync_businesses after update of company_name on public.businesses
  for each row execute function blockchain_sync.on_business_change();

create or replace function blockchain_sync.snapshot(p_project_id uuid)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare
  v jsonb;
begin
  select jsonb_build_object(
           'id',         p.id,
           'owner',      left(u.full_name, 500),
           'contractor', left(b.company_name, 500),
           'agreedPrice', o.amount,
           'currency',   'SAR',
           'milestone',  coalesce((select jsonb_agg(jsonb_strip_nulls(jsonb_build_object(
                                      'description', t.description,
                                      'startDate',   t.start_date,
                                      'finishDate',  t.finish_date,
                                      'status',      t.status)) order by t.created_at, t.id)
                                     from public.project_tasks t where t.project_id = p.id), '[]'::jsonb),
           'payments',   coalesce((select jsonb_agg(jsonb_strip_nulls(jsonb_build_object(
                                      'id',     x.id,
                                      'amount', x.amount,
                                      'date',   (coalesce(x.paid_at, x.updated_at) at time zone 'Asia/Riyadh')::date,
                                      'note',   left(nullif(btrim(x.description), ''), 500)))
                                    order by coalesce(x.paid_at, x.updated_at), x.stage_number, x.id)
                                     from public.project_payments x
                                    where x.project_id = p.id and x.status = 'paid'), '[]'::jsonb))
    into v
    from public.projects p
    join public.users u      on u.id = p.owner_id
    join public.businesses b on b.user_id = p.taker_id
    join lateral (select po.amount from public.project_offers po
                   where po.project_id = p.id and po.status = 'accepted'
                   order by po.decided_at desc nulls last limit 1) o on true
   where p.id = p_project_id and p.taker_id is not null;
  return v;
end $$;

create or replace function blockchain_sync.resync(p_project_id uuid default null)
returns integer language plpgsql security definer set search_path = '' as $$
declare
  r record;
  n integer := 0;
begin
  for r in select p.id from public.projects p
            where p.taker_id is not null and (p_project_id is null or p.id = p_project_id) loop
    perform blockchain_sync.mark(r.id);
    n := n + 1;
  end loop;
  return n;
end $$;

create or replace function public.blockchain_sync_claim(p_secret text, p_limit integer default 5)
returns table (pid uuid, ver bigint)
language plpgsql security definer set search_path = '' as $$
begin
  if not blockchain_sync.check_secret(p_secret) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  return query
  with c as (
    select s.project_id
      from blockchain_sync.state s
     where s.dirty and s.next_attempt_at <= now()
       and (s.claimed_until is null or s.claimed_until < now())
     order by s.next_attempt_at
     limit least(greatest(p_limit, 0), 20)
       for update skip locked),
  u as (
    update blockchain_sync.state s
       set claimed_until = now() + interval '3 minutes', last_attempt_at = now()
      from c where s.project_id = c.project_id
    returning s.project_id, s.version)
  select u.project_id, u.version from u;
end $$;

create or replace function public.blockchain_sync_snapshot(p_secret text, p_project_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
begin
  if not blockchain_sync.check_secret(p_secret) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  return blockchain_sync.snapshot(p_project_id);
end $$;

create or replace function public.blockchain_sync_complete(
  p_secret text, p_project_id uuid, p_version bigint, p_outcome text, p_message text default null)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if not blockchain_sync.check_secret(p_secret) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if p_outcome not in ('ok', 'retry', 'failed') then
    raise exception 'outcome must be ok, retry or failed' using errcode = '22023';
  end if;

  if p_outcome = 'retry' then
    update blockchain_sync.state s
       set attempts        = s.attempts + 1,
           next_attempt_at = case when s.version <> p_version then now()
                                  else now() + make_interval(secs => least(15 * power(2, s.attempts), 3600)) end,
           claimed_until   = null,
           last_outcome    = 'retry',
           last_message    = left(p_message, 1000)
     where s.project_id = p_project_id;
  else
    update blockchain_sync.state s
       set dirty         = (s.version <> p_version),
           claimed_until = null,
           attempts      = 0,
           synced_at     = case when p_outcome = 'ok' then now() else s.synced_at end,
           last_outcome  = p_outcome,
           last_message  = left(p_message, 1000)
     where s.project_id = p_project_id;
  end if;
end $$;

revoke all on all functions in schema blockchain_sync from public, anon, authenticated;
revoke all on function public.blockchain_sync_claim(text, integer)                          from public, anon, authenticated;
revoke all on function public.blockchain_sync_snapshot(text, uuid)                          from public, anon, authenticated;
revoke all on function public.blockchain_sync_complete(text, uuid, bigint, text, text)      from public, anon, authenticated;
grant execute on function public.blockchain_sync_claim(text, integer)                       to service_role;
grant execute on function public.blockchain_sync_snapshot(text, uuid)                       to service_role;
grant execute on function public.blockchain_sync_complete(text, uuid, bigint, text, text)   to service_role;

select cron.schedule('blockchain-sync-retry', '*/2 * * * *', 'select blockchain_sync.kick()');
;
