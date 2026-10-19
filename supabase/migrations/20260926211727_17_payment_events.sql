-- =====================================================================
-- 17_payment_events.sql  ·  payment gateway webhooks (server only)
--
-- Review fix #2: money only moves when the payment gateway says so.
-- Your server (an Edge Function holding the service_role key and the
-- gateway secret) verifies the webhook signature, then calls
-- record_payment_event(). Each gateway event id is stored once, so a
-- replayed webhook can't pay twice, and the amount must match what
-- the database expects. Clients can't execute these functions.
-- =====================================================================

create table public.payment_events (
  id                 bigint generated always as identity primary key,
  -- The gateway's own event id: the idempotency key for webhooks.
  gateway_event_id   text not null unique check (char_length(gateway_event_id) between 1 and 200),
  event_type         text not null
                     check (event_type in ('payment.succeeded', 'payment.failed', 'refund.succeeded')),
  order_id           uuid references public.orders (id) on delete restrict,
  project_payment_id uuid references public.project_payments (id) on delete restrict,
  amount             numeric(14, 2) not null check (amount >= 0),
  currency           char(3) not null check (currency ~ '^[A-Z]{3}$'),
  gateway_reference  text check (gateway_reference is null or char_length(gateway_reference) <= 200),
  outcome            text not null default 'ignored'
                     check (outcome in ('applied', 'ignored', 'amount_mismatch', 'needs_refund')),
  received_at        timestamptz not null default now(),
  constraint payment_events_one_subject check (num_nonnulls(order_id, project_payment_id) = 1)
);

comment on table public.payment_events is
  'Webhook log. One row per gateway event id. needs_refund / amount_mismatch rows need an admin.';

create index payment_events_order_id_idx on public.payment_events (order_id);
create index payment_events_project_payment_id_idx on public.payment_events (project_payment_id);
create index payment_events_attention_idx on public.payment_events (received_at)
  where outcome in ('amount_mismatch', 'needs_refund');

-- ---------------------------------------------------------------------
-- Server-only RPCs (service_role)
-- ---------------------------------------------------------------------

-- processTransaction(), step 1: after creating the payment at the
-- gateway (send idempotency_key with that request), store its id.
create or replace function public.attach_payment_intent(
  p_gateway_reference text,
  p_order_id uuid default null,
  p_project_payment_id uuid default null
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

  if p_order_id is not null then
    update public.orders
       set gateway_reference = p_gateway_reference
     where id = p_order_id
       and status = 'pending_payment'
       and (gateway_reference is null or gateway_reference = p_gateway_reference);
  else
    update public.project_payments
       set gateway_reference = p_gateway_reference,
           status = 'processing'
     where id = p_project_payment_id
       and status in ('pending', 'failed', 'processing')
       and (gateway_reference is null or gateway_reference = p_gateway_reference);
  end if;
  if not found then
    raise exception 'Nothing is awaiting payment there, or another payment is already in progress'
      using errcode = 'P0001';
  end if;
end;
$$;

-- processTransaction() step 2 / confirmPayment() / issueRefund():
-- apply a verified gateway event. Returns the outcome.
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
         or (v_order.gateway_reference is not null and v_order.gateway_reference <> p_gateway_reference) then
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
      if v_payment.status not in ('pending', 'processing', 'failed') then
        v_outcome := case when v_payment.status = 'cancelled' then 'needs_refund' else 'ignored' end;
      elsif round(p_amount, 2) <> v_payment.amount
         or v_currency <> v_payment.currency
         or (v_payment.gateway_reference is not null and v_payment.gateway_reference <> p_gateway_reference) then
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

revoke all on function public.attach_payment_intent(text, uuid, uuid) from public, anon, authenticated;
revoke all on function public.record_payment_event(text, text, numeric, text, text, uuid, uuid, text, text)
  from public, anon, authenticated;
grant execute on function public.attach_payment_intent(text, uuid, uuid) to service_role;
grant execute on function public.record_payment_event(text, text, numeric, text, text, uuid, uuid, text, text)
  to service_role;

-- ---------------------------------------------------------------------
-- Row level security (admins read; nobody writes from the app)
-- ---------------------------------------------------------------------
alter table public.payment_events enable row level security;

create policy payment_events_select_admin
  on public.payment_events for select
  to authenticated
  using ((select private.is_admin()));

revoke all on table public.payment_events from anon, authenticated;
grant select on table public.payment_events to authenticated;
;
