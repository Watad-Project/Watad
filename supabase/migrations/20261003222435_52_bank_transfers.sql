-- =====================================================================
-- 52_bank_transfers.sql  ·  bank transfer receipts (new table + bucket)
--
-- Feature: a client can pay a stage by bank transfer. The client sends
-- the money to the contractor, uploads the receipt and submits it; the
-- contractor checks the account and confirms or rejects it.
--   - Private storage bucket "bank-transfer-receipts": PDF, JPEG or PNG,
--     up to 10 MB, path "<payment id>/<file>". Only the project owner
--     uploads, while the stage is unpaid and no other payment is in
--     flight; the owner, the contractor and admins can read. Files can't
--     be replaced or deleted.
--   - bank_transfers: one row per submitted receipt and its outcome. At
--     most one per stage waits for the contractor.
--   - submit_bank_transfer()   client:     stage pending/failed -> processing
--   - confirm_bank_transfer()  contractor: stage -> paid
--   - reject_bank_transfer()   contractor, with a reason: stage -> pending
--     (the client can upload a new receipt or pay another way)
--     An admin can confirm or reject on the contractor's behalf; the
--     client never can.
--   - A stage cancelled while its transfer waits (an admin cancelled the
--     project) closes the transfer as 'cancelled'; money already sent is
--     returned outside the app.
-- Every stage change lands in status_history with a note.
-- =====================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('bank-transfer-receipts', 'bank-transfer-receipts', false, 10485760,
        array['application/pdf', 'image/jpeg', 'image/png'])
on conflict (id) do nothing;

create type public.bank_transfer_status as enum ('pending', 'confirmed', 'rejected', 'cancelled');

create table public.bank_transfers (
  id               uuid primary key default gen_random_uuid(),
  payment_id       uuid not null references public.project_payments (id) on delete restrict,
  -- Object path in the "bank-transfer-receipts" bucket: "<payment id>/<file>".
  storage_path     text not null unique
                   check (storage_path ~ '^[0-9a-f-]{36}/[A-Za-z0-9_-][A-Za-z0-9._-]{0,199}$'
                          and split_part(storage_path, '/', 1) = payment_id::text),
  bank_reference   text check (bank_reference is null or char_length(bank_reference) between 1 and 100),
  status           public.bank_transfer_status not null default 'pending',
  submitted_by     uuid not null references public.users (id) on delete restrict,
  decided_by       uuid references public.users (id) on delete restrict,
  decided_at       timestamptz,
  rejection_reason text check (rejection_reason is null or char_length(rejection_reason) between 1 and 500),
  created_at       timestamptz not null default now(),
  constraint bank_transfers_decided check ((status = 'pending') = (decided_at is null)),
  constraint bank_transfers_reason check ((status = 'rejected') = (rejection_reason is not null))
);

comment on table public.bank_transfers is
  'Bank transfer receipts for project stages. Read-only for clients; written by submit_bank_transfer(), confirm_bank_transfer() and reject_bank_transfer().';

comment on table public.project_payments is
  'Read-only for clients. Stages come from add_payment_stage(); status changes through the payment webhook or the bank transfer RPCs.';

-- One receipt per stage waits for the contractor at a time.
create unique index bank_transfers_one_pending_idx on public.bank_transfers (payment_id) where status = 'pending';
create index bank_transfers_payment_id_idx on public.bank_transfers (payment_id, created_at desc);
create index bank_transfers_submitted_by_idx on public.bank_transfers (submitted_by);
create index bank_transfers_decided_by_idx on public.bank_transfers (decided_by);

alter table public.bank_transfers enable row level security;

create policy bank_transfers_select
  on public.bank_transfers for select
  to authenticated
  using (
    (select private.is_admin())
    or exists (
      select 1
      from public.project_payments pp
      join public.projects p on p.id = pp.project_id
      where pp.id = bank_transfers.payment_id
        and (p.owner_id = (select auth.uid()) or p.taker_id = (select auth.uid()))
    )
  );

revoke all on table public.bank_transfers from anon, authenticated;
grant select on table public.bank_transfers to authenticated;

-- ---------------------------------------------------------------------
-- Storage access
-- ---------------------------------------------------------------------

