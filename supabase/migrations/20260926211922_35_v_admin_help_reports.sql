-- =====================================================================
-- 35_v_admin_help_reports.sql  ·  VIEW: admin queue of help reports
--
-- App (admin): supabase.from('v_admin_help_reports').select()
--                .inFilter('status', ['open', 'in_review']).order('created_at')
-- Returns nothing for non-admins.
-- =====================================================================

create view public.v_admin_help_reports
with (security_invoker = true)
as
select
  h.id,
  h.report_type,
  h.description,
  h.status,
  case
    when h.target_user_id is not null then 'user'
    when h.target_project_id is not null then 'project'
    when h.target_item_id is not null then 'marketplace_item'
    when h.target_order_id is not null then 'order'
    when h.target_review_id is not null then 'review'
    when h.target_message_id is not null then 'message'
  end as target_type,
  coalesce(h.target_user_id, h.target_project_id, h.target_item_id,
           h.target_order_id, h.target_review_id, h.target_message_id) as target_id,
  h.evidence_snapshot,
  h.reporter_id,
  rp.full_name as reporter_name,
  h.target_user_id,
  tu.full_name as target_user_name,
  h.assigned_admin_id,
  aa.full_name as assigned_admin_name,
  h.resolution_note,
  h.created_at,
  h.updated_at,
  h.resolved_at
from public.help_reports h
join public.users rp on rp.id = h.reporter_id
left join public.users tu on tu.id = h.target_user_id
left join public.users aa on aa.id = h.assigned_admin_id
where (select private.is_admin());

comment on view public.v_admin_help_reports is 'Admins only: every help report with reporter, target, evidence and assignee.';

revoke all on table public.v_admin_help_reports from anon, authenticated;
grant select on table public.v_admin_help_reports to authenticated;
;
