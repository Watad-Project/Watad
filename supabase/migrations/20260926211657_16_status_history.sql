-- =====================================================================
-- 16_status_history.sql  ·  audit trail of every status change
--
-- Review fix #13: who changed what, and when, for orders, projects,
-- offers, payments, business verification and help reports. Rows are
-- written only by triggers; nobody can edit or delete them.
-- =====================================================================

create table public.status_history (
  id                 bigint generated always as identity primary key,
  order_id           uuid references public.orders (id) on delete restrict,
  project_id         uuid references public.projects (id) on delete restrict,
  project_offer_id   uuid references public.project_offers (id) on delete restrict,
  project_payment_id uuid references public.project_payments (id) on delete restrict,
  business_id        uuid references public.businesses (user_id) on delete restrict,
  help_report_id     uuid references public.help_reports (id) on delete restrict,
  old_status         text,
  new_status         text not null,
  -- Null when the change came from the server (payment webhook, jobs).
  changed_by         uuid references public.users (id) on delete restrict,
  note               text,
  changed_at         timestamptz not null default now(),
  constraint status_history_one_subject check (
    num_nonnulls(order_id, project_id, project_offer_id, project_payment_id,
                 business_id, help_report_id) = 1
  )
);

comment on table public.status_history is
  'Append-only audit trail, written by triggers. Visible to the parties of each record and to admins.';

create index status_history_order_id_idx on public.status_history (order_id);
create index status_history_project_id_idx on public.status_history (project_id);
create index status_history_project_offer_id_idx on public.status_history (project_offer_id);
create index status_history_project_payment_id_idx on public.status_history (project_payment_id);
create index status_history_business_id_idx on public.status_history (business_id);
create index status_history_help_report_id_idx on public.status_history (help_report_id);
create index status_history_changed_by_idx on public.status_history (changed_by);

-- One trigger function for every table. An RPC can attach a reason
-- with set_config('app.status_note', '...', true).
create or replace function private.record_status_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_col   text := case when tg_table_name = 'businesses' then 'verification_status' else 'status' end;
  v_key   text := case when tg_table_name = 'businesses' then 'user_id' else 'id' end;
  v_new   text := to_jsonb(new) ->> v_col;
  v_old   text;
  v_id    uuid := (to_jsonb(new) ->> v_key)::uuid;
  v_actor uuid;
begin
  if tg_op = 'UPDATE' then
    v_old := to_jsonb(old) ->> v_col;
    if v_old is not distinct from v_new then
      return new;
    end if;
  end if;

  select u.id into v_actor from public.users u where u.id = auth.uid();

  insert into public.status_history (
    order_id, project_id, project_offer_id, project_payment_id, business_id, help_report_id,
    old_status, new_status, changed_by, note)
  values (
    case when tg_table_name = 'orders' then v_id end,
    case when tg_table_name = 'projects' then v_id end,
    case when tg_table_name = 'project_offers' then v_id end,
    case when tg_table_name = 'project_payments' then v_id end,
    case when tg_table_name = 'businesses' then v_id end,
    case when tg_table_name = 'help_reports' then v_id end,
    v_old, v_new, v_actor,
    nullif(current_setting('app.status_note', true), ''));
  return new;
end;
$$;

revoke all on function private.record_status_change() from public;

create trigger orders_status_history
  after insert or update of status on public.orders
  for each row execute function private.record_status_change();

create trigger projects_status_history
  after insert or update of status on public.projects
  for each row execute function private.record_status_change();

create trigger project_offers_status_history
  after insert or update of status on public.project_offers
  for each row execute function private.record_status_change();

create trigger project_payments_status_history
  after insert or update of status on public.project_payments
  for each row execute function private.record_status_change();

create trigger businesses_status_history
  after insert or update of verification_status on public.businesses
  for each row execute function private.record_status_change();

create trigger help_reports_status_history
  after insert or update of status on public.help_reports
  for each row execute function private.record_status_change();

-- ---------------------------------------------------------------------
-- Row level security (read-only for clients)
-- ---------------------------------------------------------------------
alter table public.status_history enable row level security;

create policy status_history_select
  on public.status_history for select
  to authenticated
  using (
    (select private.is_admin())
    or business_id = (select auth.uid())
    or exists (
      select 1 from public.orders o
      where o.id = status_history.order_id
        and (o.buyer_id = (select auth.uid()) or o.seller_id = (select auth.uid()))
    )
    or exists (
      select 1 from public.projects p
      where p.id = status_history.project_id
        and (p.owner_id = (select auth.uid()) or p.taker_id = (select auth.uid()))
    )
    or exists (
      select 1 from public.project_offers po
      join public.projects p on p.id = po.project_id
      where po.id = status_history.project_offer_id
        and (po.provider_id = (select auth.uid()) or p.owner_id = (select auth.uid()))
    )
    or exists (
      select 1 from public.project_payments pp
      join public.projects p on p.id = pp.project_id
      where pp.id = status_history.project_payment_id
        and (p.owner_id = (select auth.uid()) or p.taker_id = (select auth.uid()))
    )
    or exists (
      select 1 from public.help_reports h
      where h.id = status_history.help_report_id
        and h.reporter_id = (select auth.uid())
    )
  );

revoke all on table public.status_history from anon, authenticated;
grant select on table public.status_history to authenticated;
;
