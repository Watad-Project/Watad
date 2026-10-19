-- =====================================================================
-- 51_project_payment_methods.sql  ·  how a project stage is paid
--
-- Feature: a stage is paid one of three ways —
--   gateway        through the payment gateway
--   wallet         through the integrated wallet
--   bank_transfer  the client transfers to the contractor and uploads the
--                  receipt; the contractor confirms it (file 52)
--
--   1. project_payment_method enum + project_payments.method, set when a
--      payment starts (null while nothing is in flight).
--   2. attach_payment_intent() gains p_method ('gateway' or 'wallet';
--      project payments only) and refuses a stage whose bank transfer is
--      waiting for the contractor.
--   3. record_payment_event(): gateway money for a stage that is being,
--      or already was, paid by bank transfer is flagged 'needs_refund',
--      never applied. An applied payment keeps its method ('gateway' if
--      none was set).
--
-- Replaces attach_payment_intent (17_payment_events.sql) and
-- record_payment_event (37_fix_cancelled_project_payments.sql).
-- =====================================================================

create type public.project_payment_method as enum ('gateway', 'wallet', 'bank_transfer');

alter table public.project_payments
  add column method public.project_payment_method;

comment on column public.project_payments.method is
  'How the stage is being or was paid; null while nothing is in flight. Set by attach_payment_intent() (gateway, wallet) or submit_bank_transfer().';

-- The signature changes, so the old function goes first (no overloads).
drop function public.attach_payment_intent(text, uuid, uuid);

-- Server only. p_method applies to project payments; orders keep the
-- method chosen at checkout.
create function public.attach_payment_intent(
  p_gateway_reference text,
  p_order_id uuid default null,
  p_project_payment_id uuid default null,
  p_method public.project_payment_method default 'gateway'
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if num_nonnulls(p_order_id, p_project_payment_id) <> 1 or coalesce(p_gateway_reference, '') = '' then
    raise exception 'Give a gateway reference and exactly one of p_order_id / p_project_payment_id'
      using errcode = '22023';
  end if;
  if p_method is null or p_method = 'bank_transfer' then
    raise exception 'p_method is gateway or wallet; bank transfers go through submit_bank_transfer()'
      using errcode = '22023';
  end if;

  if p_order_id is not null then
    update public.orders
       set gateway_reference = p_gateway_reference
     where id = p_order_id
       and status = 'pending_payment'
       and (gateway_reference is null or gateway_reference = p_gateway_reference);
  else
    update public.project_payments
       set gateway_reference = p_gateway_reference,
           status = 'processing',
           method = p_method
     where id = p_project_payment_id
       and status in ('pending', 'failed', 'processing')
       and (gateway_reference is null or gateway_reference = p_gateway_reference)
       -- A bank transfer waiting for the contractor blocks other methods.
       and (status <> 'processing' or method is distinct from 'bank_transfer');
  end if;
  if not found then
    raise exception 'Nothing is awaiting payment there, or another payment is already in progress'
      using errcode = 'P0001';
  end if;
end;
$$;

revoke all on function public.attach_payment_intent(text, uuid, uuid, public.project_payment_method) from public, anon, authenticated;
grant execute on function public.attach_payment_intent(text, uuid, uuid, public.project_payment_method) to service_role;

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
      -- One payment per stage: a bank transfer is waiting for the
      -- contractor, or already settled the stage.
      elsif v_payment.method = 'bank_transfer' and v_payment.status in ('processing', 'paid') then
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
           set status = 'paid',
               paid_at = now(),
               gateway_reference = p_gateway_reference,
               method = coalesce(method, 'gateway')
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