-- "<payment id>/<file>" -> the payment id; null for any other shape.
create or replace function private.bank_transfer_payment_id(p_object_name text)
returns uuid
language sql
immutable
set search_path = ''
as $$
  select case
    when p_object_name ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[A-Za-z0-9_-][A-Za-z0-9._-]{0,199}$'
    then split_part(p_object_name, '/', 1)::uuid
  end;
$$;

-- Upload: the project owner, while the stage is unpaid and no other
-- payment is in flight.
create or replace function private.can_upload_bank_transfer(p_object_name text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.is_active_user()
     and exists (
       select 1
       from public.project_payments pp
       join public.projects p on p.id = pp.project_id
       where pp.id = private.bank_transfer_payment_id(p_object_name)
         and p.owner_id = (select auth.uid())
         and p.status in ('in_progress', 'completed')
         and pp.status in ('pending', 'failed')
         and pp.gateway_reference is null
     );
$$;

-- Read: the project owner, the contractor and admins.
create or replace function private.can_read_bank_transfer(p_object_name text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.is_admin()
      or exists (
        select 1
        from public.project_payments pp
        join public.projects p on p.id = pp.project_id
        where pp.id = private.bank_transfer_payment_id(p_object_name)
          and (p.owner_id = (select auth.uid()) or p.taker_id = (select auth.uid()))
      );
$$;

revoke all on function private.bank_transfer_payment_id(text) from public;
revoke all on function private.can_upload_bank_transfer(text) from public;
revoke all on function private.can_read_bank_transfer(text) from public;
grant execute on function private.can_upload_bank_transfer(text) to authenticated;
grant execute on function private.can_read_bank_transfer(text) to authenticated;

-- No update or delete policies: receipts can't be replaced or removed.
create policy watad_bank_receipts_insert_owner
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'bank-transfer-receipts'
    and private.can_upload_bank_transfer(name)
  );

create policy watad_bank_receipts_select
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'bank-transfer-receipts'
    and private.can_read_bank_transfer(name)
  );

-- ---------------------------------------------------------------------
-- RPCs
-- ---------------------------------------------------------------------

