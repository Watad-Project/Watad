-- =====================================================================
-- 30_v_project_reports.sql  ·  VIEW: progress updates on a project
--
-- App: supabase.from('v_project_reports').select().eq('project_id', id)
--        .order('created_at', ascending: false)
-- Post a new one by inserting {project_id, title, content} into
-- project_reports (taker only, while in progress).
-- =====================================================================

create view public.v_project_reports
with (security_invoker = true)
as
select
  r.id,
  r.project_id,
  p.title as project_title,
  r.author_id,
  b.company_name as author_company_name,
  u.avatar_path as author_avatar_path,
  r.title,
  r.content,
  r.created_at,
  r.updated_at,
  (r.author_id = (select auth.uid())) as is_mine
from public.project_reports r
join public.projects p on p.id = r.project_id
join public.businesses b on b.user_id = r.author_id
join public.users u on u.id = r.author_id;

comment on view public.v_project_reports is 'Taker''s progress reports, visible to the project owner, the taker and admins.';

revoke all on table public.v_project_reports from anon, authenticated;
grant select on table public.v_project_reports to authenticated;
;
