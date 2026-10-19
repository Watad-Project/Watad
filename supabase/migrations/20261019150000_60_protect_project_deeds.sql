-- =====================================================================
-- 60_protect_project_deeds.sql  ·  the private project-deeds bucket
--
-- Ownership deeds (GRA-18, GRA-22) are legal documents: only the project's
-- owner and the admins who review them (GRA-30) may see them.
--
-- The bucket, its first two policies and projects.deed_storage_path were
-- created outside the migrations (the column on 2026-10-17, the bucket on
-- 2026-10-19). This migration records them and closes the gaps:
--   1. a 10 MB limit (there was none) and the file types of the other
--      private buckets;
--   2. admins can read deeds, to review them;
--   3. only active (not suspended) users upload, and only into their own
--      folder: <user id>/<file name>;
--   4. nobody updates or deletes a deed file: there is no UPDATE or DELETE
--      policy, so storage refuses both. A new deed is a new file;
--   5. projects.deed_storage_path must point into the project owner's
--      folder, so a client can't attach someone else's deed to a project.
--
-- Safe to run more than once.
-- =====================================================================

-- 1. The bucket: private, 10 MB, PDF or image.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'project-deeds',
  'project-deeds',
  false,
  10485760,
  array['application/pdf', 'image/jpeg', 'image/png']
)
on conflict (id) do update
  set public             = false,
      file_size_limit    = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- 2. Who may upload and read. The dashboard's two policies are replaced.
drop policy if exists "Users can upload their own deed documents" on storage.objects;
drop policy if exists "Users can read their own deed documents" on storage.objects;
drop policy if exists watad_deeds_insert_own on storage.objects;
drop policy if exists watad_deeds_select on storage.objects;

-- An active user uploads into their own folder only.
create policy watad_deeds_insert_own on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'project-deeds'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and (select private.is_active_user())
  );

-- The owner reads their own deeds; admins read every deed to review it.
-- Contractors and other clients read none.
create policy watad_deeds_select on storage.objects
  for select to authenticated
  using (
    bucket_id = 'project-deeds'
    and (
      (storage.foldername(name))[1] = (select auth.uid())::text
      or (select private.is_admin())
    )
  );

-- 3. The project's deed: a path in project-deeds, written by the owner.
alter table public.projects
  add column if not exists deed_storage_path text;

grant insert (deed_storage_path), update (deed_storage_path)
  on public.projects to authenticated;

-- It must be inside the owner's own folder, without '..'.
alter table public.projects
  drop constraint if exists projects_deed_path_in_owner_folder;
alter table public.projects
  add constraint projects_deed_path_in_owner_folder check (
    deed_storage_path is null
    or (
      deed_storage_path like (owner_id::text || '/%')
      and position('..' in deed_storage_path) = 0
    )
  );
