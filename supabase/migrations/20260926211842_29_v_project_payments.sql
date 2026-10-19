-- =====================================================================
-- 29_v_project_payments.sql  ·  VIEW: payment stages of my projects
--
-- App: supabase.from('v_project_payments').select().eq('project_id', id)
--        .order('stage_number')
-- my_role: 'payer' (owner) or 'payee' (taker).
-- =====================================================================

create view public.v_project_payments
with (security_invoker = true)
as
select
  pp.id,
  pp.project_id,
  p.title as project_title,
  pp.stage_number,
  pp.description,
  pp.amount,
  pp.currency,
  pp.status,
  pp.paid_at,
  pp.refunded_at,
  pp.created_at,
  pp.updated_at,
  case
    when p.owner_id = (select auth.uid()) then 'payer'
    when p.taker_id = (select auth.uid()) then 'payee'
  end as my_role
from public.project_payments pp
join public.projects p on p.id = pp.project_id;

comment on view public.v_project_payments is 'Payment stages visible to the project owner, the taker and admins.';

revoke all on table public.v_project_payments from anon, authenticated;
grant select on table public.v_project_payments to authenticated;
;
