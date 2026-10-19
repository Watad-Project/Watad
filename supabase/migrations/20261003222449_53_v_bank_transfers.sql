-- =====================================================================
-- 53_v_bank_transfers.sql  ·  VIEW: bank transfer receipts
--
-- App (contractor, waiting for me):
--   supabase.from('v_bank_transfers').select()
--     .eq('my_role', 'payee').eq('status', 'pending')
-- App (one stage, newest first):
--   supabase.from('v_bank_transfers').select()
--     .eq('payment_id', id).order('created_at', ascending: false)
-- Open a receipt with supabase.storage.from('bank-transfer-receipts')
--   .createSignedUrl(storage_path, 60)
-- my_role: 'payer' (owner) or 'payee' (contractor); null for admins.
-- =====================================================================

create view public.v_bank_transfers
with (security_invoker = true)
as
select
  bt.id,
  bt.payment_id,
  pp.project_id,
  p.title as project_title,
  pp.stage_number,
  pp.amount,
  pp.currency,
  bt.storage_path,
  bt.bank_reference,
  bt.status,
  bt.rejection_reason,
  bt.submitted_by,
  bt.decided_by,
  bt.decided_at,
  bt.created_at,
  case
    when p.owner_id = (select auth.uid()) then 'payer'
    when p.taker_id = (select auth.uid()) then 'payee'
  end as my_role
from public.bank_transfers bt
join public.project_payments pp on pp.id = bt.payment_id
join public.projects p on p.id = pp.project_id;

comment on view public.v_bank_transfers is 'Bank transfer receipts, visible to the project owner, the contractor and admins.';

revoke all on table public.v_bank_transfers from anon, authenticated;
grant select on table public.v_bank_transfers to authenticated;
;
