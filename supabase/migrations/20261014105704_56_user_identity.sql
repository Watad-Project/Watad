-- 56_user_identity
-- Owner-only identity data (national ID / iqama, phone) for client sign-up (GRA-12).

create table public.user_identity (
  user_id     uuid primary key references public.users (id) on delete cascade,
  national_id text not null unique check (national_id ~ '^[12][0-9]{9}$'),
  phone       text not null check (phone ~ '^\+9665[0-9]{8}$'),
  created_at  timestamptz not null default now()
);

alter table public.user_identity enable row level security;

create policy user_identity_select_own on public.user_identity
  for select to authenticated
  using (user_id = (select auth.uid()));

-- No direct access; reads go through v_my_identity, writes through complete_client_profile().
revoke all on public.user_identity from public, anon, authenticated;

-- Remove identity data when an account is closed (soft delete).
create or replace function private.purge_identity_on_close()
returns trigger
language plpgsql
security definer
set search_path to ''
as $$
begin
  if new.deleted_at is not null and old.deleted_at is null then
    delete from public.user_identity where user_id = new.id;
  end if;
  return new;
end;
$$;

create trigger watad_purge_identity_on_close
  after update of deleted_at on public.users
  for each row execute function private.purge_identity_on_close();

-- Owner-only view.
create view public.v_my_identity as
  select i.user_id, i.national_id, i.phone, i.created_at
    from public.user_identity i
   where i.user_id = (select auth.uid());

revoke all on public.v_my_identity from public, anon, authenticated;
grant select on public.v_my_identity to authenticated;

-- Completes a client profile after email OTP verification.
-- Returns 'created', or 'already_registered' if this account already has identity data.
-- p_phone: 9 digits starting with 5 (stored as +9665XXXXXXXX).
create or replace function public.complete_client_profile(
  p_full_name   text,
  p_national_id text,
  p_phone       text
)
returns text
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_uid   uuid := private.require_active_user();
  v_name  text := btrim(coalesce(p_full_name, ''));
  v_nid   text := btrim(coalesce(p_national_id, ''));
  v_phone text := btrim(coalesce(p_phone, ''));
begin
  if exists (select 1 from public.user_identity where user_id = v_uid) then
    return 'already_registered';
  end if;

  if char_length(v_name) < 2 or char_length(v_name) > 100 then
    raise exception 'invalid_full_name' using errcode = 'P0001';
  end if;
  if v_nid !~ '^[12][0-9]{9}$' then
    raise exception 'invalid_national_id' using errcode = 'P0001';
  end if;
  if v_phone !~ '^5[0-9]{8}$' then
    raise exception 'invalid_phone' using errcode = 'P0001';
  end if;

  begin
    insert into public.user_identity (user_id, national_id, phone)
    values (v_uid, v_nid, '+966' || v_phone);
  exception when unique_violation then
    raise exception 'national_id_taken' using errcode = '23505';
  end;

  update public.users set full_name = v_name where id = v_uid;

  return 'created';
end;
$$;

revoke all on function public.complete_client_profile(text, text, text) from public, anon;
grant execute on function public.complete_client_profile(text, text, text) to authenticated;
