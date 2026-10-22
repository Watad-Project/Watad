-- =====================================================================
-- 70_notification_offers.sql  ·  offers notify people
--
-- Two more events like those of migration 68: a trigger that calls
-- private.notify() (migration 69's version, with pop_up):
--
--   | Event                                   | Who is told                |
--   |-----------------------------------------|----------------------------|
--   | A contractor sends an offer             | the project's owner        |
--   | An offer is accepted, or rejected       | the contractor who sent it |
--
-- accept_offer() also rejects the project's other pending offers: each of
-- their contractors is told. A withdrawn offer, or an edit to a pending
-- one, tells nobody. A notification that can't be written never stops the
-- offer: the trigger logs a warning. data.type names the event and
-- carries its ids (ARCHITECTURE.md §13).
-- =====================================================================

-- Who sent an offer: their business's name, or their own, or «مقاول».
create or replace function private.notification_provider_name(p_user_id uuid)
returns text
language sql
stable
security definer
set search_path to ''
as $$
  select coalesce(
    (select nullif(btrim(b.company_name), '') from public.businesses b
      where b.user_id = p_user_id and b.deleted_at is null),
    (select nullif(btrim(u.full_name), '') from public.users u
      where u.id = p_user_id),
    'مقاول');
$$;

revoke all on function private.notification_provider_name(uuid) from public, anon, authenticated;

-- 1. A contractor sends an offer: the project's owner.
create or replace function private.notify_offer_received()
returns trigger
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_owner uuid;
  v_title text := private.notification_project_title(new.project_id);
begin
  select p.owner_id into v_owner from public.projects p where p.id = new.project_id;
  if v_owner is distinct from new.provider_id then
    perform private.notify(
      v_owner,
      'عرض جديد على مشروعك',
      private.notification_provider_name(new.provider_id)
        || case when v_title = '' then '' else ' — ' || v_title end,
      jsonb_build_object('type', 'offer_received', 'project_id', new.project_id,
                         'offer_id', new.id),
      true);
  end if;
  return null;
exception when others then
  raise warning 'private.notify_offer_received(%) failed: %', new.id, sqlerrm;
  return null;
end;
$$;

create trigger notifications_offer_received
  after insert on public.project_offers
  for each row execute function private.notify_offer_received();

-- 2. An offer is accepted or rejected: the contractor who sent it. An
-- acceptance pops up; a rejection goes to the normal channel.
create or replace function private.notify_offer_decided()
returns trigger
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_title text := private.notification_project_title(new.project_id);
begin
  if new.status is not distinct from old.status then
    return null;
  end if;
  if new.status = 'accepted' then
    perform private.notify(
      new.provider_id,
      'تم قبول عرضك',
      case when v_title = '' then 'بدأ المشروع معك.'
           else 'بدأ المشروع ' || v_title || ' معك.' end,
      jsonb_build_object('type', 'offer_accepted', 'project_id', new.project_id,
                         'offer_id', new.id),
      true);
  elsif new.status = 'rejected' then
    perform private.notify(
      new.provider_id,
      'لم يُقبل عرضك',
      case when v_title = '' then 'على المشروع.'
           else 'على المشروع ' || v_title || '.' end,
      jsonb_build_object('type', 'offer_rejected', 'project_id', new.project_id,
                         'offer_id', new.id),
      false);
  end if;
  return null;
exception when others then
  raise warning 'private.notify_offer_decided(%) failed: %', new.id, sqlerrm;
  return null;
end;
$$;

create trigger notifications_offer_decided
  after update of status on public.project_offers
  for each row execute function private.notify_offer_decided();

revoke all on function private.notify_offer_received() from public, anon, authenticated;
revoke all on function private.notify_offer_decided() from public, anon, authenticated;
