-- =====================================================================
-- 02_businesses.sql  ·  a user's business profile (0..1 per user)
--
-- Review fixes here:
--   #1  verification_status is written only by admins; editing the
--       company name or CR number resets a pending/verified business.
--   #12 one business per user (primary key = user id) and a unique,
--       well-formed CR number.
--   #13 timestamps, plus status_history (file 16) logs every change.
--   design note: the business's key IS the user's id, so provider_id,
--       taker_id and author_id elsewhere are user ids too.
-- =====================================================================

create table public.businesses (
  user_id             uuid primary key default auth.uid()
                      references public.users (id) on delete restrict,
  company_name        text not null
                      check (char_length(btrim(company_name)) between 2 and 150),
  -- Saudi Commercial Registration number: 10 digits.
  cr_number           text not null unique
                      check (cr_number ~ '^[0-9]{10}$'),
  specialized_field   text not null
                      check (char_length(btrim(specialized_field)) between 2 and 100),
  verification_status public.verification_status not null default 'unverified',
  verified_at         timestamptz,
  verified_by         uuid references public.users (id) on delete restrict,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  deleted_at          timestamptz
);

comment on table public.businesses is
  'Business profile of a user. Primary key is the owner''s user id. Only admins change verification_status.';

create index businesses_verified_by_idx on public.businesses (verified_by);
create index businesses_pending_idx on public.businesses (created_at)
  where verification_status = 'pending';

create trigger businesses_set_updated_at
  before update on public.businesses
  for each row execute function private.set_updated_at();

-- Changing the legal identity drops an existing or pending verification.
-- A suspended or rejected business stays as it is.
create or replace function private.businesses_reset_verification()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if (new.company_name, new.cr_number) is distinct from (old.company_name, old.cr_number)
     and old.verification_status in ('pending', 'verified')
     and new.verification_status = old.verification_status then
    new.verification_status := 'unverified';
    new.verified_at := null;
    new.verified_by := null;
  end if;
  return new;
end;
$$;

revoke all on function private.businesses_reset_verification() from public;

create trigger businesses_reset_verification
  before update on public.businesses
  for each row execute function private.businesses_reset_verification();

-- Is this user a verified, active business? Used by offer rules.
create or replace function private.is_verified_business(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.businesses b
    join public.users u on u.id = b.user_id
    where b.user_id = p_user_id
      and b.verification_status = 'verified'
      and b.deleted_at is null
      and u.deleted_at is null
  );
$$;

revoke all on function private.is_verified_business(uuid) from public;
grant execute on function private.is_verified_business(uuid) to authenticated, service_role;

-- ---------------------------------------------------------------------
-- RPCs
-- ---------------------------------------------------------------------

-- requestVerification(): unverified/rejected -> pending
create or replace function public.request_business_verification()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_active_user();
begin
  update public.businesses
     set verification_status = 'pending'
   where user_id = v_uid
     and deleted_at is null
     and verification_status in ('unverified', 'rejected');
  if not found then
    raise exception 'Nothing to verify: no business profile, or it is already pending, verified or suspended'
      using errcode = 'P0001';
  end if;
end;
$$;

-- Admin decision. The note is stored in status_history for the owner.
create or replace function public.admin_set_business_verification(
  p_business_id uuid,
  p_status public.verification_status,
  p_note text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := private.require_admin();
begin
  if p_status = 'pending' then
    raise exception 'Pick a decision: verified, rejected, suspended or unverified' using errcode = '22023';
  end if;
  perform set_config('app.status_note', coalesce(left(p_note, 1000), ''), true);
  update public.businesses
     set verification_status = p_status,
         verified_at = case when p_status = 'verified' then now() end,
         verified_by = case when p_status = 'verified' then v_admin end
   where user_id = p_business_id;
  if not found then
    raise exception 'Business not found' using errcode = 'P0002';
  end if;
end;
$$;

revoke all on function public.request_business_verification() from public, anon;
revoke all on function public.admin_set_business_verification(uuid, public.verification_status, text) from public, anon;
grant execute on function public.request_business_verification() to authenticated;
grant execute on function public.admin_set_business_verification(uuid, public.verification_status, text) to authenticated;

-- ---------------------------------------------------------------------
-- Row level security + column grants
-- ---------------------------------------------------------------------
alter table public.businesses enable row level security;

-- Company name, field and badge are public to signed-in users.
create policy businesses_select
  on public.businesses for select
  to authenticated
  using (true);

create policy businesses_insert_own
  on public.businesses for insert
  to authenticated
  with check (
    user_id = (select auth.uid())
    and verification_status = 'unverified'
    and (select private.is_active_user())
  );

create policy businesses_update_own
  on public.businesses for update
  to authenticated
  using (user_id = (select auth.uid()) and deleted_at is null)
  with check (user_id = (select auth.uid()) and deleted_at is null);

revoke all on table public.businesses from anon, authenticated;
grant select on table public.businesses to authenticated;
grant insert (company_name, cr_number, specialized_field) on table public.businesses to authenticated;
grant update (company_name, cr_number, specialized_field) on table public.businesses to authenticated;
;
