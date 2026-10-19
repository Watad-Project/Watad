-- =====================================================================
-- 13_messages.sql  ·  chat messages
--
-- Review fixes here:
--   #3  only members of a chat can read or post in it. Messages are
--       immutable: there is no UPDATE right at all, so nobody can edit
--       someone else's content. Read receipts come from
--       chat_members.last_read_at (see v_chat_messages).
--   #4  sender_id is always the signed-in user.
--   #8  ON DELETE RESTRICT: a chat with messages can't be deleted.
-- =====================================================================

create table public.messages (
  id         uuid primary key default gen_random_uuid(),
  chat_id    uuid not null references public.chats (id) on delete restrict,
  sender_id  uuid not null default auth.uid()
             references public.users (id) on delete restrict,
  content    text not null check (char_length(btrim(content)) between 1 and 4000),
  created_at timestamptz not null default now()
);

comment on table public.messages is
  'Insert-only. Post with insert {chat_id, content}; sender_id is filled in from the session.';

create index messages_chat_id_created_at_idx on public.messages (chat_id, created_at desc);
create index messages_sender_id_idx on public.messages (sender_id);

-- Keep chats.last_message_at current for the chat list.
create or replace function private.messages_touch_chat()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.chats
     set last_message_at = new.created_at
   where id = new.chat_id;
  return new;
end;
$$;

revoke all on function private.messages_touch_chat() from public;

create trigger messages_touch_chat
  after insert on public.messages
  for each row execute function private.messages_touch_chat();

-- ---------------------------------------------------------------------
-- Row level security + column grants
-- ---------------------------------------------------------------------
alter table public.messages enable row level security;

create policy messages_select_members
  on public.messages for select
  to authenticated
  using (chat_id in (select private.my_chat_ids()));

create policy messages_insert_members
  on public.messages for insert
  to authenticated
  with check (
    sender_id = (select auth.uid())
    and chat_id in (select private.my_chat_ids())
    and (select private.is_active_user())
  );

revoke all on table public.messages from anon, authenticated;
grant select on table public.messages to authenticated;
grant insert (chat_id, content) on table public.messages to authenticated;

-- Live chat: Realtime delivers new rows only to members (it applies
-- the select policy above for each subscriber).
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select 1 from pg_publication_tables
       where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'messages'
     ) then
    alter publication supabase_realtime add table public.messages;
  end if;
end;
$$;
;
