-- =====================================================================
-- 31_v_my_chats.sql  ·  VIEW: the chat list
--
-- App: supabase.from('v_my_chats').select()
--        .order('last_message_at', ascending: false, nullsFirst: false)
-- other_members is a JSON array of {user_id, name, avatar_path}.
-- =====================================================================

create view public.v_my_chats
with (security_invoker = true)
as
select
  c.id,
  c.project_id,
  p.title as project_title,
  c.created_at,
  c.last_message_at,
  me.last_read_at,
  lm.content as last_message,
  lm.sender_id as last_message_sender_id,
  (
    select count(*)::integer
    from public.messages m
    where m.chat_id = c.id
      and m.sender_id <> (select auth.uid())
      and (me.last_read_at is null or m.created_at > me.last_read_at)
  ) as unread_count,
  (
    select coalesce(
             jsonb_agg(jsonb_build_object('user_id', u.id, 'name', u.full_name, 'avatar_path', u.avatar_path)
                       order by u.full_name),
             '[]'::jsonb)
    from public.chat_members cm
    join public.users u on u.id = cm.user_id
    where cm.chat_id = c.id
      and cm.user_id <> (select auth.uid())
  ) as other_members
from public.chats c
join public.chat_members me
  on me.chat_id = c.id
 and me.user_id = (select auth.uid())
left join public.projects p on p.id = c.project_id
left join lateral (
  select m.content, m.sender_id
  from public.messages m
  where m.chat_id = c.id
  order by m.created_at desc
  limit 1
) lm on true;

comment on view public.v_my_chats is 'Caller''s chats with last message, unread count and the other members.';

revoke all on table public.v_my_chats from anon, authenticated;
grant select on table public.v_my_chats to authenticated;
;
