-- 55_images_bucket
-- General-purpose image bucket for the whole platform (listings, projects, businesses, ...).
-- Public: anyone can view a file through its public URL.
-- Path: <user id>/<optional subfolders>/<file>, e.g. <uid>/listings/<file>.
-- Only the owner, while active (not suspended or deleted), can upload, replace or delete
-- files in their own folder. Admins can see and delete any file (moderation).

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'images', 'images', true, 5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

-- Reading/listing through the API: own folder only (admins: everything).
-- Public URLs need no policy.
create policy watad_images_select on storage.objects
for select to authenticated
using (
  bucket_id = 'images'
  and (
    (storage.foldername(name))[1] = (select auth.uid())::text
    or (select private.is_admin())
  )
);

create policy watad_images_insert_own on storage.objects
for insert to authenticated
with check (
  bucket_id = 'images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and (select private.is_active_user())
);

create policy watad_images_update_own on storage.objects
for update to authenticated
using (
  bucket_id = 'images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and (select private.is_active_user())
)
with check (
  bucket_id = 'images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and (select private.is_active_user())
);

create policy watad_images_delete on storage.objects
for delete to authenticated
using (
  bucket_id = 'images'
  and (
    (
      (storage.foldername(name))[1] = (select auth.uid())::text
      and (select private.is_active_user())
    )
    or (select private.is_admin())
  )
);;
