-- =====================================================================
-- 87_notification_preferences.sql  ·  muting groups of notifications (GRA-62)
--
-- The settings screen has one switch per group of notifications. A muted
-- group stops the phone notification and the pop-up; the notification is
-- still saved and listed in the app.
--   1. The notification_group enum and notification_preferences (user,
--      group, push on or off). No row means on. Each user reads only their
--      own rows and writes them only through set_notification_preference().
--   2. v_my_notification_preferences: every group, with its switch.
--   3. private.notification_group_of(): the one mapping from a
--      notification's data.type to its group. A new type needs one line
--      there. A type without a group (deeds, verification, the bank details
--      reminder, suspension) is always sent.
--   4. private.notify() still saves every notification. When its group is
--      muted, the row is saved without the pop-up and with push_status
--      'muted', which push_claim() never takes, so send-push skips it; and
--      the push trigger doesn't call send-push for it at all.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Groups and preferences
-- ---------------------------------------------------------------------

create type public.notification_group as enum (
  'messages',     -- «الرسائل»
  'projects',     -- «العروض والمشاريع»
  'tasks',        -- «مهام المشروع»
  'marketplace'   -- «الطلبات والسوق»
);

create table public.notification_preferences (
  user_id            uuid not null default auth.uid()
                     references public.users (id) on delete cascade,
  notification_group public.notification_group not null,
  push_enabled       boolean not null,
  updated_at         timestamptz not null default now(),
  primary key (user_id, notification_group)
);

comment on table public.notification_preferences is
  'Whether a user gets the push and pop-up of a group of notifications. No row means on. Written only by set_notification_preference().';

alter table public.notification_preferences enable row level security;

create policy notification_preferences_select_own
  on public.notification_preferences for select
  to authenticated
  using (user_id = (select auth.uid()));

revoke all on table public.notification_preferences from public, anon, authenticated;
grant select on table public.notification_preferences to authenticated;

-- ---------------------------------------------------------------------
-- 2. Every group, with its switch
-- ---------------------------------------------------------------------

create view public.v_my_notification_preferences
with (security_invoker = true) as
select g.notification_group,
       coalesce(p.push_enabled, true) as push_enabled
  from unnest(enum_range(null::public.notification_group)) as g (notification_group)
  left join public.notification_preferences p
    on p.user_id = (select auth.uid())
   and p.notification_group = g.notification_group
 where (select auth.uid()) is not null;

comment on view public.v_my_notification_preferences is
  'Every notification group, and whether the signed-in user gets its push and pop-up (on when never set).';

revoke all on public.v_my_notification_preferences from public, anon, authenticated;
grant select on public.v_my_notification_preferences to authenticated;

create function public.set_notification_preference(
  p_group   public.notification_group,
  p_enabled boolean
)
returns void
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_uid uuid := private.require_active_user();
begin
  if p_group is null or p_enabled is null then
    raise exception 'invalid_preference' using errcode = '22023';
  end if;
  insert into public.notification_preferences as p
    (user_id, notification_group, push_enabled)
  values (v_uid, p_group, p_enabled)
  on conflict (user_id, notification_group) do update
     set push_enabled = excluded.push_enabled,
         updated_at   = now();
end;
$$;

revoke all on function public.set_notification_preference(public.notification_group, boolean) from public, anon;
grant execute on function public.set_notification_preference(public.notification_group, boolean) to authenticated;

-- ---------------------------------------------------------------------
-- 3. The one mapping from a type to its group
-- ---------------------------------------------------------------------

create or replace function private.notification_group_of(p_type text)
returns public.notification_group
language sql
immutable
set search_path to ''
as $$
  select case
    when p_type = 'message' then 'messages'
    when p_type in ('offer_received', 'offer_accepted', 'offer_rejected')
      then 'projects'
    when p_type in ('task_added', 'task_accepted', 'task_update_sent',
                    'task_update_accepted', 'task_update_rejected')
      then 'tasks'
    when p_type like 'order\_%' then 'marketplace'
    -- deed_verified, deed_rejected, bank_details_missing, and anything
    -- about the account: always sent.
    else null
  end::public.notification_group;
$$;

revoke all on function private.notification_group_of(text) from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- 4. notify() respects a muted group
-- ---------------------------------------------------------------------

alter table public.notifications drop constraint if exists notifications_push_status_check;
alter table public.notifications
  add constraint notifications_push_status_check
  check (push_status in ('pending', 'in_app', 'sent', 'failed', 'muted'));

create or replace function private.notify(
  p_user_id uuid,
  p_title   text,
  p_body    text,
  p_data    jsonb default '{}'::jsonb,
  p_pop_up  boolean default false
)
returns void
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_group public.notification_group :=
    private.notification_group_of(coalesce(p_data, '{}'::jsonb) ->> 'type');
  v_muted boolean := false;
begin
  if p_user_id is null
     or not exists (select 1 from public.users u
                     where u.id = p_user_id and u.deleted_at is null) then
    return;
  end if;
  if v_group is not null then
    v_muted := exists (
      select 1 from public.notification_preferences p
       where p.user_id = p_user_id
         and p.notification_group = v_group
         and not p.push_enabled);
  end if;
  insert into public.notifications (user_id, title, body, data, pop_up, push_status)
  values (
    p_user_id,
    left(btrim(p_title), 200),
    left(btrim(p_body), 1000),
    coalesce(p_data, '{}'::jsonb),
    coalesce(p_pop_up, false) and not v_muted,
    case when v_muted then 'muted' else 'pending' end);
end;
$$;

-- A muted notification has nothing to send.
create or replace function private.notifications_push()
returns trigger
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_secret text;
begin
  if new.push_status <> 'pending' then
    return null;
  end if;
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
