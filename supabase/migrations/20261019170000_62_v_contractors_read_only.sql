-- =====================================================================
-- 62_v_contractors_read_only.sql  ·  v_contractors is read-only
--
-- Migration 61 revoked the default privileges of v_contractors from
-- public and anon but not from authenticated, so signed-in users kept
-- Supabase's defaults on it (INSERT, UPDATE, DELETE, TRUNCATE, ...).
-- Postgres can't write through this view (it joins tables), but like
-- every other view it must only be readable.
-- =====================================================================

revoke all on public.v_contractors from public, anon, authenticated;
grant select on public.v_contractors to authenticated;
