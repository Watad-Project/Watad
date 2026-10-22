-- =====================================================================
-- 70_task_updates.sql  ·  task updates, evidence photos and client decisions (GRA-40)
--
-- Feature (GRA-37, GRA-39, GRA-40, GRA-41, GRA-42):
--   1. public.task_update_state ('in_progress', 'done') and
--      public.task_update_decision ('pending', 'accepted', 'rejected').
--   2. public.project_task_updates: one row per update the contractor
--      sends on an accepted task, with optional note and up to 3 evidence
--      photos in the private "task-evidence" bucket (at least 1 required
--      for 'done'). At most one 'pending' update per task at a time.
--      Readable by the project's owner, its taker and admins; written only
--      by RPCs; published to Supabase Realtime for live status cards.
--   3. Private storage bucket "task-evidence": JPEG, PNG or WebP images up
--      to 10 MB. The contractor uploads into "<own user id>/<file>"; the
--      project's owner, its taker and admins can read.
--   4. submit_task_update(): contractor sends an 'in_progress' update
--      (recorded immediately as 'accepted') or a 'done' update (recorded
--      as 'pending' and moves the task accepted -> done in the same
--      transaction).
--   5. decide_task_update(): client accepts a pending 'done' update (moves
--      the task done -> approved and schedules a payment stage when the
--      task has an amount) or rejects it with a reason and optional
--      details (moves the task done -> accepted).
--   6. Error codes from APP_ARCHITECTURE.md §13 (42501, P0002, 40001,
--      22023) on submit_task_update(), decide_task_update() and
--      set_task_status().
--   7. Views:
--      - v_project_task_updates: update details, task/project titles,
--        payment amount and my_role.
--      - v_project_tasks: adds last_update_id, last_update_proposed_state,
--        last_update_decision, last_update_at and has_pending_update.
--      - v_my_projects: adds photo_paths for the schedule header.
--   8. Notifications (GRA-32): notifies the client when an update is sent
--      and the contractor when the client decides.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Enums and path helper
-- ---------------------------------------------------------------------

do $$
begin
  if not exists (select 1 from pg_type where typname = 'task_update_state') then
    create type public.task_update_state as enum ('in_progress', 'done');
  end if;
  if not exists (select 1 from pg_type where typname = 'task_update_decision') then
    create type public.task_update_decision as enum ('pending', 'accepted', 'rejected');
  end if;
end $$;

-- Checks that every storage path in p_paths is inside "<p_user_id>/" without "..".
create or replace function private.paths_in_user_folder(p_paths text[], p_user_id uuid)
returns boolean
language sql
immutable
set search_path to ''
as $$
  select coalesce(
    (
      select bool_and(
        p is not null
        and btrim(p) <> ''
        and p like (p_user_id::text || '/%')
        and position('..' in p) = 0
      )
      from unnest(p_paths) as p
    ),
    true
  );
$$;

revoke all on function private.paths_in_user_folder(text[], uuid) from public;

-- ---------------------------------------------------------------------
-- 2. Table: public.project_task_updates
-- ---------------------------------------------------------------------

create table if not exists public.project_task_updates (
  id                uuid primary key default gen_random_uuid(),
  task_id           uuid not null references public.project_tasks (id) on delete restrict,
  project_id        uuid not null references public.projects (id) on delete restrict,
  author_id         uuid not null default auth.uid()
                    references public.businesses (user_id) on delete restrict,
  proposed_state    public.task_update_state not null,
  note              text check (note is null or char_length(btrim(note)) between 1 and 5000),
  photo_paths       text[] not null default '{}',
  decision          public.task_update_decision not null default 'pending',
  rejection_reason  text check (rejection_reason is null or char_length(btrim(rejection_reason)) between 1 and 200),
  rejection_details text check (rejection_details is null or char_length(btrim(rejection_details)) between 1 and 1000),
  decided_by        uuid references public.users (id) on delete restrict,
  decided_at        timestamptz,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  constraint project_task_updates_photos_count check (
    cardinality(photo_paths) <= 3
    and (proposed_state <> 'done' or cardinality(photo_paths) >= 1)
  ),
  constraint project_task_updates_photos_in_author_folder check (
    private.paths_in_user_folder(photo_paths, author_id)
  ),
  constraint project_task_updates_decided_check check (
    (decision = 'pending') = (decided_at is null)
  ),
  constraint project_task_updates_rejection_check check (
    (decision = 'rejected') = (rejection_reason is not null)
    and (decision = 'rejected' or rejection_details is null)
  ),
  constraint project_task_updates_in_progress_decision check (
    proposed_state = 'done' or decision = 'accepted'
  )
);

