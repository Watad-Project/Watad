-- =====================================================================
-- 64_admin_deed_review.sql  ·  admins review ownership deeds (GRA-36)
--
-- Migration 63 added projects.deed_status and the admin RPC, but no view
-- showed the deeds, and a project could be published before its deed was
-- checked. This migration:
--   1. records when a deed was sent (projects.deed_submitted_at), so the
--      queue is oldest first;
--   2. keeps a project whose deed is under review or rejected out of
--      'open': a new project with a deed starts as a draft, and nobody can
--      publish it until its deed is verified;
--   3. publishes the project when an admin verifies its deed;
--   4. adds v_admin_deed_queue: the deeds waiting for review, with the
--      project and its owner;
--   5. adds the business's city and the owner's photo to
--      v_admin_verification_queue, for the license details page;
--   6. adds deed_status and deed_rejection_reason to v_my_projects, so the
--      client sees the decision.
-- =====================================================================

-- 1. When the deed was sent. Not writable by the app (no column grant).
alter table public.projects
  add column if not exists deed_submitted_at timestamptz;

-- The deeds already waiting were sent with their project. Migration 63's
-- backfill touched updated_at, so created_at is the real time.
update public.projects
   set deed_submitted_at = created_at
 where deed_status = 'under_review'
   and deed_submitted_at is null;

-- 2a. A new or replaced deed waits for review; a new project with a deed
-- starts as a draft, hidden from contractors.
create or replace function private.handle_project_deed_status_change()
returns trigger
language plpgsql
security definer
set search_path to ''
as $$
begin
  if tg_op = 'UPDATE'
     and new.deed_storage_path is not distinct from old.deed_storage_path then
    return new;
  end if;

  if new.deed_storage_path is not null and btrim(new.deed_storage_path) <> '' then
    new.deed_status := 'under_review';
    new.deed_submitted_at := now();
    if tg_op = 'INSERT' and new.status = 'open' then
      new.status := 'draft';
    end if;
  else
    new.deed_status := 'none';
    new.deed_submitted_at := null;
  end if;
  new.deed_rejection_reason := null;
  new.deed_reviewed_at := null;
  new.deed_reviewed_by := null;
  return new;
end;
$$;

-- 2b. Nobody publishes a project whose deed isn't verified, whatever the
-- path (set_project_status() or anything added later).
create or replace function private.guard_project_deed_before_open()
returns trigger
language plpgsql
set search_path to ''
as $$
begin
  if new.status = 'open'
     and old.status is distinct from 'open'
     and new.deed_status in ('under_review', 'rejected') then
    raise exception 'deed_not_verified' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

drop trigger if exists watad_project_deed_gate on public.projects;
create trigger watad_project_deed_gate
  before update of status on public.projects
  for each row execute function private.guard_project_deed_before_open();

-- 3. Verifying a deed publishes its draft project.
create or replace function public.admin_set_project_deed_verification(
  p_project_id        uuid,
  p_status            text,
  p_rejection_reason  text default null
)
returns void
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_admin_id uuid := private.require_active_user();
  v_status   text := btrim(coalesce(p_status, ''));
  v_reason   text := btrim(coalesce(p_rejection_reason, ''));
begin
  if not private.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  if v_status not in ('under_review', 'verified', 'rejected') then
    raise exception 'invalid_deed_status' using errcode = 'P0001';
  end if;

  if v_status = 'rejected' and (v_reason = '' or char_length(v_reason) < 3) then
    raise exception 'rejection_reason_required' using errcode = 'P0001';
  end if;

  if not exists (
    select 1 from public.projects
     where id = p_project_id and deed_storage_path is not null
  ) then
    raise exception 'project_not_found' using errcode = 'P0002';
  end if;

  perform set_config(
    'app.status_note',
    case when v_status = 'verified' then 'deed verified' else '' end,
    true
  );

  update public.projects
     set deed_status           = v_status,
         deed_rejection_reason = case when v_status = 'rejected' then left(v_reason, 1000) end,
         deed_reviewed_at      = now(),
         deed_reviewed_by      = v_admin_id,
         status                = case
                                   when v_status = 'verified' and status = 'draft'
                                     then 'open'::public.project_status
                                   else status
                                 end
   where id = p_project_id;
