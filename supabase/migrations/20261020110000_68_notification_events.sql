-- =====================================================================
-- 68_notification_events.sql  ·  what happens in the app notifies people
--
-- Each event inserts a row into public.notifications (migration 67), which
-- reaches the person in the app when they have it open, and as a push
-- otherwise:
--
--   | Event                                   | Who is told                   |
--   |-----------------------------------------|-------------------------------|
--   | A deed is verified, or rejected         | the project's owner           |
--   | A task is added to a project            | the other side of the project |
--   | A task is accepted                      | the other side of the project |
--   | A message is sent                       | everyone else in the chat     |
--
-- Nobody is told about what they did themselves. A notification that
-- can't be written never stops the event: the trigger logs a warning.
-- `data.type` names the event and carries its ids, for the screens that
-- will open them (ARCHITECTURE.md §13).
-- =====================================================================

-- Writes one notification; does nothing for nobody or a closed account.
create or replace function private.notify(
  p_user_id uuid, p_title text, p_body text, p_data jsonb default '{}'::jsonb)
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
  insert into public.notifications (user_id, title, body, data)
  values (
    p_user_id,
    left(btrim(p_title), 200),
    left(btrim(p_body), 1000),
    coalesce(p_data, '{}'::jsonb));
end;
$$;

revoke all on function private.notify(uuid, text, text, jsonb) from public, anon, authenticated;

-- A project's title in «», or nothing when it has none.
create or replace function private.notification_project_title(p_project_id uuid)
returns text
language sql
stable
security definer
set search_path to ''
as $$
  select case when nullif(btrim(p.title), '') is null then ''
              else '«' || btrim(p.title) || '»' end
    from public.projects p
   where p.id = p_project_id;
$$;

revoke all on function private.notification_project_title(uuid) from public, anon, authenticated;

-- 1. A deed is verified or rejected: the project's owner.
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
      jsonb_build_object('type', 'deed_verified', 'project_id', new.id));
  elsif new.deed_status = 'rejected' then
    perform private.notify(
      new.owner_id,
      'تم رفض صك الملكية',
      'ارفع صكًا جديدًا لمشروعك'
        || case when v_title = '' then '' else ' ' || v_title end
        || coalesce('. السبب: ' || nullif(btrim(new.deed_rejection_reason), ''), '.'),
      jsonb_build_object('type', 'deed_rejected', 'project_id', new.id));
  end if;
  return null;
exception when others then
  raise warning 'private.notify_deed_decision(%) failed: %', new.id, sqlerrm;
  return null;
end;
$$;

create trigger notifications_deed_decision
  after update of deed_status on public.projects
  for each row execute function private.notify_deed_decision();

-- 2. A task is added: the side of the project that didn't add it.
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
                           'task_id', new.id));
    end if;
  end loop;
  return null;
exception when others then
  raise warning 'private.notify_task_added(%) failed: %', new.id, sqlerrm;
  return null;
end;
$$;

create trigger notifications_task_added
  after insert on public.project_tasks
  for each row execute function private.notify_task_added();

-- 3. A task is accepted: the side of the project that didn't accept it
-- (the client accepts, so the contractor is told).
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
                           'task_id', new.id));
    end if;
  end loop;
  return null;
exception when others then
  raise warning 'private.notify_task_accepted(%) failed: %', new.id, sqlerrm;
  return null;
end;
$$;

create trigger notifications_task_accepted
  after update of status on public.project_tasks
  for each row execute function private.notify_task_accepted();

-- 4. A message is sent: everyone else in the chat. The title is who sent
-- it: their business's name, or their own.
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
                         'message_id', new.id));
  end loop;
  return null;
exception when others then
  raise warning 'private.notify_message(%) failed: %', new.id, sqlerrm;
  return null;
end;
$$;

create trigger notifications_message
  after insert on public.messages
  for each row execute function private.notify_message();

revoke all on function private.notify_deed_decision() from public, anon, authenticated;
revoke all on function private.notify_task_added() from public, anon, authenticated;
revoke all on function private.notify_task_accepted() from public, anon, authenticated;
revoke all on function private.notify_message() from public, anon, authenticated;