comment on table public.project_task_updates is
  'Task progress and completion updates sent by the contractor. Written only by submit_task_update() and decide_task_update().';

-- At most one pending update per task at a time.
create unique index if not exists project_task_updates_one_pending_idx
  on public.project_task_updates (task_id)
  where decision = 'pending';

create index if not exists project_task_updates_task_id_idx
  on public.project_task_updates (task_id, created_at desc);

create index if not exists project_task_updates_project_id_idx
  on public.project_task_updates (project_id, created_at desc);

create index if not exists project_task_updates_author_id_idx
  on public.project_task_updates (author_id);

drop trigger if exists project_task_updates_set_updated_at on public.project_task_updates;
create trigger project_task_updates_set_updated_at
  before update on public.project_task_updates
  for each row execute function private.set_updated_at();

alter table public.project_task_updates enable row level security;

drop policy if exists project_task_updates_select on public.project_task_updates;
create policy project_task_updates_select
  on public.project_task_updates for select
  to authenticated
  using (
    (select private.is_admin())
    or exists (
      select 1 from public.projects p
      where p.id = project_task_updates.project_id
        and (p.owner_id = (select auth.uid()) or p.taker_id = (select auth.uid()))
    )
  );

-- Read-only for the app: nobody inserts or updates directly.
revoke all on table public.project_task_updates from public, anon, authenticated;
grant select on table public.project_task_updates to authenticated;

-- Live updates for the status screen (GRA-39).
do $$
begin
  if not exists (
    select 1
      from pg_publication_tables
     where pubname = 'supabase_realtime'
       and schemaname = 'public'
       and tablename = 'project_task_updates'
  ) then
    alter publication supabase_realtime add table public.project_task_updates;
  end if;
end $$;

-- ---------------------------------------------------------------------
-- 3. Private storage bucket: task-evidence
-- ---------------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'task-evidence',
  'task-evidence',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
  set public             = false,
      file_size_limit    = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

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
         where p_object_name = any (u.photo_paths)
           and (p.owner_id = (select auth.uid()) or p.taker_id = (select auth.uid()))
      );
$$;

revoke all on function private.can_read_task_evidence(text) from public;
grant execute on function private.can_read_task_evidence(text) to authenticated;

drop policy if exists watad_task_evidence_insert_own on storage.objects;
drop policy if exists watad_task_evidence_select on storage.objects;

-- An active contractor on an in-progress project uploads into their own folder only.
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
      where p.taker_id = (select auth.uid())
        and p.status = 'in_progress'
    )
  );

-- The uploader, the project's owner, its taker and admins may read evidence photos.
create policy watad_task_evidence_select
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'task-evidence'
    and private.can_read_task_evidence(name)
  );

-- ---------------------------------------------------------------------
-- 4. RPCs: submit_task_update, decide_task_update, and set_task_status
-- ---------------------------------------------------------------------

-- Contractor sends an update on an accepted task.
create or replace function public.submit_task_update(
  p_task_id        uuid,
  p_proposed_state public.task_update_state,
  p_note           text default null,
  p_photo_paths    text[] default '{}'
)
returns uuid
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_uid       uuid := private.require_active_user();
  v_task      public.project_tasks;
  v_project   public.projects;
  v_note      text := nullif(btrim(p_note), '');
  v_photos    text[] := coalesce(p_photo_paths, '{}');
  v_photo     text;
  v_today     date := (now() at time zone 'Asia/Riyadh')::date;
  v_update_id uuid;
