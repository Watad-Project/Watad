-- =====================================================================
-- 46_v_business_documents.sql  ·  VIEW: verification documents
--
-- App (owner): supabase.from('v_business_documents').select().eq('is_mine', true)
-- App (admin): supabase.from('v_business_documents').select().eq('business_id', id)
-- Open a file with supabase.storage.from('business-documents')
--   .createSignedUrl(storage_path, 60)
-- =====================================================================

create view public.v_business_documents
with (security_invoker = true)
as
select
  d.id,
  d.business_id,
  b.company_name,
  b.verification_status,
  d.document_type,
  d.storage_path,
  d.created_at,
  (d.business_id = (select auth.uid())) as is_mine
from public.business_documents d
join public.businesses b on b.user_id = d.business_id;

comment on view public.v_business_documents is 'Verification documents, visible to the business owner and admins.';

revoke all on table public.v_business_documents from anon, authenticated;
grant select on table public.v_business_documents to authenticated;
;
