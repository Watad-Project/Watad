-- =====================================================================
-- 79_task_update_rejection_photos.sql  ·  pictures with a rejected task update (GRA-51)
--
-- Feature (GRA-51; the contractor reads it in GRA-39): when the client
-- rejects a contractor's «منجزة» update, they can attach up to 3 pictures
-- that show what's wrong.
--   1. project_task_updates.rejection_photo_paths: up to 3 paths in the
--      private "task-evidence" bucket, inside the deciding client's own
--      folder; only on a rejected update, '{}' otherwise.
--   2. decide_task_update() gains p_rejection_photo_paths (default '{}'),
--      taken only with 'rejected'; each photo must already be uploaded.
--      The 4-argument function is dropped first, so PostgREST keeps one
--      decide_task_update; calls with the 4 named arguments still work.
--   3. "task-evidence" upload policy: the project's owner may also upload,
--      into their own folder, while the project is in progress.
--   4. private.can_read_task_evidence(): rejection photos are readable by
--      the project's owner and taker (and admins), like evidence photos.
--   5. v_project_task_updates: adds rejection_photo_paths at the end.
-- Error codes as in migration 72 (APP_ARCHITECTURE.md §13).
-- Off-chain: updates and their photos are never synced (golden rule 5).
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Column and checks
-- ---------------------------------------------------------------------

alter table public.project_task_updates
  add column if not exists rejection_photo_paths text[] not null default '{}';

comment on column public.project_task_updates.rejection_photo_paths is
  'Up to 3 pictures the client attached when rejecting, in the private task-evidence bucket, inside the client''s own folder.';

-- At most 3, and only on a rejected update.
alter table public.project_task_updates
  drop constraint if exists project_task_updates_rejection_photos_count;
alter table public.project_task_updates
  add constraint project_task_updates_rejection_photos_count check (
    cardinality(rejection_photo_paths) <= 3
    and (decision = 'rejected' or cardinality(rejection_photo_paths) = 0)
  );

-- Inside the folder of the client who decided (decided_by is the project's
-- owner), so nobody can attach someone else's file.
alter table public.project_task_updates
  drop constraint if exists project_task_updates_rejection_photos_in_decider_folder;
alter table public.project_task_updates
  add constraint project_task_updates_rejection_photos_in_decider_folder check (
    cardinality(rejection_photo_paths) = 0
    or (
      decided_by is not null
      and private.paths_in_user_folder(rejection_photo_paths, decided_by)
    )
  );

-- ---------------------------------------------------------------------
-- 2. decide_task_update(): the rejection's photos
-- ---------------------------------------------------------------------

-- A new parameter is a new signature: drop the old one first, or PostgREST
-- would find two candidates for a call with 4 named arguments.
drop function if exists public.decide_task_update(uuid, public.task_update_decision, text, text);

create function public.decide_task_update(
  p_update_id             uuid,
  p_decision              public.task_update_decision,
  p_rejection_reason      text default null,
  p_rejection_details     text default null,
  p_rejection_photo_paths text[] default '{}'
)
returns void
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_uid     uuid := private.require_active_user();
  v_update  public.project_task_updates;
  v_task    public.project_tasks;
  v_project public.projects;
  v_reason  text := nullif(btrim(p_rejection_reason), '');
  v_details text := nullif(btrim(p_rejection_details), '');
  v_photos  text[] := coalesce(p_rejection_photo_paths, '{}');
  v_photo   text;