begin
  if p_task_id is null or p_proposed_state is null then
    raise exception 'task_id and proposed_state are required' using errcode = '22023';
  end if;

  select * into v_task from public.project_tasks where id = p_task_id for update;
  if not found then
    raise exception 'task_not_found' using errcode = 'P0002';
  end if;

  select * into v_project from public.projects where id = v_task.project_id for update;
  if v_uid <> v_project.owner_id and v_uid is distinct from v_project.taker_id then
    raise exception 'task_not_found' using errcode = 'P0002';
  end if;

  if v_uid is distinct from v_project.taker_id then
    raise exception 'only_taker_can_submit_task_update' using errcode = '42501';
  end if;

  if v_project.status <> 'in_progress' then
    raise exception 'project_not_in_progress' using errcode = '40001';
  end if;

  if v_task.status <> 'accepted' then
    raise exception 'task_not_accepted' using errcode = '40001';
  end if;

  if exists (
    select 1 from public.project_task_updates
     where task_id = p_task_id and decision = 'pending'
  ) then
    raise exception 'task_update_already_pending' using errcode = '40001';
  end if;

  if v_note is not null and char_length(v_note) > 5000 then
    raise exception 'note_too_long' using errcode = '22023';
  end if;

  if cardinality(v_photos) > 3 then
    raise exception 'too_many_photos' using errcode = '22023';
  end if;

  if p_proposed_state = 'done' and cardinality(v_photos) < 1 then
    raise exception 'evidence_photo_required_for_done' using errcode = '22023';
  end if;

  if not private.paths_in_user_folder(v_photos, v_uid) then
    raise exception 'invalid_evidence_photo_path' using errcode = '22023';
  end if;

  foreach v_photo in array v_photos loop
    if not exists (
      select 1 from storage.objects o
       where o.bucket_id = 'task-evidence'
         and o.name = v_photo
    ) then
      raise exception 'evidence_photo_not_uploaded' using errcode = '22023';
    end if;
  end loop;

  if p_proposed_state = 'done' and v_task.start_date is not null and v_task.start_date > v_today then
    raise exception 'task_cannot_finish_before_start_date' using errcode = '22023';
  end if;

  if p_proposed_state = 'done' then
    insert into public.project_task_updates (
      task_id, project_id, author_id, proposed_state, note, photo_paths, decision
    )
    values (
      v_task.id, v_project.id, v_uid, 'done', v_note, v_photos, 'pending'
    )
    returning id into v_update_id;

    perform set_config('app.status_note', 'task update submitted (done)', true);

    update public.project_tasks
       set status      = 'done',
           start_date  = coalesce(start_date, (decided_at at time zone 'Asia/Riyadh')::date, v_today),
           finish_date = v_today
     where id = v_task.id;
  else
    insert into public.project_task_updates (
      task_id, project_id, author_id, proposed_state, note, photo_paths,
      decision, decided_by, decided_at
    )
    values (
      v_task.id, v_project.id, v_uid, 'in_progress', v_note, v_photos,
      'accepted', v_uid, now()
    )
    returning id into v_update_id;
  end if;

  return v_update_id;
end;
$$;

revoke all on function public.submit_task_update(uuid, public.task_update_state, text, text[]) from public, anon;
grant execute on function public.submit_task_update(uuid, public.task_update_state, text, text[]) to authenticated;

