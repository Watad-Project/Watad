-- =====================================================================
-- 01_users.sql  ·  public profile for every signed-up user
--
-- Review fixes here:
--   #1  role can't be self-assigned: clients may only update full_name
--       and avatar_path (column grants), and role never comes from
--       sign-up metadata.
--   #8  accounts are closed by anonymising, never hard-deleted, so
--       orders, payments, reports and messages keep their history.
--   #13 created_at / updated_at.
--   #14 avatars are a path inside our own "avatars" bucket, not a URL.
--   design note: users.role is only 'user' | 'admin'. Being a business
--       is decided by the businesses table alone.
-- =====================================================================

create table public.users (
  -- Same value as auth.users.id. There is deliberately no foreign key
  -- to auth.users: deleting a login must leave an anonymised profile
  -- behind instead of cascading through financial history.
  id          uuid primary key,
  full_name   text not null default ''
              check (char_length(full_name) <= 100),
  avatar_path text
              check (
                avatar_path is null
                or (avatar_path ~ '^[0-9a-f-]{36}/[A-Za-z0-9_-][A-Za-z0-9._-]{0,127}$'
                    and split_part(avatar_path, '/', 1) = id::text)
              ),
  role        public.app_role not null default 'user',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

comment on table public.users is
  'Public profile, one row per auth user. Created by trigger at sign-up; anonymised (never deleted) when the account closes.';
comment on column public.users.avatar_path is
  'Object path in the "avatars" storage bucket, always "<user id>/<file name>". Never an external URL.';
comment on column public.users.role is
  'Staff permissions only. Changed with admin_set_user_role(); clients cannot write it.';

create trigger users_set_updated_at
  before update on public.users
  for each row execute function private.set_updated_at();

-- ---------------------------------------------------------------------
-- Access helpers used by policies everywhere
-- ---------------------------------------------------------------------

-- SECURITY DEFINER so they can read users.role without going through
-- RLS; search_path is pinned so they can't be hijacked.
create or replace function private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.users u
    where u.id = (select auth.uid())
      and u.role = 'admin'
      and u.deleted_at is null
  );
$$;

create or replace function private.is_active_user()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.users u
    where u.id = (select auth.uid())
      and u.deleted_at is null
  );
$$;

-- For RPCs: the caller's id, or an error if not signed in / closed.
create or replace function private.require_active_user()
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'Not signed in' using errcode = '28000';
  end if;
  if not exists (select 1 from public.users where id = v_uid and deleted_at is null) then
    raise exception 'This account is closed or has no profile' using errcode = '42501';
  end if;
  return v_uid;
end;
$$;

create or replace function private.require_admin()
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_active_user();
begin
  if not private.is_admin() then
    raise exception 'Admins only' using errcode = '42501';
  end if;
  return v_uid;
end;
$$;

revoke all on function private.is_admin() from public;
revoke all on function private.is_active_user() from public;
revoke all on function private.require_active_user() from public;
revoke all on function private.require_admin() from public;
grant execute on function private.is_admin() to authenticated, service_role;
grant execute on function private.is_active_user() to authenticated, service_role;

-- ---------------------------------------------------------------------
-- Profile rows follow auth.users
-- ---------------------------------------------------------------------

-- Only the display name is taken from sign-up metadata. Role is NEVER
-- read from raw_user_meta_data: the client controls that field.
create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.users (id, full_name)
  values (new.id, left(btrim(coalesce(new.raw_user_meta_data ->> 'full_name', '')), 100))
  on conflict (id) do nothing;
  return new;
end;
$$;

revoke all on function private.handle_new_user() from public;

create trigger watad_on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();

-- Anyone who signed up before this migration gets a profile too.
insert into public.users (id, full_name)
select au.id, left(btrim(coalesce(au.raw_user_meta_data ->> 'full_name', '')), 100)
from auth.users au
on conflict (id) do nothing;

