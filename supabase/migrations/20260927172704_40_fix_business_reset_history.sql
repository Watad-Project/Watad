-- =====================================================================
-- 40_fix_business_reset_history.sql
--
-- Bug: changing a business's company name or CR number drops its
-- verification (02_businesses.sql), but that reset never reached
-- status_history. The audit trigger was "update of verification_status",
-- and Postgres fires a column trigger only when the UPDATE names the
-- column; a change made by a BEFORE trigger does not count. So admins
-- could not see the reset, and 42_business_documents.sql could not tell
-- that the old documents were out of date.
--
-- Fix: fire on every update. record_status_change() already skips rows
-- whose status did not change.
-- =====================================================================

drop trigger businesses_status_history on public.businesses;

create trigger businesses_status_history
  after insert or update on public.businesses
  for each row execute function private.record_status_change();

-- Log any reset that was missed, so the trail ends at the current status.
insert into public.status_history (business_id, old_status, new_status, note)
select b.user_id, last.new_status, b.verification_status::text,
       'Verification reset after a company name or CR change (logged late)'
from public.businesses b
cross join lateral (
  select sh.new_status
  from public.status_history sh
  where sh.business_id = b.user_id
  order by sh.changed_at desc, sh.id desc
  limit 1
) last
where last.new_status is distinct from b.verification_status::text;
;
