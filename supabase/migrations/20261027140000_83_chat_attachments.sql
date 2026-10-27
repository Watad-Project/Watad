-- =====================================================================
-- 83_chat_attachments.sql  ·  private chat photos (GRA-54)
--
-- What the conversation screen (GRA-56) needs to send photos, kept
-- private: only the members of a chat can upload or see them.
--   1. The private bucket "chat-attachments": JPEG, PNG and WebP up to
--      10 MB, files at <chat id>/<file id>.<ext>. Members of the chat
--      upload to and read its folder (private.my_chat_ids(), the check
--      messages uses); nobody updates or deletes, as messages are
--      insert-only. The app shows them through short-lived signed URLs.
--   2. messages.attachment_path and attachment_mime. content becomes
--      optional: a message has text, a photo, or both. A path outside the
--      chat's own folder is refused.
--   3. v_chat_messages returns the attachment; v_my_chats and the
--      new-message notification say «📷 صورة» for a photo without text.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. The bucket and its policies
-- ---------------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'chat-attachments',
  'chat-attachments',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
  set public             = false,
      file_size_limit    = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- An active member uploads into their chat's folder, one level deep:
-- <chat id>/<file>.
drop policy if exists watad_chat_attachments_insert_member on storage.objects;
create policy watad_chat_attachments_insert_member
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'chat-attachments'
    and cardinality(storage.foldername(name)) = 1
    and (storage.foldername(name))[1] in (
      select c::text from private.my_chat_ids() as c
    )
    and position('..' in name) = 0
    and (select private.is_active_user())
  );

-- The chat's members read its photos (for signed URLs).
drop policy if exists watad_chat_attachments_select_member on storage.objects;
create policy watad_chat_attachments_select_member
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'chat-attachments'
    and (storage.foldername(name))[1] in (
      select c::text from private.my_chat_ids() as c
    )
  );

-- No update or delete policy: a sent photo stays as it was sent.

-- ---------------------------------------------------------------------
-- 2. Message columns
-- ---------------------------------------------------------------------

alter table public.messages
  add column attachment_path text,
  add column attachment_mime text;

comment on column public.messages.attachment_path is
  'A photo in the private chat-attachments bucket, at <chat id>/<file id>.<ext> inside this message''s chat. Shown through a signed URL.';
comment on column public.messages.attachment_mime is
  'The photo''s type: image/jpeg, image/png or image/webp. Set exactly when attachment_path is.';

alter table public.messages alter column content drop not null;

alter table public.messages drop constraint if exists messages_content_check;
alter table public.messages
  add constraint messages_content_check check (
    content is null or char_length(btrim(content)) between 1 and 4000
  );

-- Text, a photo, or both.
alter table public.messages
  add constraint messages_text_or_photo check (
    content is not null or attachment_path is not null
  );

-- The path and its type come together, and the type is a photo.
alter table public.messages
  add constraint messages_attachment_mime check (
    (attachment_path is null) = (attachment_mime is null)
    and (attachment_mime is null
         or attachment_mime in ('image/jpeg', 'image/png', 'image/webp'))
  );

-- Only inside this chat's own folder, so nobody can attach another chat's
-- photo: <chat id>/<file id>.<ext>.
alter table public.messages
  add constraint messages_attachment_in_chat_folder check (
    attachment_path is null
    or attachment_path ~ ('^' || chat_id::text || '/[A-Za-z0-9_-]{1,100}\.(jpe?g|png|webp)$')
  );

comment on table public.messages is
  'Insert-only. Post with insert {chat_id, content} and/or {attachment_path, attachment_mime}; sender_id is filled in from the session.';

grant insert (attachment_path, attachment_mime) on table public.messages to authenticated;

-- ---------------------------------------------------------------------
-- 3. Views and the notification
-- ---------------------------------------------------------------------

create or replace view public.v_chat_messages
with (security_invoker = true) as
select m.id,
       m.chat_id,
       m.sender_id,
       u.full_name as sender_name,
       u.avatar_path as sender_avatar_path,
       m.content,
       m.created_at,
       m.sender_id = (select auth.uid()) as is_mine,
       case
         when m.sender_id = (select auth.uid()) then
           not exists (
             select 1 from public.chat_members cm
              where cm.chat_id = m.chat_id
                and cm.user_id <> m.sender_id
                and (cm.last_read_at is null or cm.last_read_at < m.created_at))
         else
           exists (
             select 1 from public.chat_members cm
              where cm.chat_id = m.chat_id
                and cm.user_id = (select auth.uid())
                and cm.last_read_at >= m.created_at)
       end as is_read,
       m.attachment_path,
       m.attachment_mime
  from public.messages m
  join public.users u on u.id = m.sender_id;

create or replace view public.v_my_chats
with (security_invoker = true) as
select c.id,
       c.project_id,
       p.title as project_title,
       c.created_at,
       c.last_message_at,
       me.last_read_at,
       -- A photo without text reads «📷 صورة».
       case
         when lm.content is null and lm.attachment_path is not null then '📷 صورة'
         else lm.content
       end as last_message,
       lm.sender_id as last_message_sender_id,
       (select count(*)::integer
          from public.messages m
         where m.chat_id = c.id
           and m.sender_id <> (select auth.uid())
           and (me.last_read_at is null or m.created_at > me.last_read_at)) as unread_count,
       (select coalesce(
                 jsonb_agg(
                   jsonb_build_object('user_id', u.id, 'name', u.full_name,
                                      'avatar_path', u.avatar_path)
                   order by u.full_name),
                 '[]'::jsonb)
          from public.chat_members cm
          join public.users u on u.id = cm.user_id
         where cm.chat_id = c.id
           and cm.user_id <> (select auth.uid())) as other_members
  from public.chats c
  join public.chat_members me
    on me.chat_id = c.id and me.user_id = (select auth.uid())
  left join public.projects p on p.id = c.project_id
  left join lateral (
    select m.content, m.sender_id, m.attachment_path
      from public.messages m
     where m.chat_id = c.id
     order by m.created_at desc
     limit 1
  ) lm on true;

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
      coalesce(
        nullif(btrim(new.content), ''),
        case when new.attachment_path is not null then '📷 صورة' end,
        'رسالة جديدة'),
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
