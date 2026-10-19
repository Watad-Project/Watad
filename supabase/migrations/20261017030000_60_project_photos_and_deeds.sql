-- 60_project_photos_and_deeds
-- Storage and database support for project photos, ownership deeds, and verification lifecycle (GRA-18, GRA-21, GRA-22, GRA-30).

-- 1. Add deed, photo storage paths, and deed verification status columns to public.projects
alter table public.projects
  add column if not exists deed_storage_path text,
  add column if not exists photo_paths text[] not null default '{}',
  add column if not exists deed_status text not null default 'none' check (deed_status in ('none', 'under_review', 'verified', 'rejected')),
  add column if not exists deed_rejection_reason text,
  add column if not exists deed_reviewed_at timestamptz,
  add column if not exists deed_reviewed_by uuid references public.users (id);

-- 2. Allow direct INSERT/UPDATE from client for deed_storage_path and photo_paths (ARCHITECTURE.md §3a)
-- Note: deed_status and deed_rejection_reason are locked and changed only by trigger / admin RPC.
grant insert (deed_storage_path, photo_paths) on public.projects to authenticated;
grant update (deed_storage_path, photo_paths) on public.projects to authenticated;

-- 3. Trigger to manage deed verification status on insert/update of deed_storage_path
create or replace function private.handle_project_deed_status_change()
returns trigger
language plpgsql
security definer
set search_path to ''
as $$
begin
  if tg_op = 'INSERT' then
    if new.deed_storage_path is not null and btrim(new.deed_storage_path) <> '' then
      new.deed_status := 'under_review';
    else
      new.deed_status := 'none';
    end if;
  elsif tg_op = 'UPDATE' then
    if new.deed_storage_path is distinct from old.deed_storage_path then
      if new.deed_storage_path is not null and btrim(new.deed_storage_path) <> '' then
        new.deed_status := 'under_review';
        new.deed_rejection_reason := null;
        new.deed_reviewed_at := null;
        new.deed_reviewed_by := null;
      else
        new.deed_status := 'none';
        new.deed_rejection_reason := null;
        new.deed_reviewed_at := null;
        new.deed_reviewed_by := null;
      end if;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists watad_project_deed_status_change on public.projects;
create trigger watad_project_deed_status_change
  before insert or update of deed_storage_path on public.projects
  for each row execute function private.handle_project_deed_status_change();

-- 4. Admin RPC to review property deeds (GRA-30)
create or replace function public.admin_set_project_deed_verification(
  p_project_id        uuid,
  p_status            text,
  p_rejection_reason  text default null
)
returns void
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_admin_id uuid := private.require_active_user();
  v_status   text := btrim(coalesce(p_status, ''));
  v_reason   text := btrim(coalesce(p_rejection_reason, ''));
begin
  if not private.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  if v_status not in ('under_review', 'verified', 'rejected') then
    raise exception 'invalid_deed_status' using errcode = 'P0001';
  end if;

  if v_status = 'rejected' and (v_reason = '' or char_length(v_reason) < 3) then
    raise exception 'rejection_reason_required' using errcode = 'P0001';
  end if;

  if not exists (select 1 from public.projects where id = p_project_id) then
    raise exception 'project_not_found' using errcode = 'P0002';
  end if;

  update public.projects
     set deed_status           = v_status,
         deed_rejection_reason = case when v_status = 'rejected' then v_reason else null end,
         deed_reviewed_at      = now(),
         deed_reviewed_by      = v_admin_id
   where id = p_project_id;
end;
$$;

revoke all on function public.admin_set_project_deed_verification(uuid, text, text) from public, anon;
grant execute on function public.admin_set_project_deed_verification(uuid, text, text) to authenticated;

-- 5. Storage bucket for ownership deeds (private bucket, sensitive legal data)
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