end;
$$;

revoke all on function public.admin_set_project_deed_verification(uuid, text, text) from public, anon;
grant execute on function public.admin_set_project_deed_verification(uuid, text, text) to authenticated;

-- 4. The deeds waiting for an admin, with the project and its owner.
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
       u.created_at        as member_since
  from public.projects p
  join public.users u on u.id = p.owner_id
 where p.deed_status = 'under_review'
   and p.deed_storage_path is not null
   and (select private.is_admin());

revoke all on public.v_admin_deed_queue from public, anon, authenticated;
grant select on public.v_admin_deed_queue to authenticated;

-- 5. The license queue, plus the business's city and the owner's photo
-- (new columns go last).
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
       u.avatar_path as owner_avatar_path
  from public.businesses b
  join public.users u on u.id = b.user_id
 where b.verification_status = 'pending'::public.verification_status
   and b.deleted_at is null
   and (select private.is_admin());

-- 6. The client's projects, plus the deed decision (new columns go last).
create or replace view public.v_my_projects
with (security_invoker = true) as
select p.id,
       p.title,
       p.description,
       p.status,
       p.budget,
       p.city,
       p.district,
       private.project_site_address(p.id) as site_address,
       case when p.owner_id = (select auth.uid()) then p.address_id else null::uuid end as address_id,
       p.created_at,
       p.updated_at,
       p.completed_at,
       case when p.owner_id = (select auth.uid()) then 'owner'::text else 'taker'::text end as my_role,
       p.owner_id,
       ow.full_name as owner_name,
       ow.avatar_path as owner_avatar_path,
       p.taker_id,
       tb.company_name as taker_company_name,
       tu.avatar_path as taker_avatar_path,
       ao.id as accepted_offer_id,
       ao.amount as agreed_amount,
       coalesce(pay.total_paid, 0::numeric) as total_paid,
       coalesce(pay.total_scheduled, 0::numeric) as total_scheduled,
       case when p.owner_id = (select auth.uid()) then private.project_offer_count(p.id) else null::integer end as pending_offer_count,
       (select c.id
          from public.chats c
         where c.project_id = p.id
           and c.id in (select private.my_chat_ids())
           and exists (select 1 from public.chat_members m where m.chat_id = c.id and m.user_id = p.owner_id)
           and exists (select 1 from public.chat_members m where m.chat_id = c.id and m.user_id = p.taker_id)
         order by c.created_at
         limit 1) as chat_id,
       p.status = 'completed'::public.project_status
         and not exists (select 1 from public.reviews r
                          where r.project_id = p.id and r.reviewer_id = (select auth.uid())) as can_review,
       case when p.owner_id = (select auth.uid()) then p.deed_status end as deed_status,
       case when p.owner_id = (select auth.uid()) then p.deed_rejection_reason end as deed_rejection_reason
  from public.projects p
  join public.users ow on ow.id = p.owner_id
  left join public.businesses tb on tb.user_id = p.taker_id
  left join public.users tu on tu.id = p.taker_id
  left join public.project_offers ao on ao.project_id = p.id and ao.status = 'accepted'::public.offer_status
  left join lateral (
    select sum(pp.amount) filter (where pp.status = 'paid'::public.payment_status) as total_paid,
           sum(pp.amount) filter (where pp.status = any (array['pending'::public.payment_status, 'processing'::public.payment_status, 'paid'::public.payment_status])) as total_scheduled
      from public.project_payments pp
     where pp.project_id = p.id
  ) pay on true
 where p.owner_id = (select auth.uid()) or p.taker_id = (select auth.uid());
