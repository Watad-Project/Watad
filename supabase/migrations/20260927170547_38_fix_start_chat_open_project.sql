-- =====================================================================
-- 38_fix_start_chat_open_project.sql
--
-- Bug (scenario 22, medium): while a project was open, any signed-in
-- user could open a chat with its owner about it (unverified businesses
-- and normal clients included).
--
-- Why: taker_id is null on an open project, so "v_partner = taker_id"
-- was null; with the other two conditions false the whole check was
-- null, "not null" is still null, and "if null" never raises.
--
-- Replaces the definition in 11_chats.sql; grants are unchanged.
-- =====================================================================

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
         -- FIX: compare with the taker only when there is one.
         (v_project.taker_id is not null and v_partner = v_project.taker_id)
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
;
