-- =====================================================================
-- 43_project_tasks.sql  ·  tasks inside a project in progress (new table)
--
-- Feature (scenarios 11a, 11b, 12): the business doing the job proposes
-- tasks, the client accepts or rejects them, the business marks them
-- done, and the client approves or sends them back. Approving a priced
-- task schedules a payment stage under the add_payment_stage() rules
-- (never above the agreed amount); it is then paid through the gateway.
--
-- Every move goes through set_task_status(), which allows each step for
-- one side only. Task changes are recorded in status_history.
-- =====================================================================

create type public.task_status as enum ('proposed', 'accepted', 'done', 'approved', 'rejected');

create table public.project_tasks (
  id          uuid primary key default gen_random_uuid(),
  project_id  uuid not null references public.projects (id) on delete restrict,
  -- The business doing the job (the project's taker).
  created_by  uuid not null default auth.uid()
              references public.businesses (user_id) on delete restrict,
  title       text not null check (char_length(btrim(title)) between 2 and 150),
  description text check (description is null or char_length(description) <= 5000),
  -- Optional price; approving a priced task schedules a payment stage.
  amount      numeric(12, 2) check (amount is null or amount > 0),
  status      public.task_status not null default 'proposed',
  payment_id  uuid unique references public.project_payments (id) on delete restrict,
  done_at     timestamptz,
  decided_at  timestamptz,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

comment on table public.project_tasks is
  'Tasks proposed by the taker. Status changes only through set_task_status(); approving a priced task creates its payment stage.';

create index project_tasks_project_id_idx on public.project_tasks (project_id, created_at);
create index project_tasks_created_by_idx on public.project_tasks (created_by);

create trigger project_tasks_set_updated_at
  before update on public.project_tasks
  for each row execute function private.set_updated_at();

alter table public.project_tasks enable row level security;

create policy project_tasks_select
  on public.project_tasks for select
  to authenticated
  using (
    (select private.is_admin())
    or exists (
      select 1 from public.projects p
      where p.id = project_tasks.project_id
        and (p.owner_id = (select auth.uid()) or p.taker_id = (select auth.uid()))
    )
  );

-- The business doing the job proposes tasks while the project is in progress.
create policy project_tasks_insert_taker
  on public.project_tasks for insert
  to authenticated
  with check (
    created_by = (select auth.uid())
    and status = 'proposed'
    and (select private.is_active_user())
    and exists (
      select 1 from public.projects p
      where p.id = project_tasks.project_id
        and p.taker_id = (select auth.uid())
        and p.status = 'in_progress'
    )
  );

revoke all on table public.project_tasks from anon, authenticated;
grant select on table public.project_tasks to authenticated;
grant insert (project_id, title, description, amount) on table public.project_tasks to authenticated;

-- Client:   proposed -> accepted | rejected,   done -> approved | accepted (send back)
-- Business: accepted -> done
create or replace function public.set_task_status(p_task_id uuid, p_status public.task_status)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid     uuid := private.require_active_user();
  v_task    public.project_tasks;
  v_project public.projects;
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
    raise exception 'Tasks can only change while the project is in progress' using errcode = 'P0001';
  end if;
  if not (
       (v_uid = v_project.owner_id and v_task.status = 'proposed' and p_status in ('accepted', 'rejected'))
    or (v_uid = v_project.taker_id and v_task.status = 'accepted' and p_status = 'done')
    or (v_uid = v_project.owner_id and v_task.status = 'done' and p_status in ('approved', 'accepted'))
  ) then
    raise exception 'You can''t move this task from % to %', v_task.status, p_status using errcode = 'P0001';
  end if;

  update public.project_tasks
     set status = p_status,
         done_at = case when p_status = 'done' then now()
                        when p_status = 'accepted' and v_task.status = 'done' then null
                        else done_at end,
         decided_at = case when p_status in ('accepted', 'rejected', 'approved') then now() else decided_at end
   where id = p_task_id;

  if p_status = 'approved' and v_task.amount is not null then
    update public.project_tasks
       set payment_id = public.add_payment_stage(v_project.id, v_task.amount, v_task.title)
     where id = p_task_id;
  end if;
end;
$$;

revoke all on function public.set_task_status(uuid, public.task_status) from public, anon;
grant execute on function public.set_task_status(uuid, public.task_status) to authenticated;

-- ---------------------------------------------------------------------
-- Task changes join the audit trail (16_status_history.sql)
-- ---------------------------------------------------------------------
alter table public.status_history
  add column project_task_id uuid references public.project_tasks (id) on delete restrict;

create index status_history_project_task_id_idx on public.status_history (project_task_id);

alter table public.status_history drop constraint status_history_one_subject;
alter table public.status_history add constraint status_history_one_subject check (
  num_nonnulls(order_id, project_id, project_offer_id, project_payment_id,
               business_id, help_report_id, project_task_id) = 1
);

create or replace function private.record_status_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_col   text := case when tg_table_name = 'businesses' then 'verification_status' else 'status' end;
  v_key   text := case when tg_table_name = 'businesses' then 'user_id' else 'id' end;
  v_new   text := to_jsonb(new) ->> v_col;
  v_old   text;
  v_id    uuid := (to_jsonb(new) ->> v_key)::uuid;
  v_actor uuid;
begin
  if tg_op = 'UPDATE' then
    v_old := to_jsonb(old) ->> v_col;
    if v_old is not distinct from v_new then
      return new;
    end if;
  end if;

  select u.id into v_actor from public.users u where u.id = auth.uid();

  insert into public.status_history (
    order_id, project_id, project_offer_id, project_payment_id, business_id, help_report_id,
    project_task_id, old_status, new_status, changed_by, note)
  values (
    case when tg_table_name = 'orders' then v_id end,
    case when tg_table_name = 'projects' then v_id end,
    case when tg_table_name = 'project_offers' then v_id end,
    case when tg_table_name = 'project_payments' then v_id end,
    case when tg_table_name = 'businesses' then v_id end,
    case when tg_table_name = 'help_reports' then v_id end,
    case when tg_table_name = 'project_tasks' then v_id end,
    v_old, v_new, v_actor,
    nullif(current_setting('app.status_note', true), ''));
  return new;
end;
$$;

create trigger project_tasks_status_history
  after insert or update of status on public.project_tasks
  for each row execute function private.record_status_change();

alter policy status_history_select
  on public.status_history
  using (
    (select private.is_admin())
    or business_id = (select auth.uid())
    or exists (
      select 1 from public.orders o
      where o.id = status_history.order_id
        and (o.buyer_id = (select auth.uid()) or o.seller_id = (select auth.uid()))
    )
    or exists (
      select 1 from public.projects p
      where p.id = status_history.project_id
        and (p.owner_id = (select auth.uid()) or p.taker_id = (select auth.uid()))
    )
    or exists (
      select 1 from public.project_offers po
      join public.projects p on p.id = po.project_id
      where po.id = status_history.project_offer_id
        and (po.provider_id = (select auth.uid()) or p.owner_id = (select auth.uid()))
    )
    or exists (
      select 1 from public.project_payments pp
      join public.projects p on p.id = pp.project_id
      where pp.id = status_history.project_payment_id
        and (p.owner_id = (select auth.uid()) or p.taker_id = (select auth.uid()))
    )
    or exists (
      select 1 from public.help_reports h
      where h.id = status_history.help_report_id
        and h.reporter_id = (select auth.uid())
    )
    or exists (
      select 1 from public.project_tasks t
      join public.projects p on p.id = t.project_id
      where t.id = status_history.project_task_id
        and (p.owner_id = (select auth.uid()) or p.taker_id = (select auth.uid()))
    )
  );
;
