-- =====================================================================
-- 41_listing_delete_final.sql
--
-- Decision (scenario 16): deleting a listing is final. Before this the
-- seller could set deleted_at back to null and the listing went live
-- again. A seller who changes their mind lists the item again.
-- =====================================================================

create or replace function private.marketplace_items_no_undelete()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if old.deleted_at is not null and new.deleted_at is null then
    raise exception 'A deleted listing cannot be restored; list it again instead' using errcode = '42501';
  end if;
  return new;
end;
$$;

revoke all on function private.marketplace_items_no_undelete() from public;

create trigger marketplace_items_no_undelete
  before update of deleted_at on public.marketplace_items
  for each row execute function private.marketplace_items_no_undelete();
;