-- Close an account: end open obligations, remove personal data, keep
-- the history other people rely on. p_force skips the "you still have
-- work in progress" checks (used when an admin deletes the login).
-- plpgsql resolves the tables below at run time, so it can reference
-- tables created by later files.
create or replace function private.close_account(p_user_id uuid, p_force boolean default false)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order_id uuid;
begin
  if not p_force then
    if exists (
      select 1 from public.orders o
      where (o.buyer_id = p_user_id or o.seller_id = p_user_id)
        and o.status in ('paid', 'shipped')
    ) then
      raise exception 'Finish or refund your active orders before closing the account' using errcode = 'P0001';
    end if;
    if exists (
      select 1 from public.projects p
      where (p.owner_id = p_user_id or p.taker_id = p_user_id)
        and p.status = 'in_progress'
    ) then
      raise exception 'Finish your projects in progress before closing the account' using errcode = 'P0001';
    end if;
  end if;

  perform set_config('app.status_note', 'account closed', true);

  -- Unpaid orders: cancel them and put the stock back.
  for v_order_id in
    select o.id from public.orders o
    where o.status = 'pending_payment'
      and (o.buyer_id = p_user_id or o.seller_id = p_user_id)
    for update
  loop
    perform private.cancel_order_internal(v_order_id, 'account closed');
  end loop;

  -- Offers this user made are withdrawn.
  update public.project_offers
     set status = 'withdrawn', decided_at = now()
   where provider_id = p_user_id and status = 'pending';

  -- Their draft/open projects are cancelled and pending offers rejected.
  update public.project_offers o
     set status = 'rejected', decided_at = now()
    from public.projects p
   where p.id = o.project_id
     and p.owner_id = p_user_id
     and p.status in ('draft', 'open')
     and o.status = 'pending';
  update public.projects
     set status = 'cancelled'
   where owner_id = p_user_id and status in ('draft', 'open');

  -- Listings come off the market (rows stay for order history).
  update public.marketplace_items
     set is_active = false, deleted_at = coalesce(deleted_at, now())
   where seller_id = p_user_id;

  -- Saved addresses are personal data: delete them. Projects keep
  -- their city/district copy; a site still in progress keeps its row.
  delete from public.addresses a
   where a.owner_id = p_user_id
     and not exists (
       select 1 from public.projects p
       where p.address_id = a.id and p.status = 'in_progress'
     );

  update public.businesses
     set deleted_at = coalesce(deleted_at, now())
   where user_id = p_user_id;

  -- Leave every chat; the others keep the history ("Deleted user").
  delete from public.chat_members where user_id = p_user_id;

  update public.users
     set full_name = 'Deleted user',
         avatar_path = null,
         deleted_at = coalesce(deleted_at, now())
   where id = p_user_id;
end;
$$;

revoke all on function private.close_account(uuid, boolean) from public;

-- Deleting a login from the dashboard or the admin API anonymises the
-- profile instead of failing on (or cascading through) history.
create or replace function private.handle_deleted_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.close_account(old.id, true);
  return old;
end;
$$;

revoke all on function private.handle_deleted_user() from public;

create trigger watad_on_auth_user_deleted
  after delete on auth.users
  for each row execute function private.handle_deleted_user();

-- ---------------------------------------------------------------------
-- RPCs
-- ---------------------------------------------------------------------

-- deleteAccount(): supabase.rpc('delete_my_account')
-- Afterwards the app signs out; a server function may also delete the
-- login with the admin API (the trigger above handles that safely).
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_active_user();
begin
  perform private.close_account(v_uid, false);
end;
$$;

-- Admins grant or remove staff rights. The first admin is set once by
-- hand in the SQL editor: update public.users set role = 'admin' where id = '...';
create or replace function public.admin_set_user_role(p_user_id uuid, p_role public.app_role)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := private.require_admin();
begin
  if p_user_id = v_admin and p_role <> 'admin' then
    raise exception 'You cannot remove your own admin role' using errcode = 'P0001';
  end if;
  update public.users set role = p_role
   where id = p_user_id and deleted_at is null;
  if not found then
    raise exception 'User not found' using errcode = 'P0002';
  end if;
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
revoke all on function public.admin_set_user_role(uuid, public.app_role) from public, anon;
grant execute on function public.delete_my_account() to authenticated;
grant execute on function public.admin_set_user_role(uuid, public.app_role) to authenticated;

-- ---------------------------------------------------------------------
-- Row level security + column grants
-- ---------------------------------------------------------------------
alter table public.users enable row level security;

-- Names and avatars are visible to signed-in users (no email or phone
-- lives in this table; those stay in auth.users).
create policy users_select
  on public.users for select
  to authenticated
  using (true);

create policy users_update_own
  on public.users for update
  to authenticated
  using (id = (select auth.uid()) and deleted_at is null)
  with check (id = (select auth.uid()) and deleted_at is null);

revoke all on table public.users from anon, authenticated;
grant select on table public.users to authenticated;
grant update (full_name, avatar_path) on table public.users to authenticated;

-- ---------------------------------------------------------------------
-- Avatar storage (review fix #14)
-- ---------------------------------------------------------------------
-- Public read (no listing), 2 MB images only, and each user can only
-- write inside the folder named after their own id.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 2097152, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

create policy watad_avatars_select_own
  on storage.objects for select
  to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy watad_avatars_insert_own
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy watad_avatars_update_own
  on storage.objects for update
  to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy watad_avatars_delete_own
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
;
