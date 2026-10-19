-- =====================================================================
-- 22_v_my_addresses.sql  ·  VIEW: the signed-in user's saved addresses
--
-- App: supabase.from('v_my_addresses').select().order('created_at')
-- Add / edit / delete through the addresses table itself.
-- =====================================================================

create view public.v_my_addresses
with (security_invoker = true)
as
select
  a.id,
  a.name,
  a.city,
  a.district,
  a.street,
  a.building_number,
  a.postal_code,
  private.format_address(a.building_number, a.street, a.district, a.city, a.postal_code) as formatted_address,
  exists (
    select 1 from public.projects p
    where p.address_id = a.id and p.status = 'in_progress'
  ) as is_active_project_site,
  a.created_at,
  a.updated_at
from public.addresses a
where a.owner_id = (select auth.uid());

comment on view public.v_my_addresses is 'Own addresses with formatAddress() applied. is_active_project_site = cannot be deleted yet.';

revoke all on table public.v_my_addresses from anon, authenticated;
grant select on table public.v_my_addresses to authenticated;
;
