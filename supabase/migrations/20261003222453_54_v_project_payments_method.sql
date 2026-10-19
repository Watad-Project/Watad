-- =====================================================================
-- 54_v_project_payments_method.sql  ·  VIEW: payment stages + method
--
-- Adds method ('gateway', 'wallet', 'bank_transfer'; null while nothing
-- is in flight). A stage with status 'processing' and method
-- 'bank_transfer' is waiting for the contractor to check the receipt
-- (details in v_bank_transfers).
-- Replaces 29_v_project_payments.sql; the new column comes last.
-- =====================================================================

create or replace view public.v_project_payments
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
  end as my_role,
  pp.method
from public.project_payments pp
join public.projects p on p.id = pp.project_id;

revoke all on table public.v_project_payments from anon, authenticated;
grant select on table public.v_project_payments to authenticated;
;
