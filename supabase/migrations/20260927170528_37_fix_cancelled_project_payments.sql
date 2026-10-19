-- =====================================================================
-- 37_fix_cancelled_project_payments.sql
--
-- Bug (scenario 14, high): a cancelled project could still collect
-- payments. Cancelling left its unpaid stages 'pending', and a later
-- gateway confirmation was applied and kept.
--
--   1. set_project_status(): cancelling a project now also cancels its
--      stages that are not paid (pending, processing, failed).
--   2. record_payment_event(): a payment for a stage of a cancelled
--      project is flagged 'needs_refund', never applied, even if it was
--      already in flight when the project was cancelled.
--
-- Also hardened in the same function: when a gateway reference is
-- attached, a webhook with a different or missing reference is not
-- applied ('x <> null' is null, so the old check let it through).
--
-- Replaces the definitions in 07_projects.sql and 17_payment_events.sql;
-- grants are unchanged.
-- =====================================================================

create or replace function public.set_project_status(p_project_id uuid, p_status public.project_status)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid     uuid := private.require_active_user();
  v_admin   boolean := private.is_admin();
  v_project public.projects;
begin
  select * into v_project from public.projects where id = p_project_id for update;
  if not found or (v_project.owner_id <> v_uid and not v_admin) then
    raise exception 'Project not found' using errcode = 'P0002';
  end if;
  if v_project.status = p_status then
    return;
  end if;
  if p_status = 'in_progress' then
    raise exception 'A project starts when you accept an offer' using errcode = 'P0001';
  end if;
  if not v_admin and not (
       (v_project.status = 'draft' and p_status in ('open', 'cancelled'))
    or (v_project.status = 'open' and p_status in ('draft', 'cancelled'))
    or (v_project.status = 'in_progress' and p_status = 'completed')
  ) then
    raise exception 'A project can''t move from % to %', v_project.status, p_status using errcode = 'P0001';
  end if;
  if v_project.status = 'open' and p_status = 'draft'
     and exists (select 1 from public.project_offers where project_id = p_project_id) then
    raise exception 'This project already has offers; cancel it instead' using errcode = 'P0001';
  end if;

  perform set_config('app.status_note', case when v_admin and v_project.owner_id <> v_uid then 'changed by admin' else '' end, true);

  if p_status = 'cancelled' then
    update public.project_offers
       set status = 'rejected', decided_at = now()
     where project_id = p_project_id and status = 'pending';
    -- FIX: stages that are not paid can no longer be paid. A payment
    -- already in flight ('processing') is cancelled too; if the gateway
    -- still confirms it, record_payment_event() returns 'needs_refund'.
    update public.project_payments
       set status = 'cancelled'
     where project_id = p_project_id
       and status in ('pending', 'processing', 'failed');
  end if;

  update public.projects
     set status = p_status,
         completed_at = case when p_status = 'completed' then now() else completed_at end
   where id = p_project_id;
end;
$$;

create or replace function public.record_payment_event(
  p_gateway_event_id text,
  p_event_type text,
  p_amount numeric,
  p_currency text,
  p_gateway_reference text,
  p_order_id uuid default null,
  p_project_payment_id uuid default null,
  p_card_brand text default null,
  p_card_last4 text default null
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event_id bigint;
  v_outcome  text := 'ignored';
  v_currency text := upper(p_currency);
  v_order    public.orders;
  v_payment  public.project_payments;
begin
  if num_nonnulls(p_order_id, p_project_payment_id) <> 1 then
    raise exception 'Give exactly one of p_order_id / p_project_payment_id' using errcode = '22023';
  end if;

  -- Idempotency: each gateway event is processed once.
  insert into public.payment_events (
    gateway_event_id, event_type, order_id, project_payment_id, amount, currency, gateway_reference)
  values (
    p_gateway_event_id, p_event_type, p_order_id, p_project_payment_id,
    round(p_amount, 2), v_currency, p_gateway_reference)
  on conflict (gateway_event_id) do nothing
  returning id into v_event_id;

  if v_event_id is null then
    return 'duplicate';
  end if;

  perform set_config('app.status_note', 'gateway event ' || p_gateway_event_id, true);

  if p_order_id is not null then
    select * into v_order from public.orders where id = p_order_id for update;
    if not found then
      raise exception 'Unknown order %', p_order_id using errcode = 'P0002';
    end if;

    if p_event_type = 'payment.succeeded' then
      if v_order.status <> 'pending_payment' then
        v_outcome := case when v_order.status = 'cancelled' then 'needs_refund' else 'ignored' end;
      elsif round(p_amount, 2) <> v_order.total_amount
         or v_currency <> v_order.currency
         -- FIX: "is distinct from" so a missing reference counts as a mismatch
         or (v_order.gateway_reference is not null and v_order.gateway_reference is distinct from p_gateway_reference) then
        v_outcome := 'amount_mismatch';
      else
        update public.orders
           set status = 'paid',
               paid_at = now(),
               gateway_reference = p_gateway_reference,
               card_brand = left(p_card_brand, 30),
               card_last4 = case when p_card_last4 ~ '^[0-9]{4}$' then p_card_last4 end
         where id = p_order_id;
        v_outcome := 'applied';
      end if;

    elsif p_event_type = 'payment.failed' then
      -- The order stays open so the buyer can retry (or it expires).
      if v_order.status = 'pending_payment' and v_order.gateway_reference = p_gateway_reference then
        update public.orders set gateway_reference = null where id = p_order_id;
        v_outcome := 'applied';
      end if;

    elsif p_event_type = 'refund.succeeded' then
      if v_order.status in ('paid', 'shipped', 'delivered') then
        update public.orders set status = 'refunded' where id = p_order_id;
        v_outcome := 'applied';
      end if;
    end if;

  else
    select * into v_payment from public.project_payments where id = p_project_payment_id for update;
    if not found then
      raise exception 'Unknown project payment %', p_project_payment_id using errcode = 'P0002';
    end if;

    if p_event_type = 'payment.succeeded' then
      -- FIX: money for a cancelled project is refunded, never kept.
      if exists (select 1 from public.projects p
                  where p.id = v_payment.project_id and p.status = 'cancelled') then
        v_outcome := 'needs_refund';
      elsif v_payment.status not in ('pending', 'processing', 'failed') then
        v_outcome := case when v_payment.status = 'cancelled' then 'needs_refund' else 'ignored' end;
      elsif round(p_amount, 2) <> v_payment.amount
         or v_currency <> v_payment.currency
         -- FIX: "is distinct from" so a missing reference counts as a mismatch
         or (v_payment.gateway_reference is not null and v_payment.gateway_reference is distinct from p_gateway_reference) then
        v_outcome := 'amount_mismatch';
      else
        update public.project_payments
           set status = 'paid', paid_at = now(), gateway_reference = p_gateway_reference
         where id = p_project_payment_id;
        v_outcome := 'applied';
      end if;

    elsif p_event_type = 'payment.failed' then
      if v_payment.status = 'processing' and v_payment.gateway_reference = p_gateway_reference then
        update public.project_payments
           set status = 'failed', gateway_reference = null
         where id = p_project_payment_id;
        v_outcome := 'applied';
      end if;

    elsif p_event_type = 'refund.succeeded' then
      if v_payment.status = 'paid' then
        update public.project_payments
           set status = 'refunded', refunded_at = now()
         where id = p_project_payment_id;
        v_outcome := 'applied';
      end if;
    end if;
  end if;

  update public.payment_events set outcome = v_outcome where id = v_event_id;
  return v_outcome;
end;
$$;
;
