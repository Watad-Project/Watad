-- =====================================================================
-- 09_project_payments.sql  ·  staged payments for a project in progress
--
-- Review fixes here:
--   #2  clients can't write this table. The owner adds stages with
--       add_payment_stage() (never more than the agreed amount); only
--       the payment webhook (file 17) moves a stage to paid/failed/
--       refunded. gateway_reference + idempotency_key stop double pays.
--   #7  unique (project_id, stage_number); stage numbers are assigned
--       under a lock on the project row.
--   #8  ON DELETE RESTRICT.   #11 amount > 0.   #13 timestamps + history.
-- =====================================================================

create table public.project_payments (
  id                uuid primary key default gen_random_uuid(),
  project_id        uuid not null references public.projects (id) on delete restrict,
  stage_number      integer not null check (stage_number > 0),
  description       text check (description is null or char_length(description) <= 500),
  amount            numeric(12, 2) not null check (amount > 0),
  currency          char(3) not null default 'SAR' check (currency ~ '^[A-Z]{3}$'),
  status            public.payment_status not null default 'pending',
  idempotency_key   uuid not null default gen_random_uuid() unique,
  gateway_reference text unique
                    check (gateway_reference is null or char_length(gateway_reference) <= 200),
  paid_at           timestamptz,
  refunded_at       timestamptz,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  constraint project_payments_stage_unique unique (project_id, stage_number)
);

comment on table public.project_payments is
  'Read-only for clients. Stages come from add_payment_stage(); status changes only through the payment webhook.';

create trigger project_payments_set_updated_at
  before update on public.project_payments
  for each row execute function private.set_updated_at();

-- ---------------------------------------------------------------------
-- RPCs
-- ---------------------------------------------------------------------

-- Owner adds the next stage. Stages that are still owed or paid can't
-- add up to more than the accepted offer.
create or replace function public.add_payment_stage(
  p_project_id uuid,
  p_amount numeric,
  p_description text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid     uuid := private.require_active_user();
  v_project public.projects;
  v_agreed  numeric(12, 2);
  v_planned numeric(14, 2);
  v_last    integer;
  v_id      uuid;
begin
  select * into v_project from public.projects where id = p_project_id for update;
  if not found or v_project.owner_id <> v_uid then
    raise exception 'Project not found' using errcode = 'P0002';
  end if;
  if v_project.status <> 'in_progress' then
    raise exception 'Payment stages can only be added while the project is in progress' using errcode = 'P0001';
  end if;
  if p_amount is null or round(p_amount, 2) <= 0 then
    raise exception 'The amount must be more than zero' using errcode = '22023';
  end if;

  select o.amount into v_agreed
    from public.project_offers o
   where o.project_id = p_project_id and o.status = 'accepted';

  select coalesce(sum(pp.amount) filter (where pp.status in ('pending', 'processing', 'paid')), 0),
         coalesce(max(pp.stage_number), 0)
    into v_planned, v_last
    from public.project_payments pp
   where pp.project_id = p_project_id;

  if v_planned + round(p_amount, 2) > v_agreed then
    raise exception 'Stages would total % but the agreed amount is %', v_planned + round(p_amount, 2), v_agreed
      using errcode = 'P0001';
  end if;

  insert into public.project_payments (project_id, stage_number, description, amount)
  values (p_project_id, v_last + 1, nullif(btrim(p_description), ''), round(p_amount, 2))
  returning id into v_id;
  return v_id;
end;
$$;

-- Owner drops a stage that hasn't started paying.
create or replace function public.cancel_payment_stage(p_payment_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_active_user();
begin
  update public.project_payments pp
     set status = 'cancelled'
    from public.projects p
   where pp.id = p_payment_id
     and p.id = pp.project_id
     and p.owner_id = v_uid
     and pp.status in ('pending', 'failed')
     and pp.gateway_reference is null;
  if not found then
    raise exception 'Only an unpaid stage of your own project can be cancelled' using errcode = 'P0001';
  end if;
end;
$$;

revoke all on function public.add_payment_stage(uuid, numeric, text) from public, anon;
revoke all on function public.cancel_payment_stage(uuid) from public, anon;
grant execute on function public.add_payment_stage(uuid, numeric, text) to authenticated;
grant execute on function public.cancel_payment_stage(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- Row level security (read-only for clients)
-- ---------------------------------------------------------------------
alter table public.project_payments enable row level security;

create policy project_payments_select
  on public.project_payments for select
  to authenticated
  using (
    (select private.is_admin())
    or exists (
      select 1 from public.projects p
      where p.id = project_payments.project_id
        and (p.owner_id = (select auth.uid()) or p.taker_id = (select auth.uid()))
    )
  );

revoke all on table public.project_payments from anon, authenticated;
grant select on table public.project_payments to authenticated;
;
