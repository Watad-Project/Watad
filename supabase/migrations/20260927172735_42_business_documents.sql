-- =====================================================================
-- 42_business_documents.sql  ·  verification documents (new table)
--
-- Feature (scenarios 02, 05): a business uploads its documents
-- (commercial registration, VAT certificate, ...) and an admin reviews
-- them before verifying.
--   - Private storage bucket "business-documents": PDF, JPEG or PNG,
--     up to 10 MB. The owner uploads into "<own user id>/<file>" while
--     the business is unverified or rejected; admins can read every file.
--   - business_documents: one row per uploaded file.
--   - request_business_verification() needs at least one document
--     uploaded since the business was last rejected or reset (a changed
--     company name or CR number resets it).
--   - v_admin_verification_queue gains document_count.
-- =====================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('business-documents', 'business-documents', false, 10485760,
        array['application/pdf', 'image/jpeg', 'image/png'])
on conflict (id) do nothing;

create policy watad_bizdocs_insert_own
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'business-documents'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and (select private.is_active_user())
    and exists (
      select 1 from public.businesses b
      where b.user_id = (select auth.uid())
        and b.verification_status in ('unverified', 'rejected')
        and b.deleted_at is null
    )
  );

create policy watad_bizdocs_select
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'business-documents'
    and ((storage.foldername(name))[1] = (select auth.uid())::text or (select private.is_admin()))
  );

create type public.business_document_type as enum (
  'commercial_registration', 'vat_certificate', 'national_address', 'other'
);

create table public.business_documents (
  id            uuid primary key default gen_random_uuid(),
  business_id   uuid not null default auth.uid()
                references public.businesses (user_id) on delete restrict,
  document_type public.business_document_type not null,
  -- Object path in the "business-documents" bucket: "<business id>/<file>".
  storage_path  text not null unique
                check (storage_path ~ '^[0-9a-f-]{36}/[A-Za-z0-9_-][A-Za-z0-9._-]{0,199}$'
                       and split_part(storage_path, '/', 1) = business_id::text),
  created_at    timestamptz not null default now()
);

comment on table public.business_documents is
  'Files a business sent for verification. Readable by the owner and admins; added only while unverified or rejected.';

create index business_documents_business_id_idx on public.business_documents (business_id, created_at desc);

alter table public.business_documents enable row level security;

create policy business_documents_select
  on public.business_documents for select
  to authenticated
  using (business_id = (select auth.uid()) or (select private.is_admin()));

-- The row must point at a file the owner really uploaded.
create policy business_documents_insert_own
  on public.business_documents for insert
  to authenticated
  with check (
    business_id = (select auth.uid())
    and (select private.is_active_user())
    and exists (
      select 1 from public.businesses b
      where b.user_id = (select auth.uid())
        and b.verification_status in ('unverified', 'rejected')
        and b.deleted_at is null
    )
    and exists (
      select 1 from storage.objects o
      where o.bucket_id = 'business-documents'
        and o.name = business_documents.storage_path
    )
  );

revoke all on table public.business_documents from anon, authenticated;
grant select on table public.business_documents to authenticated;
grant insert (document_type, storage_path) on table public.business_documents to authenticated;

-- requestVerification(): unverified/rejected -> pending, with documents.
create or replace function public.request_business_verification()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid   uuid := private.require_active_user();
  v_since timestamptz;
begin
  if not exists (
    select 1 from public.businesses
    where user_id = v_uid
      and deleted_at is null
      and verification_status in ('unverified', 'rejected')
  ) then
    raise exception 'Nothing to verify: no business profile, or it is already pending, verified or suspended'
      using errcode = 'P0001';
  end if;

  -- Documents must be newer than the last rejection or reset.
  select max(sh.changed_at) into v_since
    from public.status_history sh
   where sh.business_id = v_uid
     and sh.old_status is not null
     and sh.new_status in ('rejected', 'unverified');
  if not exists (
    select 1 from public.business_documents d
    where d.business_id = v_uid
      and d.created_at > coalesce(v_since, '-infinity'::timestamptz)
  ) then
    raise exception 'Upload your documents before asking for verification' using errcode = 'P0001';
  end if;

  update public.businesses
     set verification_status = 'pending'
   where user_id = v_uid;
end;
$$;

create or replace view public.v_admin_verification_queue
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
  ) as requested_at,
  (
    select count(*)::integer
    from public.business_documents d
    where d.business_id = b.user_id
  ) as document_count
from public.businesses b
join public.users u on u.id = b.user_id
where b.verification_status = 'pending'
  and b.deleted_at is null
  and (select private.is_admin());
;
