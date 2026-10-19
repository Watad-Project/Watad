-- =====================================================================
-- 34_v_my_help_reports.sql  ·  VIEW: tickets the signed-in user filed
--
-- App: supabase.from('v_my_help_reports').select()
--        .order('created_at', ascending: false)
-- File one by inserting into help_reports with at most one target_* id.
-- =====================================================================

create view public.v_my_help_reports
with (security_invoker = true)
as
select
  h.id,
  h.report_type,
  h.description,
  h.status,
  h.resolution_note,
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
  h.created_at,
  h.updated_at,
  h.resolved_at
from public.help_reports h
where h.reporter_id = (select auth.uid());

comment on view public.v_my_help_reports is 'Caller''s own support tickets and reports with their status.';

revoke all on table public.v_my_help_reports from anon, authenticated;
grant select on table public.v_my_help_reports to authenticated;
;
