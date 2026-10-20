-- =====================================================================
-- 66_presence.sql  ·  who is online now, and when they were last seen
--
-- Two halves:
--   * Live, in the app: Supabase Realtime Presence on the private channel
--     `online`. Every signed-in user joins it and tracks their user id,
--     so screens can show "online now" as it changes. Only signed-in
--     users may join (Realtime Authorization, policies on
--     realtime.messages), not anyone with the public anon key.
--   * Saved, in the database: user_presence. While the app is open it
--     calls set_my_presence(true) every minute; when it goes to the
--     background, set_my_presence(false). last_seen_at is the last call;
--     a user is online while online_until is in the future, so a phone
--     that dies without saying goodbye is offline within two minutes.
--     The server reads it to choose between an in-app notification and
--     a push (migration 67), and screens read it from v_public_profiles.
-- =====================================================================

-- 1. Saved presence.
create table public.user_presence (
  user_id      uuid        primary key references public.users (id),
  last_seen_at timestamptz not null default now(),
  online_until timestamptz not null default now()
);

alter table public.user_presence enable row level security;

-- Every signed-in user may see who is online and when others were last
-- seen; only set_my_presence() writes.
create policy user_presence_select on public.user_presence
  for select to authenticated
  using (true);

revoke all on public.user_presence from public, anon, authenticated;
grant select on public.user_presence to authenticated;

-- The app, while open (p_online true, every minute) and when it goes to
-- the background (false).
create or replace function public.set_my_presence(p_online boolean)
returns void
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_uid uuid := private.require_active_user();
begin
  insert into public.user_presence as p (user_id, last_seen_at, online_until)
  values (
    v_uid,
    now(),
    case when p_online then now() + interval '2 minutes' else now() end)
  on conflict (user_id) do update
     set last_seen_at = excluded.last_seen_at,
         online_until = excluded.online_until;
end;
$$;

revoke all on function public.set_my_presence(boolean) from public, anon;
grant execute on function public.set_my_presence(boolean) to authenticated;

-- For server code: whether the user has the app open now.
create or replace function private.is_online(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path to ''
as $$
  select exists (
    select 1 from public.user_presence p
     where p.user_id = p_user_id and p.online_until > now());
$$;

revoke all on function private.is_online(uuid) from public, anon, authenticated;

-- 2. The profile everyone sees, plus last_seen_at and is_online (last).
create or replace view public.v_public_profiles
with (security_invoker = true) as
select u.id,
       u.full_name as display_name,
       u.avatar_path,
       u.deleted_at is not null as is_deleted,
       u.created_at as member_since,
       b.user_id is not null and b.deleted_at is null as is_business,
       b.company_name,
       b.specialized_field,
       coalesce(b.verification_status = 'verified'::public.verification_status
                and b.deleted_at is null, false) as is_verified_business,
       r.rating_avg,
       r.rating_count,
       pr.last_seen_at,
       coalesce(pr.online_until > now(), false) as is_online
  from public.users u
  left join public.businesses b on b.user_id = u.id
  left join lateral (
    select round(avg(rv.rating), 2) as rating_avg,
           count(*)::integer as rating_count
      from public.reviews rv
     where rv.target_user_id = u.id
  ) r on true
  left join public.user_presence pr on pr.user_id = u.id;

-- 3. Live presence: the private Realtime channel `online`, for signed-in
-- users only.
create policy watad_presence_read on realtime.messages
  for select to authenticated
  using (realtime.topic() = 'online' and realtime.messages.extension = 'presence');

create policy watad_presence_track on realtime.messages
  for insert to authenticated
  with check (realtime.topic() = 'online' and realtime.messages.extension = 'presence');
