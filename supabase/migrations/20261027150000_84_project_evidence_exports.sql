-- =====================================================================
-- 84_project_evidence_exports.sql  ·  signed project evidence (GRA-73)
--
-- The backend of the project evidence PDF (GRA-72). The Edge Function
-- project-evidence collects a project's evidence from here and from the
-- blockchain, signs it, and keeps a record of every export so a PDF can be
-- checked later.
--   1. project_evidence_exports: one row per export (project, who, when,
--      the SHA-256 fingerprint, the Ed25519 signature and its key id).
--      Inserted only by the function; read through v_project_evidence_exports
--      by the project's owner, its taker and admins.
--   2. project_evidence_collect(): checks the caller (owner, taker or
--      admin) and returns the project's details, the record the sync sends
--      (blockchain_sync.snapshot()) and its sync state, from the closed
--      blockchain_sync schema.
--   3. project_evidence_record(): saves an export.
-- Both functions are for the Edge Function only: they need the shared
-- secret project_evidence_secret (Vault; the function's
-- PROJECT_EVIDENCE_SECRET) and are granted to service_role only, like
-- blockchain_sync_snapshot(). The app never calls them.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. The exports
-- ---------------------------------------------------------------------

create table public.project_evidence_exports (
  id          uuid primary key,
  project_id  uuid not null references public.projects (id) on delete restrict,
  exported_by uuid not null references public.users (id) on delete restrict,
  -- The time inside the signed evidence.
  exported_at timestamptz not null,
  -- SHA-256 of the evidence's canonical JSON, lower-case hex.
  fingerprint text not null check (fingerprint ~ '^[0-9a-f]{64}$'),
  -- Ed25519 signature of the same canonical JSON, base64.
  signature   text not null check (char_length(signature) between 1 and 200),
  key_id      text not null check (char_length(key_id) between 1 and 100)
);

comment on table public.project_evidence_exports is
  'Every signed export of a project''s evidence (the PDF of GRA-72). Inserted only by the project-evidence Edge Function, through project_evidence_record().';

create index project_evidence_exports_project_idx
  on public.project_evidence_exports (project_id, exported_at desc);

alter table public.project_evidence_exports enable row level security;

-- The project's owner, its taker and admins.
create policy project_evidence_exports_select
  on public.project_evidence_exports for select
  to authenticated
  using (
    exists (
      select 1 from public.projects p
       where p.id = project_evidence_exports.project_id
         and (p.owner_id = (select auth.uid()) or p.taker_id = (select auth.uid()))
    )
    or (select private.is_admin())
  );

revoke all on table public.project_evidence_exports from public, anon, authenticated;
grant select on table public.project_evidence_exports to authenticated;

create view public.v_project_evidence_exports
with (security_invoker = true) as
select e.id,
       e.project_id,
       e.exported_by,
       u.full_name as exported_by_name,
       e.exported_at,
       e.fingerprint,
       e.signature,
       e.key_id
  from public.project_evidence_exports e
  join public.users u on u.id = e.exported_by;

comment on view public.v_project_evidence_exports is
  'The signed evidence exports of a project, for its owner, its taker and admins; check a PDF''s export id and fingerprint against it.';

revoke all on public.v_project_evidence_exports from public, anon, authenticated;
grant select on public.v_project_evidence_exports to authenticated;

-- ---------------------------------------------------------------------
-- 2. The shared secret
-- ---------------------------------------------------------------------

do $$
begin
  if not exists (select 1 from vault.secrets where name = 'project_evidence_secret') then
    perform vault.create_secret(
      replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''),
      'project_evidence_secret',
      'Shared secret between the database and the project-evidence Edge Function');
  end if;
end $$;

create or replace function private.evidence_check_secret(p_secret text)
returns boolean
language sql
stable
security definer
set search_path to ''
as $$
  select coalesce((select s.decrypted_secret = p_secret
                     from vault.decrypted_secrets s
                    where s.name = 'project_evidence_secret'), false);
$$;

revoke all on function private.evidence_check_secret(text) from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- 3. Collect a project's evidence
-- ---------------------------------------------------------------------

