-- =====================================================================
-- 07_projects.sql  ·  projects posted by users, taken by a business
--
-- Review fixes here:
--   #5  taker_id can't be written by clients; it is set only by
--       accept_offer() (file 08). Status changes go through
--       set_project_status() with an allowed-transition table.
--   #8  ON DELETE RESTRICT; only an untouched draft can be deleted.
--   #9  address_id must be one of the owner's own addresses (composite
--       foreign key). Only city/district are public; the full site
--       address goes to the accepted taker via project_site_address().
--   #11 enum status, budget >= 0.   #13 timestamps.
-- =====================================================================

create table public.projects (
  id           uuid primary key default gen_random_uuid(),
  owner_id     uuid not null default auth.uid()
               references public.users (id) on delete restrict,
  -- The business that took the job (a user id; see 02_businesses).
  taker_id     uuid references public.businesses (user_id) on delete restrict,
  address_id   uuid,
  title        text not null check (char_length(btrim(title)) between 3 and 150),
  description  text check (description is null or char_length(description) <= 5000),
  status       public.project_status not null default 'draft',
  budget       numeric(12, 2) check (budget is null or budget >= 0),
  -- Public location: copied from the address when one is linked.
  city         text not null check (char_length(btrim(city)) between 1 and 80),
  district     text check (district is null or char_length(btrim(district)) between 1 and 80),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  completed_at timestamptz,
  constraint projects_address_belongs_to_owner
    foreign key (address_id, owner_id)
    references public.addresses (id, owner_id)
    on delete set null (address_id),
  constraint projects_taker_is_not_owner
    check (taker_id is null or taker_id <> owner_id),
  constraint projects_taker_matches_status check (
    (status in ('draft', 'open') and taker_id is null)
    or (status in ('in_progress', 'completed') and taker_id is not null)
    or status = 'cancelled'
  )
);

comment on table public.projects is
  'taker_id is set only by accept_offer(); status only by set_project_status()/accept_offer(). address_id is private to owner and taker.';

create index projects_owner_id_idx on public.projects (owner_id, created_at desc);
create index projects_taker_id_idx on public.projects (taker_id);
create index projects_address_idx on public.projects (address_id, owner_id);
create index projects_open_idx on public.projects (created_at desc) where status = 'open';

create trigger projects_set_updated_at
  before update on public.projects
  for each row execute function private.set_updated_at();

-- City and district always match the linked address.
create or replace function private.projects_copy_location()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.address_id is not null then
    select a.city, a.district
      into new.city, new.district
      from public.addresses a
     where a.id = new.address_id;
    if not found then
      raise exception 'That address does not exist or is not yours' using errcode = '23503';
    end if;
  end if;
  return new;
end;
$$;

revoke all on function private.projects_copy_location() from public;

create trigger projects_copy_location
  before insert or update of address_id, city, district on public.projects
  for each row execute function private.projects_copy_location();

-- ---------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------

-- Projects the caller has bid on (so bidders keep seeing them after
-- they close). SECURITY DEFINER avoids an RLS loop with
-- project_offers, which is created in file 08; plpgsql resolves it at
-- run time.
create or replace function private.my_bid_project_ids()
returns setof uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  return query
    select o.project_id
    from public.project_offers o
    where o.provider_id = (select auth.uid());
end;
$$;

-- Number of pending offers, without revealing the offers themselves.
create or replace function private.project_offer_count(p_project_id uuid)
returns integer
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  return (
    select count(*)::integer
    from public.project_offers o
    where o.project_id = p_project_id and o.status = 'pending'
  );
end;
$$;

