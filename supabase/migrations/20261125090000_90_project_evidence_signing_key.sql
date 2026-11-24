-- =====================================================================
-- 90_project_evidence_signing_key.sql  ·  project-evidence's keys in the Vault (GRA-76)
--
-- project-evidence (migration 84) read three Edge Function secrets:
-- PROJECT_EVIDENCE_SECRET, EVIDENCE_SIGNING_KEY and EVIDENCE_SIGNING_KEY_ID.
-- They were never set, so every export answered not_configured. Now the
-- function falls back to the Vault, when a secret isn't set:
--   1. project_evidence_config(): the Vault's project_evidence_secret, and
--      the signing key and its id once they exist (null before).
--   2. project_evidence_store_signing_key(p_key, p_key_id): the first time
--      it finds no key, the function makes an Ed25519 key itself and saves
--      it here. Only the first key is kept: a second call gets the stored
--      one back, so two exports at the same moment sign with the same key.
--      The key never leaves the server; a new key is never written over the
--      old one, or earlier PDFs could no longer be checked.
-- Both are for the Edge Function only (service_role), like
-- project_evidence_collect(). The app never calls them.
-- =====================================================================

create or replace function public.project_evidence_config()
returns jsonb
language sql
stable
security definer
set search_path to ''
as $$
  select jsonb_build_object(
    'db_secret', (select s.decrypted_secret from vault.decrypted_secrets s
                   where s.name = 'project_evidence_secret'),
    'signing_key', (select s.decrypted_secret from vault.decrypted_secrets s
                     where s.name = 'evidence_signing_key'),
    'key_id', (select s.decrypted_secret from vault.decrypted_secrets s
                where s.name = 'evidence_signing_key_id'));
$$;

revoke all on function public.project_evidence_config() from public, anon, authenticated;
grant execute on function public.project_evidence_config() to service_role;

-- p_key: an Ed25519 private key, PKCS#8 DER in base64. p_key_id: its name.
-- Errors: 22023 (invalid_signing_key) for an empty key or id.
create or replace function public.project_evidence_store_signing_key(
  p_key    text,
  p_key_id text
)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $$
begin
  if nullif(btrim(p_key), '') is null or nullif(btrim(p_key_id), '') is null
     or char_length(p_key_id) > 100 then
    raise exception 'invalid_signing_key' using errcode = '22023';
  end if;
  -- One key at a time: the first caller stores it, the others wait here
  -- and then get it back.
  perform pg_advisory_xact_lock(hashtext('evidence_signing_key'));
  if not exists (select 1 from vault.secrets where name = 'evidence_signing_key') then
    perform vault.create_secret(p_key, 'evidence_signing_key',
      'Ed25519 private key (PKCS#8 DER, base64) that project-evidence signs exports with');
    perform vault.create_secret(p_key_id, 'evidence_signing_key_id',
      'The name of evidence_signing_key, printed in each export');
  end if;
  return public.project_evidence_config();
end;
$$;

revoke all on function public.project_evidence_store_signing_key(text, text) from public, anon, authenticated;
grant execute on function public.project_evidence_store_signing_key(text, text) to service_role;
