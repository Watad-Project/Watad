-- =====================================================================
-- 69_notification_pop_up.sql  ·  which pushes pop up over the screen
--
-- Android shows a push over the screen (heads-up) only on a channel of
-- importance Urgent, at high priority. OneSignal has two channels for
-- Watad: "pop up" and "normal". notifications.pop_up says which one a
-- push uses; send-push picks the channel from it (ARCHITECTURE.md §13).
--
-- Every event of migration 68 pops up: deed decisions, a task added or
-- accepted, a message. A notification inserted without pop_up (a test, a
-- later campaign) uses the normal channel. iOS is unaffected.
-- =====================================================================

-- For the server (send-push) only.
alter table public.notifications
  add column if not exists pop_up boolean not null default false;

-- send-push gets pop_up with the row (migration 67's push_claim, plus it).
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
     set push_status = case when private.is_online(n.user_id) then 'in_app' else 'sent' end,
         pushed_at   = now(),
         push_error  = null
   where n.id = p_notification_id and n.push_status = 'pending'
  returning n.* into v_row;
  if not found or v_row.push_status = 'in_app' then
    return null;
  end if;
  return jsonb_build_object(
    'user_id', v_row.user_id,
    'title',   v_row.title,
    'body',    v_row.body,
    'data',    v_row.data,
    'pop_up',  v_row.pop_up);
end;
$$;

-- private.notify() takes p_pop_up. The old four-argument version goes
-- first: with both, a four-argument call would match two functions.
drop function if exists private.notify(uuid, text, text, jsonb);

create or replace function private.notify(
  p_user_id uuid, p_title text, p_body text, p_data jsonb default '{}'::jsonb,
  p_pop_up boolean default false)
returns void
language plpgsql
security definer
set search_path to ''
as $$
begin
  if p_user_id is null
     or not exists (select 1 from public.users u
                     where u.id = p_user_id and u.deleted_at is null) then
    return;
  end if;
  insert into public.notifications (user_id, title, body, data, pop_up)
  values (
    p_user_id,
    left(btrim(p_title), 200),
    left(btrim(p_body), 1000),
    coalesce(p_data, '{}'::jsonb),
    coalesce(p_pop_up, false));
end;
$$;

revoke all on function private.notify(uuid, text, text, jsonb, boolean) from public, anon, authenticated;

-- The events of migration 68 now pop up. Their triggers already call these.
create or replace function private.notify_deed_decision()
returns trigger
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_title text := private.notification_project_title(new.id);
begin
  if new.deed_status is not distinct from old.deed_status then
    return null;
  end if;
  if new.deed_status = 'verified' then
    perform private.notify(
      new.owner_id,
      'تم توثيق صك الملكية',
      case when v_title = '' then 'نُشر مشروعك وأصبح متاحًا للمقاولين.'
           else 'نُشر مشروعك ' || v_title || ' وأصبح متاحًا للمقاولين.' end,
      jsonb_build_object('type', 'deed_verified', 'project_id', new.id),
      true);
  elsif new.deed_status = 'rejected' then
    perform private.notify(
      new.owner_id,
      'تم رفض صك الملكية',
      'ارفع صكًا جديدًا لمشروعك'
        || case when v_title = '' then '' else ' ' || v_title end
        || coalesce('. السبب: ' || nullif(btrim(new.deed_rejection_reason), ''), '.'),
      jsonb_build_object('type', 'deed_rejected', 'project_id', new.id),
      true);
  end if;
  return null;
exception when others then
  raise warning 'private.notify_deed_decision(%) failed: %', new.id, sqlerrm;
  return null;
end;
$$;

create or replace function private.notify_task_added()
returns trigger
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_project public.projects;
  v_title   text := private.notification_project_title(new.project_id);
  v_user    uuid;
begin
  select * into v_project from public.projects where id = new.project_id;
  foreach v_user in array array[v_project.owner_id, v_project.taker_id] loop
    if v_user is distinct from new.created_by then
      perform private.notify(
        v_user,
        'مهمة جديدة في مشروعك',
        coalesce(nullif(btrim(new.title), ''), 'مهمة')
          || case when v_title = '' then '' else ' — ' || v_title end,
        jsonb_build_object('type', 'task_added', 'project_id', new.project_id,
                           'task_id', new.id),
        true);
    end if;
  end loop;
  return null;
exception when others then
  raise warning 'private.notify_task_added(%) failed: %', new.id, sqlerrm;
  return null;
end;
$$;

create or replace function private.notify_task_accepted()
returns trigger
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_project public.projects;
  v_title   text := private.notification_project_title(new.project_id);
  v_actor   uuid := auth.uid();
  v_user    uuid;
begin
  if new.status <> 'accepted' or old.status = 'accepted' then
    return null;
  end if;
  select * into v_project from public.projects where id = new.project_id;
  foreach v_user in array array[v_project.owner_id, v_project.taker_id] loop
    if v_user is distinct from coalesce(v_actor, v_project.owner_id) then
      perform private.notify(
        v_user,
        'تم قبول المهمة',
        coalesce(nullif(btrim(new.title), ''), 'مهمة')
          || case when v_title = '' then '' else ' — ' || v_title end,
        jsonb_build_object('type', 'task_accepted', 'project_id', new.project_id,
                           'task_id', new.id),
        true);
    end if;
  end loop;
  return null;
exception when others then
  raise warning 'private.notify_task_accepted(%) failed: %', new.id, sqlerrm;
  return null;
end;
$$;

create or replace function private.notify_message()
returns trigger
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_sender text;
  v_member record;
begin
  select coalesce(nullif(btrim(b.company_name), ''), nullif(btrim(u.full_name), ''), 'رسالة جديدة')
    into v_sender
    from public.users u
    left join public.businesses b on b.user_id = u.id and b.deleted_at is null
   where u.id = new.sender_id;
  for v_member in
    select m.user_id from public.chat_members m
     where m.chat_id = new.chat_id and m.user_id <> new.sender_id
  loop
    perform private.notify(
      v_member.user_id,
      coalesce(v_sender, 'رسالة جديدة'),
      coalesce(nullif(btrim(new.content), ''), 'رسالة جديدة'),
      jsonb_build_object('type', 'message', 'chat_id', new.chat_id,
                         'message_id', new.id),
      true);
  end loop;
  return null;
exception when others then
  raise warning 'private.notify_message(%) failed: %', new.id, sqlerrm;
  return null;
end;
$$;