-- Client accepts or rejects a pending task update.
create or replace function public.decide_task_update(
  p_update_id         uuid,
  p_decision          public.task_update_decision,
  p_rejection_reason  text default null,
  p_rejection_details text default null
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
  else
    v_reason := null;
    v_details := null;
  end if;

  update public.project_task_updates
     set decision          = p_decision,
         rejection_reason  = v_reason,
         rejection_details = v_details,
         decided_by        = v_uid,
         decided_at        = now()
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

revoke all on function public.decide_task_update(uuid, public.task_update_decision, text, text) from public, anon;
grant execute on function public.decide_task_update(uuid, public.task_update_decision, text, text) to authenticated;

-- Update set_task_status() to use APP_ARCHITECTURE.md §13 error codes
-- (42501, P0002, 40001, 22023) and keep pending task updates consistent.
create or replace function public.set_task_status(p_task_id uuid, p_status public.task_status)
returns void
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_uid     uuid := private.require_active_user();
  v_task    public.project_tasks;
  v_project public.projects;
  v_today   date := (now() at time zone 'Asia/Riyadh')::date;
begin
  select * into v_task from public.project_tasks where id = p_task_id for update;
  if not found then
    raise exception 'Task not found' using errcode = 'P0002';
  end if;
  select * into v_project from public.projects where id = v_task.project_id for update;
  if v_uid <> v_project.owner_id and v_uid is distinct from v_project.taker_id then
    raise exception 'Task not found' using errcode = 'P0002';
  end if;
  if v_project.status <> 'in_progress' then
    raise exception 'Tasks can only change while the project is in progress' using errcode = '40001';
  end if;
  if (v_uid = v_project.owner_id and p_status = 'done')
     or (v_uid = v_project.taker_id and p_status in ('accepted', 'rejected', 'approved')) then
    raise exception 'You are not allowed to set this task status' using errcode = '42501';
  end if;
  if not (
       (v_uid = v_project.owner_id and v_task.status = 'proposed' and p_status in ('accepted', 'rejected'))
    or (v_uid = v_project.taker_id and v_task.status = 'accepted' and p_status = 'done')
    or (v_uid = v_project.owner_id and v_task.status = 'done' and p_status in ('approved', 'accepted'))
  ) then
    raise exception 'You can''t move this task from % to %', v_task.status, p_status using errcode = '40001';
  end if;
  if p_status = 'done' and v_task.start_date is not null and v_task.start_date > v_today then
    raise exception 'A task can''t be finished before its start date' using errcode = '22023';
  end if;

  update public.project_tasks
     set status      = p_status,
         start_date  = case when p_status = 'done'
                            then coalesce(start_date, (decided_at at time zone 'Asia/Riyadh')::date, v_today)
                            else start_date end,
         finish_date = case when p_status = 'done' then v_today
                            when p_status = 'accepted' and v_task.status = 'done' then null
                            else finish_date end,
         decided_at  = case when p_status in ('accepted', 'rejected', 'approved') then now() else decided_at end
   where id = p_task_id;

  if p_status = 'approved' and v_task.amount is not null then
    update public.project_tasks
       set payment_id = public.add_payment_stage(v_project.id, v_task.amount, v_task.title)
     where id = p_task_id;
  end if;
end;
$function$;

-- ---------------------------------------------------------------------
-- 5. Views: v_project_task_updates, v_project_tasks, v_my_projects
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
       end as my_role
  from public.project_task_updates u
  join public.project_tasks t on t.id = u.task_id
  join public.projects p on p.id = u.project_id
  left join public.project_payments pp on pp.id = t.payment_id;

comment on view public.v_project_task_updates is
  'Task updates with task and project titles, evidence photo paths, decision, reason, payment amount and caller role.';

revoke all on public.v_project_task_updates from public, anon, authenticated;
grant select on public.v_project_task_updates to authenticated;
grant all on public.v_project_task_updates to service_role;

-- v_project_tasks: append last update columns at the end.
create or replace view public.v_project_tasks
with (security_invoker = true) as
select t.id,
       t.project_id,
       p.title as project_title,
       t.title,
       t.description,
       t.amount,
       t.status,
       t.payment_id,
       pp.status as payment_status,
       t.start_date,
       t.finish_date,
       t.decided_at,
       t.created_at,
       t.updated_at,
       case
         when p.owner_id = (select auth.uid()) then 'owner'::text
         when p.taker_id = (select auth.uid()) then 'taker'::text
         else null::text
       end as my_role,
       lu.id             as last_update_id,
       lu.proposed_state as last_update_proposed_state,
       lu.decision       as last_update_decision,
       lu.created_at     as last_update_at,
       coalesce(lu.decision = 'pending'::public.task_update_decision, false) as has_pending_update
  from public.project_tasks t
  join public.projects p on p.id = t.project_id
  left join public.project_payments pp on pp.id = t.payment_id
  left join lateral (
    select u.id,
           u.proposed_state,
           u.decision,
           u.created_at
      from public.project_task_updates u
     where u.task_id = t.id
     order by u.created_at desc
     limit 1
  ) lu on true;

comment on view public.v_project_tasks is
  'Project tasks with their payment stage and latest task update, visible to the owner, the taker and admins.';

revoke all on public.v_project_tasks from public, anon, authenticated;
grant select on public.v_project_tasks to authenticated;
grant all on public.v_project_tasks to service_role;

-- v_my_projects: append photo_paths at the end for the schedule header (GRA-37).
create or replace view public.v_my_projects
with (security_invoker = true) as
select p.id,
       p.title,
       p.description,
       p.status,
       p.budget,
       p.city,
       p.district,
       private.project_site_address(p.id) as site_address,
       case when p.owner_id = (select auth.uid()) then p.address_id else null::uuid end as address_id,
       p.created_at,
       p.updated_at,
       p.completed_at,
       case when p.owner_id = (select auth.uid()) then 'owner'::text else 'taker'::text end as my_role,
       p.owner_id,
       ow.full_name as owner_name,
       ow.avatar_path as owner_avatar_path,
       p.taker_id,
       tb.company_name as taker_company_name,
       tu.avatar_path as taker_avatar_path,
       ao.id as accepted_offer_id,
       ao.amount as agreed_amount,
       coalesce(pay.total_paid, 0::numeric) as total_paid,
       coalesce(pay.total_scheduled, 0::numeric) as total_scheduled,
       case when p.owner_id = (select auth.uid()) then private.project_offer_count(p.id) else null::integer end as pending_offer_count,
       (select c.id
          from public.chats c
         where c.project_id = p.id
           and c.id in (select private.my_chat_ids())
           and exists (select 1 from public.chat_members m where m.chat_id = c.id and m.user_id = p.owner_id)
           and exists (select 1 from public.chat_members m where m.chat_id = c.id and m.user_id = p.taker_id)
         order by c.created_at
         limit 1) as chat_id,
       p.status = 'completed'::public.project_status
         and not exists (select 1 from public.reviews r
                          where r.project_id = p.id and r.reviewer_id = (select auth.uid())) as can_review,
       case when p.owner_id = (select auth.uid()) then p.deed_status end as deed_status,
       case when p.owner_id = (select auth.uid()) then p.deed_rejection_reason end as deed_rejection_reason,
       p.photo_paths
  from public.projects p
  join public.users ow on ow.id = p.owner_id
  left join public.businesses tb on tb.user_id = p.taker_id
  left join public.users tu on tu.id = p.taker_id
  left join public.project_offers ao on ao.project_id = p.id and ao.status = 'accepted'::public.offer_status
  left join lateral (
    select sum(pp.amount) filter (where pp.status = 'paid'::public.payment_status) as total_paid,
           sum(pp.amount) filter (where pp.status = any (array['pending'::public.payment_status, 'processing'::public.payment_status, 'paid'::public.payment_status])) as total_scheduled
      from public.project_payments pp
     where pp.project_id = p.id
  ) pay on true
 where p.owner_id = (select auth.uid()) or p.taker_id = (select auth.uid());

-- ---------------------------------------------------------------------
-- 6. Notifications (GRA-32 / ARCHITECTURE.md §13)
-- ---------------------------------------------------------------------

-- Notify the project's owner when the contractor sends a task update.
create or replace function private.notify_task_update_sent()
returns trigger
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_project    public.projects;
  v_task_title text;
  v_proj_title text := private.notification_project_title(new.project_id);
begin
  select * into v_project from public.projects where id = new.project_id;
  select coalesce(nullif(btrim(t.title), ''), 'مهمة')
    into v_task_title
    from public.project_tasks t
   where t.id = new.task_id;

  if v_project.owner_id is distinct from new.author_id then
    perform private.notify(
      v_project.owner_id,
      case when new.proposed_state = 'done'
           then 'تحديث إنجاز مهمة بانتظار مراجعتك'
           else 'تحديث جديد على مهمة في مشروعك' end,
      coalesce(v_task_title, 'مهمة')
        || case when v_proj_title = '' then '' else ' — ' || v_proj_title end,
      jsonb_build_object(
        'type', 'task_update_sent',
        'project_id', new.project_id,
        'task_id', new.task_id,
        'update_id', new.id
      ),
      true
    );
  end if;
  return null;
exception when others then
  raise warning 'private.notify_task_update_sent(%) failed: %', new.id, sqlerrm;
  return null;
end;
$$;

drop trigger if exists notifications_task_update_sent on public.project_task_updates;
create trigger notifications_task_update_sent
  after insert on public.project_task_updates
  for each row execute function private.notify_task_update_sent();

-- Notify the contractor when the client accepts or rejects a pending task update.
create or replace function private.notify_task_update_decided()
returns trigger
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_task_title text;
  v_proj_title text := private.notification_project_title(new.project_id);
begin
  if new.decision is not distinct from old.decision
     or new.decision not in ('accepted', 'rejected') then
    return null;
  end if;

  select coalesce(nullif(btrim(t.title), ''), 'مهمة')
    into v_task_title
    from public.project_tasks t
   where t.id = new.task_id;

  if new.decision = 'accepted' then
    perform private.notify(
      new.author_id,
      'قبل العميل تحديث المهمة',
      coalesce(v_task_title, 'مهمة')
        || case when v_proj_title = '' then '' else ' — ' || v_proj_title end,
      jsonb_build_object(
        'type', 'task_update_accepted',
        'project_id', new.project_id,
        'task_id', new.task_id,
        'update_id', new.id
      ),
      true
    );
  elsif new.decision = 'rejected' then
    perform private.notify(
      new.author_id,
      'رفض العميل تحديث المهمة',
      coalesce(v_task_title, 'مهمة')
        || case when v_proj_title = '' then '' else ' — ' || v_proj_title end
        || coalesce('. السبب: ' || nullif(btrim(new.rejection_reason), ''), '.'),
      jsonb_build_object(
        'type', 'task_update_rejected',
        'project_id', new.project_id,
        'task_id', new.task_id,
        'update_id', new.id
      ),
      true
    );
  end if;
  return null;
exception when others then
  raise warning 'private.notify_task_update_decided(%) failed: %', new.id, sqlerrm;
  return null;
end;
$$;

drop trigger if exists notifications_task_update_decided on public.project_task_updates;
create trigger notifications_task_update_decided
  after update of decision on public.project_task_updates
  for each row execute function private.notify_task_update_decided();

revoke all on function private.notify_task_update_sent() from public, anon, authenticated;
revoke all on function private.notify_task_update_decided() from public, anon, authenticated;
