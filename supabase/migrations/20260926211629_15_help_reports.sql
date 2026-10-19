-- =====================================================================
-- 15_help_reports.sql  ·  support tickets and abuse reports
--
-- Review fixes here:
--   #10 the target is a real foreign key (one typed column per kind of
--       target, at most one set). Only the reporter and admins can
--       read a report; the reported person never can. Only admins
--       assign and resolve (assigned_admin_id now exists).
--       Reported messages/reviews are snapshotted server-side, so
--       admins never need access to private chats.
--   #4  reporter_id is always the signed-in user.
--   #8  ON DELETE RESTRICT: reported content can't be deleted away.
--   #11 enum report_type / status.   #13 timestamps + history.
-- =====================================================================

create table public.help_reports (
  id                uuid primary key default gen_random_uuid(),
  reporter_id       uuid not null default auth.uid()
                    references public.users (id) on delete restrict,
  report_type       public.report_type not null,
  description       text not null check (char_length(btrim(description)) between 5 and 5000),
  target_user_id    uuid references public.users (id) on delete restrict,
  target_project_id uuid references public.projects (id) on delete restrict,
  target_item_id    uuid references public.marketplace_items (id) on delete restrict,
  target_order_id   uuid references public.orders (id) on delete restrict,
  target_review_id  uuid references public.reviews (id) on delete restrict,
  target_message_id uuid references public.messages (id) on delete restrict,
  -- Copy of the reported message/review taken at report time.
  evidence_snapshot text,
  status            public.report_status not null default 'open',
  assigned_admin_id uuid references public.users (id) on delete restrict,
  resolution_note   text check (resolution_note is null or char_length(resolution_note) <= 5000),
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  resolved_at       timestamptz,
  constraint help_reports_one_target check (
    num_nonnulls(target_user_id, target_project_id, target_item_id,
                 target_order_id, target_review_id, target_message_id) <= 1
  ),
  constraint help_reports_not_self check (target_user_id is null or target_user_id <> reporter_id)
);

comment on table public.help_reports is
  'Readable by the reporter and admins only. Set at most one target_* column. Admins use admin_assign_help_report()/admin_resolve_help_report().';

create index help_reports_reporter_id_idx on public.help_reports (reporter_id, created_at desc);
create index help_reports_queue_idx on public.help_reports (status, created_at);
create index help_reports_target_user_id_idx on public.help_reports (target_user_id);
create index help_reports_target_project_id_idx on public.help_reports (target_project_id);
create index help_reports_target_item_id_idx on public.help_reports (target_item_id);
create index help_reports_target_order_id_idx on public.help_reports (target_order_id);
create index help_reports_target_review_id_idx on public.help_reports (target_review_id);
create index help_reports_target_message_id_idx on public.help_reports (target_message_id);
create index help_reports_assigned_admin_id_idx on public.help_reports (assigned_admin_id);

create trigger help_reports_set_updated_at
  before update on public.help_reports
  for each row execute function private.set_updated_at();

-- Check the reporter could see what they report, and snapshot it.
create or replace function private.help_reports_prepare()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.evidence_snapshot := null;
  if new.target_message_id is not null then
    select m.content into new.evidence_snapshot
    from public.messages m
    join public.chat_members cm on cm.chat_id = m.chat_id and cm.user_id = new.reporter_id
    where m.id = new.target_message_id;
    if not found then
      raise exception 'You can only report messages from your own chats' using errcode = '42501';
    end if;
  elsif new.target_order_id is not null then
    if not exists (
      select 1 from public.orders o
      where o.id = new.target_order_id and new.reporter_id in (o.buyer_id, o.seller_id)
    ) then
      raise exception 'You can only report your own orders' using errcode = '42501';
    end if;
  elsif new.target_review_id is not null then
    select r.rating || '/5: ' || coalesce(r.comment, '') into new.evidence_snapshot
    from public.reviews r
    where r.id = new.target_review_id;
  end if;
  return new;
end;
$$;

revoke all on function private.help_reports_prepare() from public;

create trigger help_reports_prepare
  before insert on public.help_reports
  for each row execute function private.help_reports_prepare();

-- ---------------------------------------------------------------------
-- Admin RPCs
-- ---------------------------------------------------------------------

-- assignToAdmin(admin_id): defaults to the calling admin.
create or replace function public.admin_assign_help_report(p_report_id uuid, p_admin_id uuid default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin    uuid := private.require_admin();
  v_assignee uuid := coalesce(p_admin_id, v_admin);
begin
  if not exists (
    select 1 from public.users where id = v_assignee and role = 'admin' and deleted_at is null
  ) then
    raise exception 'Reports can only be assigned to an admin' using errcode = 'P0001';
  end if;
  update public.help_reports
     set assigned_admin_id = v_assignee,
         status = case when status = 'open' then 'in_review'::public.report_status else status end
   where id = p_report_id and status in ('open', 'in_review');
  if not found then
    raise exception 'Report not found or already closed' using errcode = 'P0002';
  end if;
end;
$$;

-- resolveTicket(): resolved or dismissed, with a note for the reporter.
create or replace function public.admin_resolve_help_report(
  p_report_id uuid,
  p_status public.report_status,
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
  if p_status not in ('resolved', 'dismissed') then
    raise exception 'Use resolved or dismissed' using errcode = '22023';
  end if;
  perform set_config('app.status_note', coalesce(left(p_note, 1000), ''), true);
  update public.help_reports
     set status = p_status,
         resolution_note = p_note,
         resolved_at = now(),
         assigned_admin_id = coalesce(assigned_admin_id, v_admin)
   where id = p_report_id and status in ('open', 'in_review');
  if not found then
    raise exception 'Report not found or already closed' using errcode = 'P0002';
  end if;
end;
$$;

revoke all on function public.admin_assign_help_report(uuid, uuid) from public, anon;
revoke all on function public.admin_resolve_help_report(uuid, public.report_status, text) from public, anon;
grant execute on function public.admin_assign_help_report(uuid, uuid) to authenticated;
grant execute on function public.admin_resolve_help_report(uuid, public.report_status, text) to authenticated;

-- ---------------------------------------------------------------------
-- Row level security + column grants
-- ---------------------------------------------------------------------
alter table public.help_reports enable row level security;

create policy help_reports_select
  on public.help_reports for select
  to authenticated
  using (reporter_id = (select auth.uid()) or (select private.is_admin()));

create policy help_reports_insert_own
  on public.help_reports for insert
  to authenticated
  with check (
    reporter_id = (select auth.uid())
    and status = 'open'
    and (select private.is_active_user())
  );

revoke all on table public.help_reports from anon, authenticated;
grant select on table public.help_reports to authenticated;
grant insert (report_type, description, target_user_id, target_project_id, target_item_id,
              target_order_id, target_review_id, target_message_id)
  on table public.help_reports to authenticated;
;