begin
  if p_update_id is null or p_decision is null or p_decision not in ('accepted', 'rejected') then
    raise exception 'invalid_decision' using errcode = '22023';
  end if;

  select * into v_update from public.project_task_updates where id = p_update_id;
  if not found then
    raise exception 'task_update_not_found' using errcode = 'P0002';
  end if;

  -- Lock in consistent order: project -> task -> update.
  select * into v_project from public.projects where id = v_update.project_id for update;
  select * into v_task from public.project_tasks where id = v_update.task_id for update;
  select * into v_update from public.project_task_updates where id = p_update_id for update;

  if v_uid <> v_project.owner_id and v_uid is distinct from v_project.taker_id then
    raise exception 'task_update_not_found' using errcode = 'P0002';
  end if;

  if v_uid <> v_project.owner_id then
    raise exception 'only_owner_can_decide_task_update' using errcode = '42501';
  end if;

  if v_project.status <> 'in_progress' then
    raise exception 'project_not_in_progress' using errcode = '40001';
  end if;

  if v_update.decision <> 'pending' then
    raise exception 'task_update_already_decided' using errcode = '40001';
  end if;

  if p_decision = 'rejected' then
    if v_reason is null or char_length(v_reason) > 200 then
      raise exception 'rejection_reason_required' using errcode = '22023';
    end if;
    if v_details is not null and char_length(v_details) > 1000 then
      raise exception 'rejection_details_too_long' using errcode = '22023';
    end if;
    if cardinality(v_photos) > 3 then
      raise exception 'too_many_photos' using errcode = '22023';
    end if;
    if not private.paths_in_user_folder(v_photos, v_uid) then
      raise exception 'invalid_rejection_photo_path' using errcode = '22023';
    end if;
    foreach v_photo in array v_photos loop
      if not exists (
        select 1 from storage.objects o
         where o.bucket_id = 'task-evidence'
           and o.name = v_photo
      ) then
        raise exception 'rejection_photo_not_uploaded' using errcode = '22023';
      end if;
    end loop;
  else
    if cardinality(v_photos) > 0 then
      raise exception 'rejection_photos_only_when_rejected' using errcode = '22023';
    end if;
    v_reason := null;
    v_details := null;
  end if;

  update public.project_task_updates
     set decision              = p_decision,
         rejection_reason      = v_reason,
         rejection_details     = v_details,
         rejection_photo_paths = v_photos,
         decided_by            = v_uid,
         decided_at            = now()
   where id = p_update_id;

  if p_decision = 'accepted' then
    if v_task.status <> 'done' then
      raise exception 'task_not_done' using errcode = '40001';
    end if;

    perform set_config('app.status_note', 'task update accepted', true);

    update public.project_tasks
       set status     = 'approved',
           decided_at = now()
     where id = v_task.id;

    if v_task.amount is not null then
      update public.project_tasks
         set payment_id = public.add_payment_stage(v_project.id, v_task.amount, v_task.title)
       where id = v_task.id;
    end if;
  else
    perform set_config('app.status_note', 'task update rejected: ' || v_reason, true);

    update public.project_tasks
       set status      = 'accepted',
           finish_date = null,
           decided_at  = now()
     where id = v_task.id;
  end if;
end;
$$;

revoke all on function public.decide_task_update(uuid, public.task_update_decision, text, text, text[]) from public, anon;
grant execute on function public.decide_task_update(uuid, public.task_update_decision, text, text, text[]) to authenticated;

-- ---------------------------------------------------------------------
-- 3. Storage: the project's owner uploads rejection photos too
-- ---------------------------------------------------------------------

drop policy if exists watad_task_evidence_insert_own on storage.objects;

-- An active contractor or client on an in-progress project uploads into
-- their own folder only.
create policy watad_task_evidence_insert_own
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'task-evidence'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and position('..' in name) = 0
    and (select private.is_active_user())
    and exists (
      select 1 from public.projects p
      where (p.taker_id = (select auth.uid()) or p.owner_id = (select auth.uid()))
        and p.status = 'in_progress'
    )
  );

-- ---------------------------------------------------------------------
-- 4. Storage: rejection photos read like evidence photos
-- ---------------------------------------------------------------------

create or replace function private.can_read_task_evidence(p_object_name text)
returns boolean
language sql
stable
security definer
set search_path to ''
as $$
  select private.is_admin()
      or (storage.foldername(p_object_name))[1] = (select auth.uid())::text
      or exists (
        select 1
          from public.project_task_updates u
          join public.projects p on p.id = u.project_id
         where (p_object_name = any (u.photo_paths)
                or p_object_name = any (u.rejection_photo_paths))
           and (p.owner_id = (select auth.uid()) or p.taker_id = (select auth.uid()))
      );
$$;

revoke all on function private.can_read_task_evidence(text) from public;
grant execute on function private.can_read_task_evidence(text) to authenticated;

-- ---------------------------------------------------------------------
-- 5. View: v_project_task_updates gets rejection_photo_paths at the end
-- ---------------------------------------------------------------------

create or replace view public.v_project_task_updates
with (security_invoker = true) as
select u.id,
       u.task_id,
       t.title  as task_title,
       t.amount as task_amount,
       t.status as task_status,
       u.project_id,
       p.title  as project_title,
       u.author_id,
       u.proposed_state,
       u.note,
       u.photo_paths,
       u.decision,
       u.rejection_reason,
       u.rejection_details,
       u.decided_by,
       u.decided_at,
       u.created_at,
       u.updated_at,
       t.payment_id,
       case
         when u.decision = 'accepted'::public.task_update_decision
          and u.proposed_state = 'done'::public.task_update_state
         then pp.amount
         else null::numeric
       end as payment_amount,
       case
         when p.owner_id = (select auth.uid()) then 'owner'::text
         when p.taker_id = (select auth.uid()) then 'taker'::text
         else null::text
       end as my_role,
       u.rejection_photo_paths
  from public.project_task_updates u
  join public.project_tasks t on t.id = u.task_id
  join public.projects p on p.id = u.project_id
  left join public.project_payments pp on pp.id = t.payment_id;

comment on view public.v_project_task_updates is
  'Task updates with task and project titles, evidence photo paths, decision, reason and rejection photo paths, payment amount and caller role.';

revoke all on public.v_project_task_updates from public, anon, authenticated;
grant select on public.v_project_task_updates to authenticated;
grant all on public.v_project_task_updates to service_role;
