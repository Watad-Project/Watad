-- =====================================================================
-- 08_project_offers.sql  ·  businesses bid on open projects
--
-- Review fixes here:
--   #4  provider_id is always the signed-in user.
--   #5  only verified businesses can bid; never on their own project;
--       one live offer per business per project; only the project
--       owner can accept or reject (server-side, in one transaction);
--       the amount is frozen once the offer is decided; the owner must
--       confirm the amount they saw, so it can't be switched last-second.
--   #7  a partial unique index allows only one accepted offer per project,
--       and accept_offer() locks the project row first.
--   #8  ON DELETE RESTRICT.   #11 amount > 0.   #13 timestamps + history.
-- =====================================================================

create table public.project_offers (
  id          uuid primary key default gen_random_uuid(),
  project_id  uuid not null references public.projects (id) on delete restrict,
  provider_id uuid not null default auth.uid()
              references public.businesses (user_id) on delete restrict,
  amount      numeric(12, 2) not null check (amount > 0),
  message     text check (message is null or char_length(message) <= 2000),
  status      public.offer_status not null default 'pending',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  decided_at  timestamptz
);

comment on table public.project_offers is
  'Bids. Providers edit amount/message while pending; accept_offer()/reject_offer()/withdraw_offer() decide them.';

create index project_offers_project_id_idx on public.project_offers (project_id, created_at desc);
create index project_offers_provider_id_idx on public.project_offers (provider_id, created_at desc);
create unique index project_offers_one_live_per_provider
  on public.project_offers (project_id, provider_id)
  where status in ('pending', 'accepted');
create unique index project_offers_one_accepted_per_project
  on public.project_offers (project_id)
  where status = 'accepted';

create trigger project_offers_set_updated_at
  before update on public.project_offers
  for each row execute function private.set_updated_at();

-- Decided offers are frozen, for everyone (admins included).
create or replace function private.project_offers_freeze()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.project_id <> old.project_id or new.provider_id <> old.provider_id then
    raise exception 'An offer can''t move to another project or provider' using errcode = 'P0001';
  end if;
  if old.status <> 'pending' and (new.amount, new.message) is distinct from (old.amount, old.message) then
    raise exception 'An offer can only be edited while it is pending' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

revoke all on function private.project_offers_freeze() from public;

create trigger project_offers_freeze
  before update on public.project_offers
  for each row execute function private.project_offers_freeze();

-- ---------------------------------------------------------------------
-- RPCs
-- ---------------------------------------------------------------------

-- acceptOffer(): owner only. Pass the amount the app showed; if the
-- provider changed it in the meantime the call fails.
create or replace function public.accept_offer(p_offer_id uuid, p_expected_amount numeric)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid        uuid := private.require_active_user();
  v_project_id uuid;
  v_project    public.projects;
  v_offer      public.project_offers;
begin
  select o.project_id into v_project_id from public.project_offers o where o.id = p_offer_id;
  if not found then
    raise exception 'Offer not found' using errcode = 'P0002';
  end if;

  -- Lock the project first: accepts/rejects on one project queue here.
  select * into v_project from public.projects where id = v_project_id for update;
  if v_project.owner_id <> v_uid then
    raise exception 'Only the project owner can accept offers' using errcode = '42501';
  end if;
  if v_project.status <> 'open' then
    raise exception 'This project is not open for offers' using errcode = 'P0001';
  end if;

  select * into v_offer from public.project_offers where id = p_offer_id for update;
  if v_offer.status <> 'pending' then
    raise exception 'This offer is no longer pending' using errcode = 'P0001';
  end if;
  if p_expected_amount is null or v_offer.amount <> p_expected_amount then
    raise exception 'The offer amount changed to %; review it again', v_offer.amount using errcode = 'P0001';
  end if;
  if not private.is_verified_business(v_offer.provider_id) then
    raise exception 'This provider is no longer a verified business' using errcode = 'P0001';
  end if;

  perform set_config('app.status_note', 'offer accepted', true);
  update public.project_offers
     set status = 'accepted', decided_at = now()
   where id = p_offer_id;
  update public.project_offers
     set status = 'rejected', decided_at = now()
   where project_id = v_project_id and id <> p_offer_id and status = 'pending';
  update public.projects
     set taker_id = v_offer.provider_id, status = 'in_progress'
   where id = v_project_id;

  -- Owner and taker get a private project chat (file 11).
  perform private.ensure_chat(v_uid, v_offer.provider_id, v_project_id);
end;
$$;

-- rejectOffer(): owner only.
create or replace function public.reject_offer(p_offer_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_active_user();
begin
  update public.project_offers o
     set status = 'rejected', decided_at = now()
    from public.projects p
   where o.id = p_offer_id
     and p.id = o.project_id
     and p.owner_id = v_uid
     and o.status = 'pending';
  if not found then
    raise exception 'No pending offer with that id on your projects' using errcode = 'P0002';
  end if;
end;
$$;

-- The provider takes back a pending offer.
create or replace function public.withdraw_offer(p_offer_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_active_user();
begin
  update public.project_offers
     set status = 'withdrawn', decided_at = now()
   where id = p_offer_id and provider_id = v_uid and status = 'pending';
  if not found then
    raise exception 'No pending offer of yours with that id' using errcode = 'P0002';
  end if;
end;
$$;

revoke all on function public.accept_offer(uuid, numeric) from public, anon;
revoke all on function public.reject_offer(uuid) from public, anon;
revoke all on function public.withdraw_offer(uuid) from public, anon;
grant execute on function public.accept_offer(uuid, numeric) to authenticated;
grant execute on function public.reject_offer(uuid) to authenticated;
grant execute on function public.withdraw_offer(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- Row level security + column grants
-- ---------------------------------------------------------------------
alter table public.project_offers enable row level security;

-- A provider sees their own offers; the project owner sees every offer
-- on the project. Competitors never see each other's bids.
create policy project_offers_select
  on public.project_offers for select
  to authenticated
  using (
    provider_id = (select auth.uid())
    or exists (
      select 1 from public.projects p
      where p.id = project_offers.project_id and p.owner_id = (select auth.uid())
    )
    or (select private.is_admin())
  );

create policy project_offers_insert
  on public.project_offers for insert
  to authenticated
  with check (
    provider_id = (select auth.uid())
    and status = 'pending'
    and (select private.is_verified_business((select auth.uid())))
    and exists (
      select 1 from public.projects p
      where p.id = project_offers.project_id
        and p.status = 'open'
        and p.owner_id <> (select auth.uid())
    )
  );

create policy project_offers_update_own_pending
  on public.project_offers for update
  to authenticated
  using (provider_id = (select auth.uid()) and status = 'pending')
  with check (provider_id = (select auth.uid()) and status = 'pending');

revoke all on table public.project_offers from anon, authenticated;
grant select on table public.project_offers to authenticated;
grant insert (project_id, amount, message) on table public.project_offers to authenticated;
grant update (amount, message) on table public.project_offers to authenticated;
;