-- p_user_id is the caller, as the Edge Function read it from their
-- session. Errors (message, code), which the function turns into answers:
--   forbidden 42501           wrong secret
--   project_not_found P0002   no such project, or the caller's account is closed
--   not_allowed 42501         not the owner, the taker or an admin
--   not_on_chain 40001        no accepted offer, so nothing is on the chain
create function public.project_evidence_collect(
  p_secret     text,
  p_user_id    uuid,
  p_project_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path to ''
as $$
declare
  v_project public.projects;
  v_role    text;
  v_result  jsonb;
begin
  if not private.evidence_check_secret(p_secret) then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  select * into v_project from public.projects where id = p_project_id;
  if not found
     or not exists (select 1 from public.users u
                     where u.id = p_user_id and u.deleted_at is null) then
    raise exception 'project_not_found' using errcode = 'P0002';
  end if;

  v_role := case
    when v_project.owner_id = p_user_id then 'owner'
    when v_project.taker_id = p_user_id then 'taker'
    when exists (select 1 from public.users u
                  where u.id = p_user_id and u.role = 'admin'
                    and u.deleted_at is null) then 'admin'
  end;
  if v_role is null then
    raise exception 'not_allowed' using errcode = '42501';
  end if;

  if v_project.taker_id is null
     or not exists (select 1 from public.project_offers o
                     where o.project_id = p_project_id and o.status = 'accepted') then
    raise exception 'not_on_chain' using errcode = '40001';
  end if;

  select jsonb_build_object(
    'caller_role', v_role,
    'project', jsonb_build_object(
      'id',           v_project.id,
      'title',        v_project.title,
      'description',  v_project.description,
      'status',       v_project.status,
      'city',         v_project.city,
      'district',     v_project.district,
      'created_at',   v_project.created_at,
      -- When it first became in_progress (the status history).
      'started_at',   (select min(h.changed_at) from public.status_history h
                        where h.project_id = v_project.id
                          and h.new_status = 'in_progress'),
      'completed_at', v_project.completed_at),
    'client', jsonb_build_object(
      'id',   ou.id,
      'name', nullif(btrim(ou.full_name), '')),
    'contractor', jsonb_build_object(
      'id',           b.user_id,
      'company_name', b.company_name,
      'cr_number',    b.cr_number),
    'agreed_price', o.amount,
    'currency',     'SAR',
    'tasks', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id',          t.id,
               'title',       t.title,
               'description', t.description,
               'status',      t.status,
               'amount',      t.amount,
               'start_date',  t.start_date,
               'finish_date', t.finish_date,
               'created_at',  t.created_at,
               'last_update', (
                 select jsonb_build_object(
                          'proposed_state',   u.proposed_state,
                          'note',             u.note,
                          'decision',         u.decision,
                          'rejection_reason', u.rejection_reason,
                          'created_at',       u.created_at,
                          'decided_at',       u.decided_at)
                   from public.project_task_updates u
                  where u.task_id = t.id
                  order by u.created_at desc
                  limit 1))
             order by t.created_at, t.id)
        from public.project_tasks t
       where t.project_id = v_project.id), '[]'::jsonb),
    'payments', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id',           x.id,
               'stage_number', x.stage_number,
               'description',  x.description,
               'amount',       x.amount,
               'currency',     x.currency,
               'status',       x.status,
               'method',       x.method,
               'paid_at',      x.paid_at,
               'refunded_at',  x.refunded_at,
               'bank_transfer', (
                 select jsonb_build_object(
                          'status',           bt.status,
                          'created_at',       bt.created_at,
                          'decided_at',       bt.decided_at,
                          'rejection_reason', bt.rejection_reason)
                   from public.bank_transfers bt
                  where bt.payment_id = x.id
                  order by bt.created_at desc
                  limit 1))
             order by x.stage_number, x.created_at)
        from public.project_payments x
       where x.project_id = v_project.id), '[]'::jsonb),
    -- What blockchain-sync sends to the chain, to compare with its copy.
    'snapshot', blockchain_sync.snapshot(v_project.id),
    'sync', (
      select jsonb_build_object(
               'status', case
                           when s.dirty and s.last_outcome = 'retry' then 'retrying'
                           when s.dirty then 'waiting'
                           when s.last_outcome = 'failed' then 'failed'
                           when s.last_outcome = 'ok' then 'synced'
                           else 'waiting'
                         end,
               'version',         s.version,
               'last_outcome',    s.last_outcome,
               'last_attempt_at', s.last_attempt_at,
               'synced_at',       s.synced_at)
        from blockchain_sync.state s
       where s.project_id = v_project.id))
    into v_result
    from public.users ou
    left join public.businesses b on b.user_id = v_project.taker_id
    join lateral (
      select po.amount from public.project_offers po
       where po.project_id = v_project.id and po.status = 'accepted'
       order by po.decided_at desc nulls last
       limit 1
    ) o on true
   where ou.id = v_project.owner_id;

  return v_result;
end;
$$;

revoke all on function public.project_evidence_collect(text, uuid, uuid) from public, anon, authenticated;
grant execute on function public.project_evidence_collect(text, uuid, uuid) to service_role;

-- ---------------------------------------------------------------------
-- 4. Save an export
-- ---------------------------------------------------------------------

-- The Edge Function picks p_export_id and p_exported_at before signing,
-- so the signed evidence carries its own export id and time.
create function public.project_evidence_record(
  p_secret      text,
  p_export_id   uuid,
  p_exported_at timestamptz,
  p_user_id     uuid,
  p_project_id  uuid,
  p_fingerprint text,
  p_signature   text,
  p_key_id      text
)
returns void
language plpgsql
security definer
set search_path to ''
as $$
begin
  if not private.evidence_check_secret(p_secret) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  insert into public.project_evidence_exports
    (id, project_id, exported_by, exported_at, fingerprint, signature, key_id)
  values
    (p_export_id, p_project_id, p_user_id, p_exported_at, p_fingerprint, p_signature, p_key_id);
end;
$$;

revoke all on function public.project_evidence_record(text, uuid, timestamptz, uuid, uuid, text, text, text) from public, anon, authenticated;
grant execute on function public.project_evidence_record(text, uuid, timestamptz, uuid, uuid, text, text, text) to service_role;
