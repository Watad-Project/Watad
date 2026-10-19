-- =====================================================================
-- 66_notifications.sql  ·  in-app notifications and push (GRA-32)
--
-- To notify a user, the server inserts a row into public.notifications.
-- Right after the insert, a trigger asks the send-push Edge Function to
-- deliver it as a push through OneSignal (to the devices signed in as
-- that user: OneSignal's external_id is the user id). The app reads its
-- own rows through v_my_notifications and marks them read with
-- mark_notifications_read(); it never inserts one and never calls
-- OneSignal.
--
--   1. public.notifications, readable by its user only;
--   2. v_my_notifications and mark_notifications_read();
--   3. the push: a Vault secret shared with send-push, the trigger, and
--      push_claim() / push_complete(), which only the function calls.
-- =====================================================================

-- 1. The notifications.
create table public.notifications (
  id         uuid        primary key default gen_random_uuid(),
  user_id    uuid        not null references public.users (id),
  title      text        not null check (char_length(btrim(title)) between 1 and 200),
  body       text        not null check (char_length(btrim(body)) between 1 and 1000),
  -- Where a tap leads, e.g. {"route": "client-projects"} (ARCHITECTURE.md §13).
  data       jsonb       not null default '{}'::jsonb check (jsonb_typeof(data) = 'object'),
  read_at    timestamptz,
  created_at timestamptz not null default now(),
  -- Delivery, for the server only: set by push_complete().
  pushed_at  timestamptz,
  push_error text
);

create index notifications_user_created on public.notifications (user_id, created_at desc);

alter table public.notifications enable row level security;

create policy notifications_select_own on public.notifications
  for select to authenticated
  using (user_id = (select auth.uid()));

-- Read-only for the app: rows are written by the server.
revoke all on public.notifications from public, anon, authenticated;
grant select on public.notifications to authenticated;

-- 2. What the app reads and does.
create view public.v_my_notifications
with (security_invoker = true) as
select n.id,
       n.title,
       n.body,
       n.data,
       n.read_at,
       n.created_at
  from public.notifications n
 where n.user_id = (select auth.uid());

revoke all on public.v_my_notifications from public, anon, authenticated;
grant select on public.v_my_notifications to authenticated;

-- Marks the caller's notifications read: [p_ids], or all of them when
-- null. Returns how many changed.
create or replace function public.mark_notifications_read(p_ids uuid[] default null)
returns integer
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_uid   uuid := private.require_active_user();
  v_count integer;
begin
  update public.notifications n
     set read_at = now()
   where n.user_id = v_uid
     and n.read_at is null
     and (p_ids is null or n.id = any (p_ids));
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke all on function public.mark_notifications_read(uuid[]) from public, anon;
grant execute on function public.mark_notifications_read(uuid[]) to authenticated;

-- 3. The push.
do $$
begin
  if not exists (select 1 from vault.secrets where name = 'push_secret') then
    perform vault.create_secret(
      replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''),
      'push_secret',
      'Shared secret between the database and the send-push Edge Function');
  end if;
end $$;

create or replace function private.push_check_secret(p_secret text)
returns boolean
language sql
stable
security definer
set search_path to ''
as $$
  select coalesce((select s.decrypted_secret = p_secret
                     from vault.decrypted_secrets s
                    where s.name = 'push_secret'), false);
$$;

-- After an insert: ask send-push to deliver the row. A failure here never
-- blocks the insert; the row keeps pushed_at null.
create or replace function private.notifications_push()
returns trigger
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_secret text;
begin
  select s.decrypted_secret into v_secret
    from vault.decrypted_secrets s
   where s.name = 'push_secret';
  perform net.http_post(
    url := 'https://nwgqhlqlpyaffoqfsebd.supabase.co/functions/v1/send-push',
    body := jsonb_build_object('notification_id', new.id),
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-push-secret', v_secret),
    timeout_milliseconds := 10000);
  return null;
exception when others then
  raise warning 'private.notifications_push(%) failed: %', new.id, sqlerrm;
  return null;
end;
$$;

create trigger notifications_push
  after insert on public.notifications
  for each row execute function private.notifications_push();

-- send-push: the row to deliver, once. Null when it was already sent (or
-- doesn't exist), so a repeated call sends nothing.
create or replace function public.push_claim(p_secret text, p_notification_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_row public.notifications;
begin
  if not private.push_check_secret(p_secret) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  update public.notifications n
     set pushed_at = now(), push_error = null
   where n.id = p_notification_id and n.pushed_at is null
  returning n.* into v_row;
  if not found then
    return null;
  end if;
  return jsonb_build_object(
    'user_id', v_row.user_id,
    'title',   v_row.title,
    'body',    v_row.body,
    'data',    v_row.data);
end;
$$;

-- send-push: how the delivery went. With an error the row is marked not
-- sent again, with the reason.
create or replace function public.push_complete(
  p_secret text, p_notification_id uuid, p_error text default null)
returns void
language plpgsql
security definer
set search_path to ''
as $$
begin
  if not private.push_check_secret(p_secret) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if p_error is not null then
    update public.notifications n
       set pushed_at = null, push_error = left(p_error, 1000)
     where n.id = p_notification_id;
  end if;
end;
$$;

revoke all on function private.push_check_secret(text) from public, anon, authenticated;
revoke all on function private.notifications_push() from public, anon, authenticated;
revoke all on function public.push_claim(text, uuid) from public, anon, authenticated;
revoke all on function public.push_complete(text, uuid, text) from public, anon, authenticated;
grant execute on function public.push_claim(text, uuid) to service_role;
grant execute on function public.push_complete(text, uuid, text) to service_role;
