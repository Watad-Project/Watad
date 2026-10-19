-- Align project tasks and payments with the blockchain record (fabric-projects-network, chaincode 1.3).

-- 1. SAR is the only currency of a project payment (the default stays 'SAR').
alter table public.project_payments drop constraint project_payments_currency_check;
alter table public.project_payments add constraint project_payments_currency_check check (currency = 'SAR');

-- 2. Tasks: the view depends on done_at, so drop it first and recreate it below.
drop view public.v_project_tasks;

-- done_at (timestamptz) -> finish_date (date, Riyadh calendar day)
alter table public.project_tasks rename column done_at to finish_date;
alter table public.project_tasks
  alter column finish_date type date using (finish_date at time zone 'Asia/Riyadh')::date;

-- new: start_date
alter table public.project_tasks add column start_date date;

-- description is required (1..5000 characters), like the blockchain record
alter table public.project_tasks drop constraint project_tasks_description_check;
alter table public.project_tasks alter column description set not null;
alter table public.project_tasks
  add constraint project_tasks_description_check
  check (char_length(btrim(description)) >= 1 and char_length(description) <= 5000);

-- same date rules as the blockchain: a finish date needs a start date and cannot be before it
alter table public.project_tasks
  add constraint project_tasks_dates_check
  check ((finish_date is null or start_date is not null) and (finish_date is null or finish_date >= start_date));

-- a task has a finish date exactly when its status is done or approved
alter table public.project_tasks
  add constraint project_tasks_finish_matches_status
  check ((status in ('done', 'approved')) = (finish_date is not null));

-- the taker can give a start date when proposing a task
grant insert (start_date) on public.project_tasks to authenticated;

comment on column public.project_tasks.start_date is
  'Date the task starts (planned or actual). Optional when proposing; if still empty when the task is marked done it becomes the acceptance date. Blockchain field: startDate.';
comment on column public.project_tasks.finish_date is
  'Riyadh calendar day the task was marked done; empty unless status is done or approved. Replaces done_at. Blockchain field: finishDate.';

-- 3. set_task_status: same workflow as before, now with start_date / finish_date
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
    raise exception 'Tasks can only change while the project is in progress' using errcode = 'P0001';
  end if;
  if not (
       (v_uid = v_project.owner_id and v_task.status = 'proposed' and p_status in ('accepted', 'rejected'))
    or (v_uid = v_project.taker_id and v_task.status = 'accepted' and p_status = 'done')
    or (v_uid = v_project.owner_id and v_task.status = 'done' and p_status in ('approved', 'accepted'))
  ) then
    raise exception 'You can''t move this task from % to %', v_task.status, p_status using errcode = 'P0001';
  end if;
  if p_status = 'done' and v_task.start_date is not null and v_task.start_date > v_today then
    raise exception 'A task can''t be finished before its start date' using errcode = 'P0001';
  end if;

  update public.project_tasks
     set status      = p_status,
         start_date  = case when p_status = 'done'
                            then coalesce(start_date, (decided_at at time zone 'Asia/Riyadh')::date)
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

-- 4. View: same as before, with start_date / finish_date instead of done_at
create view public.v_project_tasks with (security_invoker = true) as
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
        end as my_role
   from public.project_tasks t
   join public.projects p on p.id = t.project_id
   left join public.project_payments pp on pp.id = t.payment_id;

comment on view public.v_project_tasks is
  'Project tasks with their payment stage, visible to the owner, the taker and admins.';
revoke all on public.v_project_tasks from anon, authenticated;
grant select on public.v_project_tasks to authenticated;
grant all on public.v_project_tasks to service_role;
;
