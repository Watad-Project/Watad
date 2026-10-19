-- =====================================================================
-- 36_v_admin_verification_queue.sql  ·  VIEW: businesses awaiting review
--
-- App (admin): supabase.from('v_admin_verification_queue').select().order('requested_at')
-- Decide with supabase.rpc('admin_set_business_verification', params:
--   {'p_business_id': id, 'p_status': 'verified' | 'rejected', 'p_note': '...'})
-- Returns nothing for non-admins.
-- =====================================================================

create view public.v_admin_verification_queue
with (security_invoker = true)
as
select
  b.user_id as business_id,
  b.company_name,
  b.cr_number,
  b.specialized_field,
  b.verification_status,
  b.created_at,
  b.updated_at,
  u.full_name as owner_name,
  u.created_at as member_since,
  (
    select sh.changed_at
    from public.status_history sh
    where sh.business_id = b.user_id and sh.new_status = 'pending'
    order by sh.changed_at desc
    limit 1
  ) as requested_at
from public.businesses b
join public.users u on u.id = b.user_id
where b.verification_status = 'pending'
  and b.deleted_at is null
  and (select private.is_admin());

comment on view public.v_admin_verification_queue is 'Admins only: businesses whose verification is pending.';

revoke all on table public.v_admin_verification_queue from anon, authenticated;
grant select on table public.v_admin_verification_queue to authenticated;
;
