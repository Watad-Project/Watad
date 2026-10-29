-- =====================================================================
-- 85_bank_details_reminder.sql  ·  remind contractors to add their bank account
--
-- Feature (GRA-64, with the contractor's bank details screen): clients pay
-- a project's stages by bank transfer into the account the contractor
-- saved in contractor_bank_details (migration 78, GRA-48), and the
-- transfer screen (GRA-52) can't be used until it's there. On 2026-10-28,
-- 12 of the 13 verified businesses had none. A pop-up notification asks
-- them to add it; its data.type, bank_details_missing, opens the bank
-- details screen in the app (ARCHITECTURE.md §13).
--
--   1. private.notify_bank_details_missing(): the one rule and the one
--      text. Only someone who can add the details is told: a verified
--      business whose account is open and not suspended
--      (private.is_verified_business()), and only while they have none.
--   2. When a business becomes verified (admin_set_business_verification()).
--   3. When one of the contractor's offers is accepted (accept_offer()).
--      offer_accepted (migration 70) comes with it; the reminder is
--      written first, so «تم قبول عرضك» is the pop-up that stays on
--      screen (the app shows one at a time).
--   4. Once, now: every verified business that has no bank details yet.
--
-- A notification that can't be written never stops the event: the
-- triggers log a warning, as in migration 70.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. The reminder
-- ---------------------------------------------------------------------
create or replace function private.notify_bank_details_missing(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path to ''
as $$
begin
  if private.is_verified_business(p_user_id)
     and not exists (select 1 from public.contractor_bank_details d
                      where d.user_id = p_user_id) then
    perform private.notify(
      p_user_id,
      'أضف حسابك البنكي',
      'ليتمكن العملاء من تحويل دفعاتهم إليك، أضف بيانات حسابك البنكي.',
      jsonb_build_object('type', 'bank_details_missing'),
      true);
  end if;
end;
$$;

-- ---------------------------------------------------------------------
-- 2. A business becomes verified
-- ---------------------------------------------------------------------
create or replace function private.notify_bank_details_missing_on_verify()
returns trigger
language plpgsql
security definer
set search_path to ''
as $$
begin
  if new.verification_status = 'verified'
     and old.verification_status is distinct from 'verified' then
    perform private.notify_bank_details_missing(new.user_id);
  end if;
  return null;
exception when others then
  raise warning 'private.notify_bank_details_missing_on_verify(%) failed: %', new.user_id, sqlerrm;
  return null;
end;
$$;

create trigger notifications_bank_details_on_verify
  after update of verification_status on public.businesses
  for each row execute function private.notify_bank_details_missing_on_verify();

-- ---------------------------------------------------------------------
-- 3. One of their offers is accepted. Triggers fire in name order: this
--    one before notifications_offer_decided (migration 70).
-- ---------------------------------------------------------------------
create or replace function private.notify_bank_details_missing_on_offer()
returns trigger
language plpgsql
security definer
set search_path to ''
as $$
begin
  if new.status = 'accepted' and old.status is distinct from 'accepted' then
    perform private.notify_bank_details_missing(new.provider_id);
  end if;
  return null;
exception when others then
  raise warning 'private.notify_bank_details_missing_on_offer(%) failed: %', new.id, sqlerrm;
  return null;
end;
$$;

create trigger notifications_bank_details_on_offer
  after update of status on public.project_offers
  for each row execute function private.notify_bank_details_missing_on_offer();

revoke all on function private.notify_bank_details_missing(uuid) from public, anon, authenticated;
revoke all on function private.notify_bank_details_missing_on_verify() from public, anon, authenticated;
revoke all on function private.notify_bank_details_missing_on_offer() from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- 4. Once, now: every verified business without bank details (12 on
--    2026-10-28). The rule of 1 skips everyone else.
-- ---------------------------------------------------------------------
do $$
begin
  perform private.notify_bank_details_missing(b.user_id)
  from public.businesses b
  where b.verification_status = 'verified'
    and b.deleted_at is null;
end;
$$;
