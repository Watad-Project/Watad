-- =====================================================================
-- 11_chats.sql  ·  conversations (optionally about a project)
--
-- Review fixes here:
--   #3  chats now have real members (chat_members, file 12). A chat and
--       its messages are visible only to its members, and membership is
--       changed only through the RPCs below.
--   #8  ON DELETE RESTRICT to the project.
--   #13 timestamps.
-- =====================================================================

create table public.chats (
  id              uuid primary key default gen_random_uuid(),
  -- Context project (0..1). Null = a direct chat, e.g. buyer and seller.
  project_id      uuid references public.projects (id) on delete restrict,
  created_by      uuid not null references public.users (id) on delete restrict,
  last_message_at timestamptz,
  created_at      timestamptz not null default now()
);

comment on table public.chats is
  'Visible to members only. Create with start_chat(); manage members with add_chat_member()/remove_chat_member().';

create index chats_project_id_idx on public.chats (project_id);
create index chats_created_by_idx on public.chats (created_by);

-- ---------------------------------------------------------------------
-- Helpers (chat_members is created in file 12; plpgsql looks it up at
-- run time. SECURITY DEFINER avoids an RLS loop on chat_members.)
-- ---------------------------------------------------------------------
create or replace function private.my_chat_ids()
returns setof uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  return query
    select m.chat_id
    from public.chat_members m
    where m.user_id = (select auth.uid());
end;
$$;

-- Find or create the two-person chat for (a, b, project).
create or replace function private.ensure_chat(p_user_a uuid, p_user_b uuid, p_project_id uuid default null)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_chat uuid;
begin
  -- Two taps at once still make one chat.
  perform pg_advisory_xact_lock(hashtextextended(
    least(p_user_a, p_user_b)::text || greatest(p_user_a, p_user_b)::text
      || coalesce(p_project_id::text, '-'), 0));

  select m1.chat_id into v_chat
  from public.chat_members m1
  join public.chat_members m2 on m2.chat_id = m1.chat_id and m2.user_id = p_user_b
  join public.chats c on c.id = m1.chat_id
  where m1.user_id = p_user_a
    and c.project_id is not distinct from p_project_id
    and (select count(*) from public.chat_members m where m.chat_id = m1.chat_id) = 2
  order by c.created_at
  limit 1;

  if v_chat is null then
    insert into public.chats (project_id, created_by)
    values (p_project_id, p_user_a)
    returning id into v_chat;
    insert into public.chat_members (chat_id, user_id)
    values (v_chat, p_user_a), (v_chat, p_user_b);
  end if;
  return v_chat;
end;
$$;

revoke all on function private.my_chat_ids() from public;
revoke all on function private.ensure_chat(uuid, uuid, uuid) from public;
grant execute on function private.my_chat_ids() to authenticated, service_role;

-- ---------------------------------------------------------------------
-- RPCs
-- ---------------------------------------------------------------------

-- Open (or reopen) a chat with someone. With p_project_id, one side must
-- be the project owner and the other its taker, a bidder, or (while the
-- project is open) a verified business asking a question.
create or replace function public.start_chat(p_other_user_id uuid, p_project_id uuid default null)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid     uuid := private.require_active_user();
  v_project public.projects;
  v_partner uuid;
begin
  if p_other_user_id is null or p_other_user_id = v_uid then
    raise exception 'Pick someone else to chat with' using errcode = '22023';
  end if;
  if not exists (select 1 from public.users where id = p_other_user_id and deleted_at is null) then
    raise exception 'User not found' using errcode = 'P0002';
  end if;

  if p_project_id is not null then
    select * into v_project from public.projects where id = p_project_id;
    if not found then
      raise exception 'Project not found' using errcode = 'P0002';
    end if;
    if v_project.owner_id = v_uid then
      v_partner := p_other_user_id;
    elsif v_project.owner_id = p_other_user_id then
      v_partner := v_uid;
    else
      raise exception 'A project chat must include the project owner' using errcode = '42501';
    end if;
    if not (
         v_partner = v_project.taker_id
      or exists (select 1 from public.project_offers o
                 where o.project_id = p_project_id and o.provider_id = v_partner)
      or (v_project.status = 'open' and v_partner = v_uid and private.is_verified_business(v_uid))
    ) then
      raise exception 'You can only open a project chat with its taker or a business that bid on it'
        using errcode = '42501';
    end if;
  end if;

  return private.ensure_chat(v_uid, p_other_user_id, p_project_id);
end;
$$;

-- addMember(user_id): the chat's creator adds someone.
create or replace function public.add_chat_member(p_chat_id uuid, p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_active_user();
begin
  if not exists (
    select 1 from public.chats c
    join public.chat_members m on m.chat_id = c.id and m.user_id = v_uid
    where c.id = p_chat_id and c.created_by = v_uid
  ) then
    raise exception 'Only the chat''s creator can add members' using errcode = '42501';
  end if;
  if not exists (select 1 from public.users where id = p_user_id and deleted_at is null) then
    raise exception 'User not found' using errcode = 'P0002';
  end if;
  insert into public.chat_members (chat_id, user_id)
  values (p_chat_id, p_user_id)
  on conflict (chat_id, user_id) do nothing;
end;
$$;

-- removeMember(user_id): anyone can leave; the creator can remove
-- others, but never a project chat's owner or taker.
create or replace function public.remove_chat_member(p_chat_id uuid, p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid  uuid := private.require_active_user();
  v_chat public.chats;
begin
  select * into v_chat from public.chats where id = p_chat_id;
  if not found or not exists (
    select 1 from public.chat_members where chat_id = p_chat_id and user_id = v_uid
  ) then
    raise exception 'Chat not found' using errcode = 'P0002';
  end if;
  if p_user_id <> v_uid then
    if v_chat.created_by <> v_uid then
      raise exception 'Only the chat''s creator can remove other members' using errcode = '42501';
    end if;
    if v_chat.project_id is not null and exists (
      select 1 from public.projects p
      where p.id = v_chat.project_id and p_user_id in (p.owner_id, p.taker_id)
    ) then
      raise exception 'The project owner and taker can''t be removed from the project chat' using errcode = '42501';
    end if;
  end if;
  delete from public.chat_members where chat_id = p_chat_id and user_id = p_user_id;
  if not found then
    raise exception 'That user is not in this chat' using errcode = 'P0002';
  end if;
end;
$$;

revoke all on function public.start_chat(uuid, uuid) from public, anon;
revoke all on function public.add_chat_member(uuid, uuid) from public, anon;
revoke all on function public.remove_chat_member(uuid, uuid) from public, anon;
grant execute on function public.start_chat(uuid, uuid) to authenticated;
grant execute on function public.add_chat_member(uuid, uuid) to authenticated;
grant execute on function public.remove_chat_member(uuid, uuid) to authenticated;

-- ---------------------------------------------------------------------
-- Row level security (read-only for clients)
-- ---------------------------------------------------------------------
alter table public.chats enable row level security;

create policy chats_select_members
  on public.chats for select
  to authenticated
  using (id in (select private.my_chat_ids()) or (select private.is_admin()));

revoke all on table public.chats from anon, authenticated;
grant select on table public.chats to authenticated;
;
