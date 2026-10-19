-- =====================================================================
-- 47_v_project_tasks.sql  ·  VIEW: tasks of a project
--
-- App: supabase.from('v_project_tasks').select().eq('project_id', id)
--        .order('created_at')
-- Propose: insert {project_id, title, description, amount} into project_tasks
-- Move:    supabase.rpc('set_task_status', params: {'p_task_id': id, 'p_status': 'accepted'})
-- =====================================================================

create view public.v_project_tasks
with (security_invoker = true)
as
select
  t.id,
  t.project_id,
  p.title as project_title,
  t.title,
  t.description,
  t.amount,
  t.status,
  t.payment_id,
  pp.status as payment_status,
  t.done_at,
  t.decided_at,
  t.created_at,
  t.updated_at,
  case
    when p.owner_id = (select auth.uid()) then 'owner'
    when p.taker_id = (select auth.uid()) then 'taker'
  end as my_role
from public.project_tasks t
join public.projects p on p.id = t.project_id
left join public.project_payments pp on pp.id = t.payment_id;

comment on view public.v_project_tasks is 'Project tasks with their payment stage, visible to the owner, the taker and admins.';

revoke all on table public.v_project_tasks from anon, authenticated;
grant select on table public.v_project_tasks to authenticated;
;
