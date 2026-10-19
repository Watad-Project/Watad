-- =====================================================================
-- 65_admin_requester_national_id.sql  ·  admins see the requester's ID
--
-- To check a deed (the owner's ID is printed on it) or a license, the
-- admin needs the requester's ID/iqama number. user_identity stays
-- readable only by its owner (RLS user_identity_select_own): instead of
-- a policy that would let admins read every identity, one private helper
-- returns the number to an admin, and only the two admin queues use it,
-- so an admin sees the numbers of people waiting for a review and no one
-- else's. The phone stays private.
-- =====================================================================

create or replace function private.admin_national_id(p_user_id uuid)
returns text
language sql
stable
security definer
set search_path to ''
as $$
  select i.national_id
    from public.user_identity i
   where i.user_id = p_user_id
     and (select private.is_admin());
$$;

revoke all on function private.admin_national_id(uuid) from public, anon;
grant execute on function private.admin_national_id(uuid) to authenticated;

-- The deed queue (migration 64), plus the owner's ID number (last).
create or replace view public.v_admin_deed_queue
with (security_invoker = true) as
select p.id                as project_id,
       p.title,
       p.description,
       p.budget,
       p.city,
       p.district,
       p.photo_paths,
       p.deed_storage_path,
       p.deed_submitted_at as requested_at,
       p.created_at,
       p.owner_id,
       u.full_name         as owner_name,
       u.avatar_path       as owner_avatar_path,
       u.created_at        as member_since,
       private.admin_national_id(p.owner_id) as owner_national_id
  from public.projects p
  join public.users u on u.id = p.owner_id
 where p.deed_status = 'under_review'
   and p.deed_storage_path is not null
   and (select private.is_admin());

-- The license queue (migration 64), plus the owner's ID number (last).
create or replace view public.v_admin_verification_queue
with (security_invoker = true) as
select b.user_id as business_id,
       b.company_name,
       b.cr_number,
       b.specialized_field,
       b.verification_status,
       b.created_at,
       b.updated_at,
       u.full_name as owner_name,
       u.created_at as member_since,
       (select sh.changed_at
          from public.status_history sh
         where sh.business_id = b.user_id and sh.new_status = 'pending'::text
         order by sh.changed_at desc
         limit 1) as requested_at,
       (select count(*)::integer as count
          from public.business_documents d
         where d.business_id = b.user_id) as document_count,
       b.city,
       u.avatar_path as owner_avatar_path,
       private.admin_national_id(b.user_id) as owner_national_id
  from public.businesses b
  join public.users u on u.id = b.user_id
 where b.verification_status = 'pending'::public.verification_status
   and b.deleted_at is null
   and (select private.is_admin());
