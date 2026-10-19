-- =====================================================================
-- 12_chat_members.sql  ·  who is in each chat, and how far they've read
--
-- Review fixes here:
--   #3  the missing membership table. Read state lives here
--       (last_read_at) instead of messages.is_read, so nobody needs
--       UPDATE rights on messages, and it works in group chats.
-- =====================================================================

create table public.chat_members (
  chat_id      uuid not null references public.chats (id) on delete cascade,
  user_id      uuid not null references public.users (id) on delete restrict,
  joined_at    timestamptz not null default now(),
  last_read_at timestamptz,
  primary key (chat_id, user_id)
);

comment on table public.chat_members is
  'Membership + read position. Changed only by start_chat(), add/remove_chat_member() and mark_chat_read().';

create index chat_members_user_id_idx on public.chat_members (user_id);

-- ---------------------------------------------------------------------
-- RPC
-- ---------------------------------------------------------------------

-- markAsRead(): everything in the chat up to now counts as read.
create or replace function public.mark_chat_read(p_chat_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_active_user();
begin
  update public.chat_members
     set last_read_at = now()
   where chat_id = p_chat_id and user_id = v_uid;
  if not found then
    raise exception 'Chat not found' using errcode = 'P0002';
  end if;
end;
$$;

revoke all on function public.mark_chat_read(uuid) from public, anon;
grant execute on function public.mark_chat_read(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- Row level security (read-only for clients)
-- ---------------------------------------------------------------------
alter table public.chat_members enable row level security;

-- Members can see who else is in their chats.
create policy chat_members_select
  on public.chat_members for select
  to authenticated
  using (chat_id in (select private.my_chat_ids()) or (select private.is_admin()));

revoke all on table public.chat_members from anon, authenticated;
grant select on table public.chat_members to authenticated;
;
