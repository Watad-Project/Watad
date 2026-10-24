-- =====================================================================
-- 78_contractor_bank_details.sql  ·  where a client sends a bank transfer
--
-- Feature (GRA-48, for the bank transfer screen GRA-52): a contractor
-- saves the bank account that clients pay stages into, and the client
-- sees it on the transfer screen before sending the money.
--
--   1. contractor_bank_details: one row per contractor (a user with a
--      businesses row): beneficiary (account holder) name, bank name
--      and IBAN. The contractor writes it directly (ARCHITECTURE.md
--      §3a): RLS limits writes to their own row, only while they have a
--      business and their account is active (not closed or suspended),
--      and column grants limit them to the three fields. No delete: the
--      details are edited, not removed.
--   2. Saudi IBANs only (the app works in SAR). Spaces and dashes are
--      removed, Arabic-Indic digits become 0-9 and letters are
--      upper-cased; then the shape (SA + 22 characters) and the ISO
--      13616 check digits are verified, so a typo is caught before a
--      client sends money to it. Invalid input raises 22023
--      (ValidationFailure, APP_ARCHITECTURE.md §13).
--   3. Who reads it: the contractor; the owner of a project the
--      contractor works on, while that project is in progress or
--      completed (the projects that take bank transfers, as in
--      private.can_upload_bank_transfer); and admins, who confirm or
--      reject transfers on the contractor's behalf.
--   4. Closing the account deletes the row, like user_identity
--      (migration 56).
--   5. v_contractor_bank_details: what the app reads. It runs with the
--      caller's rights (security_invoker), so the rules above apply.
--
-- App (client, transfer screen; contractor_id is v_my_projects.taker_id):
--   supabase.from('v_contractor_bank_details').select()
--     .eq('contractor_id', takerId).maybeSingle()
-- App (contractor, own details):
--   supabase.from('v_contractor_bank_details').select()
--     .eq('is_mine', true).maybeSingle()
--   Save: insert {beneficiary_name, bank_name, iban} into
--   contractor_bank_details the first time, then update the same three.
--   user_id comes from the session.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Table
-- ---------------------------------------------------------------------
create table public.contractor_bank_details (
  user_id          uuid primary key default auth.uid()
                   references public.businesses (user_id) on delete cascade,
  beneficiary_name text not null
                   check (char_length(btrim(beneficiary_name)) between 2 and 150),
  bank_name        text not null
                   check (char_length(btrim(bank_name)) between 2 and 100),
  -- Saudi IBAN: SA, 2 check digits, a 2-digit bank code and an
  -- 18-character account number. Stored without spaces, in upper case.
  iban             text not null
                   check (iban ~ '^SA[0-9]{4}[0-9A-Z]{18}$'),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

comment on table public.contractor_bank_details is
  'The bank account a contractor receives bank transfers on. The contractor writes their own row; readable by them, by the owners of their in-progress or completed projects, and by admins. Deleted when the account is closed.';

create trigger contractor_bank_details_set_updated_at
  before update on public.contractor_bank_details
  for each row execute function private.set_updated_at();

-- ---------------------------------------------------------------------
-- 2. Clean up and validate before saving
-- ---------------------------------------------------------------------
create or replace function private.contractor_bank_details_prepare()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_rearranged text;
  v_char       text;
  v_remainder  integer := 0;
  i            integer;
begin
  new.beneficiary_name := btrim(new.beneficiary_name);
  new.bank_name        := btrim(new.bank_name);
  new.iban := upper(regexp_replace(
                translate(coalesce(new.iban, ''),
                          '٠١٢٣٤٥٦٧٨٩۰۱۲۳۴۵۶۷۸۹', '01234567890123456789'),
                '[[:space:]-]', '', 'g'));

  if new.beneficiary_name is null or char_length(new.beneficiary_name) not between 2 and 150 then
    raise exception 'invalid_beneficiary_name' using errcode = '22023';
  end if;
  if new.bank_name is null or char_length(new.bank_name) not between 2 and 100 then
    raise exception 'invalid_bank_name' using errcode = '22023';
  end if;
  if new.iban !~ '^SA[0-9]{4}[0-9A-Z]{18}$' then
    raise exception 'invalid_iban' using errcode = '22023';
  end if;

  -- ISO 13616 check digits (mod 97): move the first 4 characters to the
  -- end and read letters as numbers (A = 10 ... Z = 35); the remainder
  -- of that number divided by 97 must be 1. It has about 30 digits, so
  -- the remainder is worked out one character at a time.
  v_rearranged := substr(new.iban, 5) || substr(new.iban, 1, 4);
  for i in 1 .. char_length(v_rearranged) loop
    v_char := substr(v_rearranged, i, 1);
    if v_char ~ '^[0-9]$' then
      v_remainder := (v_remainder * 10 + v_char::integer) % 97;
    else
      v_remainder := (v_remainder * 100 + ascii(v_char) - 55) % 97;
    end if;
  end loop;
  if v_remainder <> 1 then
    raise exception 'invalid_iban' using errcode = '22023';
  end if;

  -- The row always stays its contractor's.
  if tg_op = 'UPDATE' then
    new.user_id    := old.user_id;
    new.created_at := old.created_at;
  end if;

  return new;
end;
$$;

revoke all on function private.contractor_bank_details_prepare() from public;

create trigger contractor_bank_details_prepare
  before insert or update on public.contractor_bank_details
  for each row execute function private.contractor_bank_details_prepare();

-- ---------------------------------------------------------------------
-- 3. Row level security + column grants
-- ---------------------------------------------------------------------
alter table public.contractor_bank_details enable row level security;

-- The contractor, the owners of their projects that take bank
-- transfers, and admins.
create policy contractor_bank_details_select
  on public.contractor_bank_details for select
  to authenticated
  using (
    user_id = (select auth.uid())
    or (select private.is_admin())
    or exists (
      select 1
      from public.projects p
      where p.taker_id = contractor_bank_details.user_id
        and p.owner_id = (select auth.uid())
        and p.status in ('in_progress', 'completed')
    )
  );

-- Only for yourself, with a business, while your account is active.
create policy contractor_bank_details_insert_own
  on public.contractor_bank_details for insert
  to authenticated
  with check (
    user_id = (select auth.uid())
    and (select private.is_active_user())
    and exists (
      select 1
      from public.businesses b
      where b.user_id = (select auth.uid())
        and b.deleted_at is null
    )
  );

-- Only your own row, while your account is active. A suspended
-- contractor gets an error (42501), not a silent "nothing changed".
create policy contractor_bank_details_update_own
  on public.contractor_bank_details for update
  to authenticated
  using (user_id = (select auth.uid()))
  with check (
    user_id = (select auth.uid())
    and (select private.is_active_user())
  );

-- No delete policy or grant: the details are edited, not removed.
revoke all on table public.contractor_bank_details from public, anon, authenticated;
grant select on table public.contractor_bank_details to authenticated;
grant insert (beneficiary_name, bank_name, iban) on table public.contractor_bank_details to authenticated;
grant update (beneficiary_name, bank_name, iban) on table public.contractor_bank_details to authenticated;

-- ---------------------------------------------------------------------
-- 4. Closing the account deletes the bank details (as in migration 56)
-- ---------------------------------------------------------------------
create or replace function private.purge_bank_details_on_close()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.deleted_at is not null and old.deleted_at is null then
    delete from public.contractor_bank_details where user_id = new.id;
  end if;
  return new;
end;
$$;

revoke all on function private.purge_bank_details_on_close() from public;

create trigger watad_purge_bank_details_on_close
  after update of deleted_at on public.users
  for each row execute function private.purge_bank_details_on_close();

-- ---------------------------------------------------------------------
-- 5. View: what the app reads
-- ---------------------------------------------------------------------
create view public.v_contractor_bank_details
with (security_invoker = true)
as
select
  b.user_id as contractor_id,
  b.beneficiary_name,
  b.bank_name,
  b.iban,
  b.created_at,
  b.updated_at,
  coalesce(b.user_id = (select auth.uid()), false) as is_mine
from public.contractor_bank_details b;

comment on view public.v_contractor_bank_details is
  'A contractor''s bank account for bank transfers, visible to the contractor, the owners of their in-progress or completed projects, and admins.';

revoke all on table public.v_contractor_bank_details from public, anon, authenticated;
grant select on table public.v_contractor_bank_details to authenticated;
