-- =====================================================================
-- 03_addresses.sql  ·  a user's saved addresses
--
-- Review fixes here:
--   #9  addresses are private to their owner. Projects copy only city
--       and district for everyone to see; the full site address is
--       shown to the accepted taker through project_site_address()
--       (file 07), never by opening up this table.
--   #13 timestamps.
-- =====================================================================

create table public.addresses (
  id              uuid primary key default gen_random_uuid(),
  owner_id        uuid not null default auth.uid()
                  references public.users (id) on delete restrict,
  name            text not null check (char_length(btrim(name)) between 1 and 60),
  city            text not null check (char_length(btrim(city)) between 1 and 80),
  district        text not null check (char_length(btrim(district)) between 1 and 80),
  street          text check (street is null or char_length(street) <= 120),
  building_number text check (building_number is null or char_length(building_number) <= 20),
  postal_code     text check (postal_code is null or postal_code ~ '^[0-9]{5}$'),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  -- Lets projects prove (with a composite foreign key) that the
  -- address they point at belongs to the project owner.
  constraint addresses_id_owner_key unique (id, owner_id)
);

comment on table public.addresses is
  'Private saved addresses. Only the owner can read them; a project''s taker sees the site address via project_site_address().';

create index addresses_owner_id_idx on public.addresses (owner_id);

create trigger addresses_set_updated_at
  before update on public.addresses
  for each row execute function private.set_updated_at();

-- formatAddress()
create or replace function private.format_address(
  p_building_number text,
  p_street text,
  p_district text,
  p_city text,
  p_postal_code text
)
returns text
language sql
immutable
set search_path = ''
as $$
  select concat_ws(', ',
    nullif(btrim(concat_ws(' ', p_building_number, p_street)), ''),
    p_district,
    p_city,
    p_postal_code);
$$;

revoke all on function private.format_address(text, text, text, text, text) from public;
grant execute on function private.format_address(text, text, text, text, text) to authenticated, service_role;

-- A site address can't disappear from under a project in progress.
-- (projects is created in file 07; plpgsql looks it up at run time.)
create or replace function private.addresses_guard_delete()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if exists (
    select 1 from public.projects p
    where p.address_id = old.id and p.status = 'in_progress'
  ) then
    raise exception 'This address is the site of a project in progress and cannot be deleted yet'
      using errcode = 'P0001';
  end if;
  return old;
end;
$$;

revoke all on function private.addresses_guard_delete() from public;

create trigger addresses_guard_delete
  before delete on public.addresses
  for each row execute function private.addresses_guard_delete();

-- ---------------------------------------------------------------------
-- Row level security + column grants
-- ---------------------------------------------------------------------
alter table public.addresses enable row level security;

create policy addresses_select_own
  on public.addresses for select
  to authenticated
  using (owner_id = (select auth.uid()));

create policy addresses_insert_own
  on public.addresses for insert
  to authenticated
  with check (owner_id = (select auth.uid()) and (select private.is_active_user()));

create policy addresses_update_own
  on public.addresses for update
  to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

create policy addresses_delete_own
  on public.addresses for delete
  to authenticated
  using (owner_id = (select auth.uid()));

revoke all on table public.addresses from anon, authenticated;
grant select, delete on table public.addresses to authenticated;
grant insert (name, city, district, street, building_number, postal_code)
  on table public.addresses to authenticated;
grant update (name, city, district, street, building_number, postal_code)
  on table public.addresses to authenticated;
;
