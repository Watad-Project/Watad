-- =====================================================================
-- 33_v_reviews.sql  ·  VIEW: reviews with the reviewer's name
--
-- App: supabase.from('v_reviews').select().eq('target_user_id', userId)
--        .order('created_at', ascending: false)
-- Write one by inserting into reviews (see 14_reviews.sql); use
-- can_review in v_my_orders / v_my_projects to show the button.
-- =====================================================================

create view public.v_reviews
with (security_invoker = true)
as
select
  r.id,
  r.target_user_id,
  r.reviewer_id,
  u.full_name as reviewer_name,
  u.avatar_path as reviewer_avatar_path,
  r.rating,
  r.comment,
  case when r.project_id is not null then 'project' else 'order' end as context_type,
  r.project_id,
  r.order_id,
  r.created_at,
  r.updated_at,
  (r.reviewer_id = (select auth.uid())) as is_mine
from public.reviews r
join public.users u on u.id = r.reviewer_id;

comment on view public.v_reviews is 'All reviews with reviewer name/avatar and whether it came from a project or an order.';

revoke all on table public.v_reviews from anon, authenticated;
grant select on table public.v_reviews to authenticated;
;