-- Full site address, only for the owner and the accepted taker.
create or replace function private.project_site_address(p_project_id uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select private.format_address(a.building_number, a.street, a.district, a.city, a.postal_code)
  from public.projects p
  join public.addresses a on a.id = p.address_id
  where p.id = p_project_id
    and (
      p.owner_id = (select auth.uid())
      or (p.taker_id = (select auth.uid()) and p.status in ('in_progress', 'completed'))
    );
$$;

revoke all on function private.my_bid_project_ids() from public;
revoke all on function private.project_offer_count(uuid) from public;
revoke all on function private.project_site_address(uuid) from public;
grant execute on function private.my_bid_project_ids() to authenticated, service_role;
grant execute on function private.project_offer_count(uuid) to authenticated, service_role;
grant execute on function private.project_site_address(uuid) to authenticated, service_role;

-- ---------------------------------------------------------------------
-- RPCs
-- ---------------------------------------------------------------------

-- updateStatus(new_status). Owner moves:
--   draft -> open | cancelled,  open -> draft (no offers yet) | cancelled,
--   in_progress -> completed.
-- open -> in_progress happens only in accept_offer(). Admins may make
-- any move the table constraints allow (e.g. cancel a disputed job).
create or replace function public.set_project_status(p_project_id uuid, p_status public.project_status)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid     uuid := private.require_active_user();
  v_admin   boolean := private.is_admin();
  v_project public.projects;
begin
  select * into v_project from public.projects where id = p_project_id for update;
  if not found or (v_project.owner_id <> v_uid and not v_admin) then
    raise exception 'Project not found' using errcode = 'P0002';
  end if;
  if v_project.status = p_status then
    return;
  end if;
  if p_status = 'in_progress' then
    raise exception 'A project starts when you accept an offer' using errcode = 'P0001';
  end if;
  if not v_admin and not (
       (v_project.status = 'draft' and p_status in ('open', 'cancelled'))
    or (v_project.status = 'open' and p_status in ('draft', 'cancelled'))
    or (v_project.status = 'in_progress' and p_status = 'completed')
  ) then
    raise exception 'A project can''t move from % to %', v_project.status, p_status using errcode = 'P0001';
  end if;
  if v_project.status = 'open' and p_status = 'draft'
     and exists (select 1 from public.project_offers where project_id = p_project_id) then
    raise exception 'This project already has offers; cancel it instead' using errcode = 'P0001';
  end if;

  perform set_config('app.status_note', case when v_admin and v_project.owner_id <> v_uid then 'changed by admin' else '' end, true);

  if p_status = 'cancelled' then
    update public.project_offers
       set status = 'rejected', decided_at = now()
     where project_id = p_project_id and status = 'pending';
  end if;

  update public.projects
     set status = p_status,
         completed_at = case when p_status = 'completed' then now() else completed_at end
   where id = p_project_id;
end;
$$;

revoke all on function public.set_project_status(uuid, public.project_status) from public, anon;
grant execute on function public.set_project_status(uuid, public.project_status) to authenticated;

-- ---------------------------------------------------------------------
-- Row level security + column grants
-- ---------------------------------------------------------------------
alter table public.projects enable row level security;

create policy projects_select
  on public.projects for select
  to authenticated
  using (
    status = 'open'
    or owner_id = (select auth.uid())
    or taker_id = (select auth.uid())
    or id in (select private.my_bid_project_ids())
    or (select private.is_admin())
  );

create policy projects_insert_own
  on public.projects for insert
  to authenticated
  with check (
    owner_id = (select auth.uid())
    and status in ('draft', 'open')
    and taker_id is null
    and (select private.is_active_user())
  );

-- Details can be edited until the job is awarded.
create policy projects_update_own
  on public.projects for update
  to authenticated
  using (owner_id = (select auth.uid()) and status in ('draft', 'open'))
  with check (owner_id = (select auth.uid()) and status in ('draft', 'open'));

create policy projects_delete_own_draft
  on public.projects for delete
  to authenticated
  using (owner_id = (select auth.uid()) and status = 'draft');

revoke all on table public.projects from anon, authenticated;
grant select, delete on table public.projects to authenticated;
grant insert (title, description, status, budget, address_id, city, district)
  on table public.projects to authenticated;
grant update (title, description, budget, address_id, city, district)
  on table public.projects to authenticated;
;
