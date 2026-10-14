-- 57_complete_client_profile_error_codes
-- Use the error codes the app maps (APP_ARCHITECTURE.md §13): 22023 for invalid input.

create or replace function public.complete_client_profile(
  p_full_name   text,
  p_national_id text,
  p_phone       text
)
returns text
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_uid   uuid := private.require_active_user();
  v_name  text := btrim(coalesce(p_full_name, ''));
  v_nid   text := btrim(coalesce(p_national_id, ''));
  v_phone text := btrim(coalesce(p_phone, ''));
begin
  if exists (select 1 from public.user_identity where user_id = v_uid) then
    return 'already_registered';
  end if;

  if char_length(v_name) < 2 or char_length(v_name) > 100 then
    raise exception 'invalid_full_name' using errcode = '22023';
  end if;
  if v_nid !~ '^[12][0-9]{9}$' then
    raise exception 'invalid_national_id' using errcode = '22023';
  end if;
  if v_phone !~ '^5[0-9]{8}$' then
    raise exception 'invalid_phone' using errcode = '22023';
  end if;

  begin
    insert into public.user_identity (user_id, national_id, phone)
    values (v_uid, v_nid, '+966' || v_phone);
  exception when unique_violation then
    raise exception 'national_id_taken' using errcode = '23505';
  end;

  update public.users set full_name = v_name where id = v_uid;

  return 'created';
end;
$$;

revoke all on function public.complete_client_profile(text, text, text) from public, anon;
grant execute on function public.complete_client_profile(text, text, text) to authenticated;
