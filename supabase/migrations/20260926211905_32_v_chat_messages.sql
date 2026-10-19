-- =====================================================================
-- 32_v_chat_messages.sql  ·  VIEW: messages of one chat
--
-- App: supabase.from('v_chat_messages').select().eq('chat_id', chatId)
--        .order('created_at', ascending: false).limit(50)
-- Send:  supabase.from('messages').insert({'chat_id': chatId, 'content': text})
-- Read:  supabase.rpc('mark_chat_read', params: {'p_chat_id': chatId})
-- is_read: for my messages, every other member has read them; for
-- other people's messages, I have.
-- =====================================================================

create view public.v_chat_messages
with (security_invoker = true)
as
select
  m.id,
  m.chat_id,
  m.sender_id,
  u.full_name as sender_name,
  u.avatar_path as sender_avatar_path,
  m.content,
  m.created_at,
  (m.sender_id = (select auth.uid())) as is_mine,
  case
    when m.sender_id = (select auth.uid()) then not exists (
      select 1 from public.chat_members cm
      where cm.chat_id = m.chat_id
        and cm.user_id <> m.sender_id
        and (cm.last_read_at is null or cm.last_read_at < m.created_at)
    )
    else exists (
      select 1 from public.chat_members cm
      where cm.chat_id = m.chat_id
        and cm.user_id = (select auth.uid())
        and cm.last_read_at >= m.created_at
    )
  end as is_read
from public.messages m
join public.users u on u.id = m.sender_id;

comment on view public.v_chat_messages is 'Messages in the caller''s chats with sender name/avatar and read state.';

revoke all on table public.v_chat_messages from anon, authenticated;
grant select on table public.v_chat_messages to authenticated;
;
