-- 59_project_photos_and_deeds
-- Storage and database support for project photos and ownership deed documents (GRA-18, GRA-21, GRA-22).

-- 1. Add deed and photo storage paths to public.projects
alter table public.projects
  add column if not exists deed_storage_path text,
  add column if not exists photo_paths text[] not null default '{}';

-- 2. Allow direct INSERT/UPDATE from client for deed_storage_path and photo_paths (ARCHITECTURE.md §3a)
grant insert (deed_storage_path, photo_paths) on public.projects to authenticated;
grant update (deed_storage_path, photo_paths) on public.projects to authenticated;

-- 3. Dedicated project_photos table for structured photo attachments (optional normalized access)
create table if not exists public.project_photos (
  id           uuid primary key default gen_random_uuid(),
  project_id   uuid not null references public.projects (id) on delete cascade,
  storage_path text not null,
  sort_order   int not null default 0,
  created_at   timestamptz not null default now()
);

alter table public.project_photos enable row level security;

-- Owner of the project can select photos
create policy project_photos_select on public.project_photos
  for select to authenticated
  using (
    exists (
      select 1 from public.projects p
       where p.id = project_photos.project_id
         and (p.client_id = (select auth.uid()) or p.taker_id = (select auth.uid()))
    )
  );

-- Owner can insert photos for their own project
create policy project_photos_insert on public.project_photos
  for insert to authenticated
  with check (
    exists (
      select 1 from public.projects p
       where p.id = project_photos.project_id
         and p.client_id = (select auth.uid())
    )
  );

-- Owner can delete photos from their own project
create policy project_photos_delete on public.project_photos
  for delete to authenticated
  using (
    exists (
      select 1 from public.projects p
       where p.id = project_photos.project_id
         and p.client_id = (select auth.uid())
    )
  );

grant select, insert, delete on public.project_photos to authenticated;

-- 4. Storage bucket for ownership deeds (private bucket, sensitive legal data)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'project-deeds',
  'project-deeds',
  false,
  10485760, -- 10MB limit
  array['application/pdf', 'image/jpeg', 'image/png']
)
on conflict (id) do nothing;

-- RLS: Only file owner (folder = user_id) or admin can read deed files
create policy "Users can upload their own deed documents"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'project-deeds'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Users can read their own deed documents"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'project-deeds'
    and (
      (storage.foldername(name))[1] = (select auth.uid())::text
      or (select private.is_admin())
    )
  );

-- RLS for project photos in the public 'images' bucket (under projects/<user_id>/...)
create policy "Authenticated users can upload project photos to images bucket"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'images'
    and (storage.foldername(name))[1] = 'projects'
    and (storage.foldername(name))[2] = (select auth.uid())::text
  );