-- Client: submit an uploaded receipt for a stage.
create or replace function public.submit_bank_transfer(
  p_payment_id uuid,
  p_storage_path text,
  p_bank_reference text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid       uuid := private.require_active_user();
  v_reference text := nullif(btrim(p_bank_reference), '');
  v_project   public.projects;
  v_payment   public.project_payments;
  v_id        uuid;
begin
  -- Lock order as in set_project_status(): project, then payment.
  select p.* into v_project
    from public.projects p
    join public.project_payments pp on pp.project_id = p.id
   where pp.id = p_payment_id
     for update of p;
  if not found or v_project.owner_id <> v_uid then
    raise exception 'Payment not found' using errcode = 'P0002';
  end if;
  select * into v_payment from public.project_payments where id = p_payment_id for update;

  if v_project.status not in ('in_progress', 'completed') then
    raise exception 'This project can''t take payments' using errcode = 'P0001';
  end if;
  if v_payment.status not in ('pending', 'failed') or v_payment.gateway_reference is not null then
    raise exception 'This stage is already paid, cancelled or being paid' using errcode = 'P0001';
  end if;
  if char_length(v_reference) > 100 then
    raise exception 'The bank reference can be at most 100 characters' using errcode = '22023';
  end if;
  if p_storage_path is null
     or split_part(p_storage_path, '/', 1) <> p_payment_id::text
     or not exists (
       select 1 from storage.objects o
        where o.bucket_id = 'bank-transfer-receipts'
          and o.name = p_storage_path
          and coalesce(o.owner_id, o.owner::text) = v_uid::text)
  then
    raise exception 'Upload the receipt to bank-transfer-receipts/%/<file> first', p_payment_id
      using errcode = 'P0001';
  end if;
  if exists (select 1 from public.bank_transfers where storage_path = p_storage_path) then
    raise exception 'That receipt was already submitted; upload a new file' using errcode = 'P0001';
  end if;

  perform set_config('app.status_note', 'bank transfer submitted', true);

  insert into public.bank_transfers (payment_id, storage_path, bank_reference, submitted_by)
  values (p_payment_id, p_storage_path, v_reference, v_uid)
  returning id into v_id;

  update public.project_payments
     set status = 'processing', method = 'bank_transfer'
   where id = p_payment_id;

  return v_id;
end;
$$;

-- Contractor (or an admin on their behalf): confirm or reject a receipt.
create or replace function private.decide_bank_transfer(p_transfer_id uuid, p_confirm boolean, p_reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid        uuid := private.require_active_user();
  v_admin      boolean := private.is_admin();
  v_reason     text := nullif(btrim(p_reason), '');
  v_payment_id uuid;
  v_project_id uuid;
  v_project    public.projects;
  v_payment    public.project_payments;
  v_transfer   public.bank_transfers;
begin
  select bt.payment_id, pp.project_id into v_payment_id, v_project_id
    from public.bank_transfers bt
    join public.project_payments pp on pp.id = bt.payment_id
   where bt.id = p_transfer_id;
  if not found then
    raise exception 'Transfer not found' using errcode = 'P0002';
  end if;

  -- Lock order as in set_project_status(): project, payment, transfer.
  select * into v_project from public.projects where id = v_project_id for update;
  select * into v_payment from public.project_payments where id = v_payment_id for update;
  select * into v_transfer from public.bank_transfers where id = p_transfer_id for update;

  if v_uid <> v_project.owner_id and v_uid is distinct from v_project.taker_id and not v_admin then
    raise exception 'Transfer not found' using errcode = 'P0002';
  end if;
  if v_uid = v_project.owner_id then
    raise exception 'Only the contractor can confirm or reject this transfer' using errcode = 'P0001';
  end if;
  if v_transfer.status <> 'pending' then
    raise exception 'This transfer is already %', v_transfer.status using errcode = 'P0001';
  end if;
  if v_payment.status <> 'processing' or v_payment.method is distinct from 'bank_transfer' then
    raise exception 'This stage is no longer waiting for a transfer' using errcode = 'P0001';
  end if;
  if not p_confirm and (v_reason is null or char_length(v_reason) > 500) then
    raise exception 'Give a reason of up to 500 characters' using errcode = '22023';
  end if;

  perform set_config('app.status_note',
    case when p_confirm then 'bank transfer confirmed'
         else 'bank transfer rejected: ' || v_reason end
    || case when v_uid is distinct from v_project.taker_id then ' (by admin)' else '' end,
    true);

  update public.bank_transfers
     set status = case when p_confirm then 'confirmed' else 'rejected' end::public.bank_transfer_status,
         rejection_reason = case when p_confirm then null else v_reason end,
         decided_by = v_uid,
         decided_at = now()
   where id = p_transfer_id;

  if p_confirm then
    update public.project_payments
       set status = 'paid', paid_at = now()
     where id = v_payment_id;
  else
    update public.project_payments
       set status = 'pending', method = null
     where id = v_payment_id;
  end if;
end;
$$;

revoke all on function private.decide_bank_transfer(uuid, boolean, text) from public;

create or replace function public.confirm_bank_transfer(p_transfer_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.decide_bank_transfer(p_transfer_id, true, null);
end;
$$;

create or replace function public.reject_bank_transfer(p_transfer_id uuid, p_reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.decide_bank_transfer(p_transfer_id, false, p_reason);
end;
$$;

revoke all on function public.submit_bank_transfer(uuid, text, text) from public, anon;
revoke all on function public.confirm_bank_transfer(uuid) from public, anon;
revoke all on function public.reject_bank_transfer(uuid, text) from public, anon;
grant execute on function public.submit_bank_transfer(uuid, text, text) to authenticated;
grant execute on function public.confirm_bank_transfer(uuid) to authenticated;
grant execute on function public.reject_bank_transfer(uuid, text) to authenticated;

-- ---------------------------------------------------------------------
-- A stage cancelled while its transfer waits closes that transfer.
-- ---------------------------------------------------------------------
create or replace function private.close_pending_bank_transfers()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.bank_transfers
     set status = 'cancelled',
         decided_by = (select u.id from public.users u where u.id = auth.uid()),
         decided_at = now()
   where payment_id = new.id
     and status = 'pending';
  return null;
end;
$$;

revoke all on function private.close_pending_bank_transfers() from public;

create trigger project_payments_close_bank_transfers
  after update of status on public.project_payments
  for each row
  when (new.status = 'cancelled' and old.status is distinct from new.status)
  execute function private.close_pending_bank_transfers();
;
