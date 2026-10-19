-- =====================================================================
-- 10_project_reports.sql  ·  progress updates the taker posts
--
-- Review fixes here:
--   #4  author_id is always the signed-in user, and that user must be
--       the project's current taker while the project is in progress.
--   #8  ON DELETE RESTRICT; reports can't be deleted by clients.
--   #13 timestamps.
-- =====================================================================

create table public.project_reports (
  id         uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects (id) on delete restrict,
  author_id  uuid not null default auth.uid()
             references public.businesses (user_id) on delete restrict,
  title      text not null check (char_length(btrim(title)) between 2 and 150),
  content    text not null check (char_length(btrim(content)) between 1 and 10000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.project_reports is
  'publishUpdate(): insert a row. Only the current taker can post, only while the project is in progress.';

create index project_reports_project_id_idx on public.project_reports (project_id, created_at desc);
create index project_reports_author_id_idx on public.project_reports (author_id);

create trigger project_reports_set_updated_at
  before update on public.project_reports
  for each row execute function private.set_updated_at();

-- ---------------------------------------------------------------------
-- Row level security + column grants
-- ---------------------------------------------------------------------
alter table public.project_reports enable row level security;

create policy project_reports_select
  on public.project_reports for select
  to authenticated
  using (
    (select private.is_admin())
    or exists (
      select 1 from public.projects p
      where p.id = project_reports.project_id
        and (p.owner_id = (select auth.uid()) or p.taker_id = (select auth.uid()))
    )
  );

create policy project_reports_insert_taker
  on public.project_reports for insert
  to authenticated
  with check (
    author_id = (select auth.uid())
    and (select private.is_active_user())
    and exists (
      select 1 from public.projects p
      where p.id = project_reports.project_id
        and p.taker_id = (select auth.uid())
        and p.status = 'in_progress'
    )
  );

create policy project_reports_update_taker
  on public.project_reports for update
  to authenticated
  using (
    author_id = (select auth.uid())
    and exists (
      select 1 from public.projects p
      where p.id = project_reports.project_id
        and p.taker_id = (select auth.uid())
        and p.status = 'in_progress'
    )
  )
  with check (author_id = (select auth.uid()));

revoke all on table public.project_reports from anon, authenticated;
grant select on table public.project_reports to authenticated;
grant insert (project_id, title, content) on table public.project_reports to authenticated;
grant update (title, content) on table public.project_reports to authenticated;
;
