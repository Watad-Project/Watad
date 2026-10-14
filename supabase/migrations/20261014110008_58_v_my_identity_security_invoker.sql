-- 58_v_my_identity_security_invoker
-- Match the other v_my_* views: run with the caller's rights so RLS applies.
alter view public.v_my_identity set (security_invoker = true);

-- The caller now needs SELECT on the table; RLS (user_identity_select_own) limits it to their own row.
grant select on public.user_identity to authenticated;
