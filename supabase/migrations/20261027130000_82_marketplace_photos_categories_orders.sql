-- =====================================================================
-- 82_marketplace_photos_categories_orders.sql  ·  the marketplace backend (GRA-65)
--
-- What the marketplace screens need (GRA-66, 67, 68, 70, 71). The
-- marketplace is off-chain: nothing here reaches the blockchain (golden
-- rule 4).
--   1. Categories: the marketplace_category enum and
--      marketplace_items.category (default 'other'), set by the seller.
--   2. Photos: marketplace_item_photos (item, position, storage_path), up
--      to 6 per item, in the public `images` bucket under
--      `<seller id>/marketplace/<item id>/`. Written only by
--      set_marketplace_item_photos(), by the seller, while the item isn't
--      deleted or removed by an admin.
--   3. Delivery address: orders.delivery_address, a copy of the buyer's
--      address taken at checkout (like order_items.price_at_purchase).
--      checkout() gains p_address_id; the old version is dropped.
--   4. Order notifications: order_paid (to the seller), order_shipped (to
--      the buyer), order_delivered and order_cancelled (to the other
--      party), the same way as the message notification (migration 68).
--   5. Demo payment: simulate_order_payment(). DEMO ONLY, no real money:
--      it pays an order through record_payment_event(), as the gateway
--      webhook would. A real gateway replaces it (ARCHITECTURE.md §15).
--   6. Views: v_marketplace_items and v_admin_marketplace_items get
--      category and photo_paths; v_my_orders gets delivery_address. All at
--      the end, as create or replace view only adds columns there.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Categories
-- ---------------------------------------------------------------------

create type public.marketplace_category as enum (
  'building_materials',   -- مواد البناء
  'steel_metals',         -- الحديد والمعادن
  'wood',                 -- الأخشاب
  'tools_equipment',      -- الأدوات والمعدات
  'electrical_lighting',  -- الكهرباء والإنارة
  'plumbing_sanitary',    -- السباكة والأدوات الصحية
  'paints',               -- الدهانات
  'insulation',           -- العزل
  'flooring_tiles',       -- الأرضيات والبلاط
  'doors_windows',        -- الأبواب والنوافذ
  'hvac',                 -- التكييف والتهوية
  'safety',               -- الأمن والسلامة
  'outdoor',              -- الحدائق والمظلات
  'other'                 -- أخرى
);

alter table public.marketplace_items
  add column category public.marketplace_category not null default 'other';

comment on column public.marketplace_items.category is
  'What kind of item it is; the seller sets it. Existing items are other.';

create index marketplace_items_category_live_idx
  on public.marketplace_items (category, created_at desc)
  where is_active and deleted_at is null;

-- The seller sets it like the other listing columns (ARCHITECTURE.md §3a).
grant insert (category) on table public.marketplace_items to authenticated;
grant update (category) on table public.marketplace_items to authenticated;

-- ---------------------------------------------------------------------
-- 2. Photos
-- ---------------------------------------------------------------------

create table public.marketplace_item_photos (
  item_id      uuid not null
               references public.marketplace_items (id) on delete restrict,
  position     smallint not null check (position between 0 and 5),
  storage_path text not null
               check (
                 char_length(storage_path) <= 500
                 and strpos(storage_path, '..') = 0
                 and storage_path like '%/marketplace/' || item_id::text || '/_%'
               ),
  created_at   timestamptz not null default now(),
  primary key (item_id, position),
  unique (item_id, storage_path)
);

comment on table public.marketplace_item_photos is
  'Up to 6 photos per item, in order (position 0 first): paths in the public images bucket, <seller id>/marketplace/<item id>/<file>. Written only by set_marketplace_item_photos().';

alter table public.marketplace_item_photos enable row level security;

-- Whoever can see the item can see its photos (the items' own policy
-- applies inside the subquery).
create policy marketplace_item_photos_select
  on public.marketplace_item_photos for select
  to authenticated
  using (
    exists (
      select 1 from public.marketplace_items i
       where i.id = marketplace_item_photos.item_id
    )
  );

revoke all on table public.marketplace_item_photos from public, anon, authenticated;
grant select on table public.marketplace_item_photos to authenticated;

-- The item's photos become exactly p_paths, in that order. Upload the
-- files first; an empty array removes every photo.
create function public.set_marketplace_item_photos(
  p_item_id uuid,
  p_paths   text[]
)
returns void
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_uid   uuid := private.require_active_user();
  v_item  public.marketplace_items;
  v_paths text[] := coalesce(p_paths, '{}');
  v_path  text;
begin
  select * into v_item from public.marketplace_items where id = p_item_id for update;
  if not found or v_item.seller_id <> v_uid then
    raise exception 'item_not_found' using errcode = 'P0002';
  end if;
  if v_item.deleted_at is not null or v_item.removed_at is not null then
    raise exception 'item_not_editable' using errcode = '42501';
  end if;
  if cardinality(v_paths) > 6 then
    raise exception 'too_many_photos' using errcode = '22023';
  end if;
  if (select count(distinct p) from unnest(v_paths) as p) <> cardinality(v_paths) then
    raise exception 'duplicate_photo' using errcode = '22023';
  end if;

  foreach v_path in array v_paths loop
    if v_path is null
       or char_length(v_path) > 500
       or strpos(v_path, '..') > 0
       or v_path not like v_uid::text || '/marketplace/' || p_item_id::text || '/_%' then
      raise exception 'invalid_photo_path' using errcode = '22023';
    end if;
    if not exists (
      select 1 from storage.objects o
       where o.bucket_id = 'images'
         and o.name = v_path
    ) then
      raise exception 'photo_not_uploaded' using errcode = '22023';
    end if;
  end loop;

  delete from public.marketplace_item_photos where item_id = p_item_id;
  insert into public.marketplace_item_photos (item_id, position, storage_path)
  select p_item_id, (t.n - 1)::smallint, t.path
    from unnest(v_paths) with ordinality as t (path, n);
end;
$$;

revoke all on function public.set_marketplace_item_photos(uuid, text[]) from public, anon;
grant execute on function public.set_marketplace_item_photos(uuid, text[]) to authenticated;

-- ---------------------------------------------------------------------
-- 3. Delivery address and checkout()
-- ---------------------------------------------------------------------

alter table public.orders
  add column delivery_address jsonb
  check (delivery_address is null or jsonb_typeof(delivery_address) = 'object');

comment on column public.orders.delivery_address is
  'The buyer''s address as it was at checkout: name, city, district, street, building_number, postal_code, formatted_address. Editing or deleting the saved address never changes it. Null on orders from before migration 82.';

-- A new parameter is a new signature: drop the old one first, so PostgREST
-- keeps one checkout.
drop function if exists public.checkout(jsonb, public.payment_method);

-- supabase.rpc('checkout', params: {
--   'p_items': [{'item_id': '...', 'quantity': 2}, ...],
--   'p_payment_method': 'mada',
--   'p_address_id': '...' })  -> new order id
create function public.checkout(
  p_items          jsonb,
  p_payment_method public.payment_method,
  p_address_id     uuid
)
returns uuid
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_buyer       uuid := private.require_active_user();
  v_order_id    uuid := gen_random_uuid();
  v_seller      uuid;
  v_total       numeric(14, 2) := 0;
  v_line        record;
  v_price       numeric(12, 2);
  v_name        text;
  v_item_seller uuid;
  v_item_ids    uuid[] := '{}';
  v_names       text[] := '{}';
  v_qtys        integer[] := '{}';
  v_prices      numeric[] := '{}';
  v_address     jsonb;
begin
  if p_payment_method is null then
    raise exception 'Choose a payment method' using errcode = '22023';
  end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'The cart is empty' using errcode = '22023';
  end if;
  if jsonb_array_length(p_items) > 50 then
    raise exception 'An order can have at most 50 lines' using errcode = '22023';
  end if;
  if p_address_id is null then
    raise exception 'address_required' using errcode = '22023';
  end if;

  -- A copy of the buyer's own address; anyone else's is not found.
  select jsonb_build_object(
           'name',              a.name,
           'city',              a.city,
           'district',          a.district,
           'street',            a.street,
           'building_number',   a.building_number,
           'postal_code',       a.postal_code,
           'formatted_address', private.format_address(
                                  a.building_number, a.street, a.district,
                                  a.city, a.postal_code))
    into v_address
    from public.addresses a
   where a.id = p_address_id
     and a.owner_id = v_buyer;
  if v_address is null then
    raise exception 'address_not_found' using errcode = 'P0002';
  end if;

  -- One checkout at a time per buyer, so the unpaid-order cap is exact.
  perform 1 from public.users where id = v_buyer for update;
  if (select count(*) from public.orders
      where buyer_id = v_buyer and status = 'pending_payment') >= 5 then
    raise exception 'You have 5 unpaid orders; pay or cancel one first' using errcode = 'P0001';
  end if;

  for v_line in
    select (e ->> 'item_id')::uuid as item_id,
           sum((e ->> 'quantity')::integer) as quantity
    from jsonb_array_elements(p_items) as e
    group by 1
    order by 1            -- same lock order in every checkout: no deadlocks
  loop
    if v_line.item_id is null or v_line.quantity is null
       or v_line.quantity <= 0 or v_line.quantity > 10000 then
      raise exception 'Every line needs an item_id and a quantity between 1 and 10000'
        using errcode = '22023';
    end if;

    -- Atomic reservation: succeeds only if the stock is there right now,
    -- and the price comes from the listing, never from the client.
    update public.marketplace_items
       set stock_quantity = stock_quantity - v_line.quantity
     where id = v_line.item_id
       and is_active
       and deleted_at is null
       and stock_quantity >= v_line.quantity
    returning price, item_name, seller_id
      into v_price, v_name, v_item_seller;

    if not found then
      raise exception 'Item % is unavailable or does not have enough stock', v_line.item_id
        using errcode = 'P0001';
    end if;
    if v_item_seller = v_buyer then
      raise exception 'You cannot buy your own item' using errcode = 'P0001';
    end if;
    if v_seller is null then
      v_seller := v_item_seller;
    elsif v_seller <> v_item_seller then
      raise exception 'All items in one order must come from the same seller' using errcode = 'P0001';
    end if;

    v_item_ids := v_item_ids || v_line.item_id;
    v_names    := v_names || v_name;
    v_qtys     := v_qtys || v_line.quantity::integer;
    v_prices   := v_prices || v_price;
    v_total    := v_total + v_price * v_line.quantity;
  end loop;

  if not exists (select 1 from public.users where id = v_seller and deleted_at is null) then
    raise exception 'The seller''s account is closed' using errcode = 'P0001';
  end if;

  insert into public.orders (id, buyer_id, seller_id, payment_method, total_amount, delivery_address)
  values (v_order_id, v_buyer, v_seller, p_payment_method, v_total, v_address);

  insert into public.order_items (order_id, item_id, item_name, quantity, price_at_purchase)
  select v_order_id, t.item_id, t.item_name, t.quantity, t.price
  from unnest(v_item_ids, v_names, v_qtys, v_prices) as t (item_id, item_name, quantity, price);

  return v_order_id;
end;
$$;

revoke all on function public.checkout(jsonb, public.payment_method, uuid) from public, anon;
grant execute on function public.checkout(jsonb, public.payment_method, uuid) to authenticated;

-- ---------------------------------------------------------------------
-- 4. Order notifications
-- ---------------------------------------------------------------------

-- Nobody is told about what they did themselves (auth.uid()). An order the
-- server cancels (expire_stale_orders, no signed-in user) tells both.
create or replace function private.notify_order_status()
returns trigger
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_actor uuid := auth.uid();
  v_type  text;
  v_title text;
  v_pop   boolean := true;
  v_to    uuid[];
  v_user  uuid;
  v_items text;
begin
  if new.status is not distinct from old.status then
    return null;
  end if;

  case new.status
    when 'paid' then
      v_type := 'order_paid';
      v_title := 'طلب جديد مدفوع';
      v_to := array[new.seller_id];
    when 'shipped' then
      v_type := 'order_shipped';
      v_title := 'تم شحن طلبك';
      v_to := array[new.buyer_id];
    when 'delivered' then
      v_type := 'order_delivered';
      v_title := 'تم تسليم الطلب';
      v_to := array[new.buyer_id, new.seller_id];
    when 'cancelled' then
      v_type := 'order_cancelled';
      v_title := 'تم إلغاء الطلب';
      v_to := array[new.buyer_id, new.seller_id];
      -- Like a rejected offer: it shows in the list, without popping up.
      v_pop := false;
    else
      return null;
  end case;

  -- «<first item>», or «<first item> وغيرها» for more than one line.
  select coalesce(nullif(btrim(min(oi.item_name)), ''), 'طلب')
           || case when count(*) > 1 then ' وغيرها' else '' end
    into v_items
    from public.order_items oi
   where oi.order_id = new.id;

  foreach v_user in array v_to loop
    if v_user is distinct from v_actor then
      perform private.notify(
        v_user,
        v_title,
        coalesce(v_items, 'طلب'),
        jsonb_build_object('type', v_type, 'order_id', new.id),
        v_pop);
    end if;
  end loop;
  return null;
exception when others then
  raise warning 'private.notify_order_status(%) failed: %', new.id, sqlerrm;
  return null;
end;
$$;

revoke all on function private.notify_order_status() from public, anon, authenticated;

create trigger notifications_order_status
  after update of status on public.orders
  for each row execute function private.notify_order_status();

-- ---------------------------------------------------------------------
-- 5. Demo payment (proof of concept, no real money)
-- ---------------------------------------------------------------------

-- DEMO ONLY. The buyer "pays" an order awaiting payment with a pretend
-- card: only its brand and last 4 digits, never a full number or CVV.
-- p_succeed = true pays it through record_payment_event(), exactly as the
-- gateway webhook would: paid_at, a DEMO-… reference, the card, the status
-- history and order_paid. p_succeed = false raises payment_declined and
-- the order stays unpaid. A real gateway replaces this function
-- (ARCHITECTURE.md §15).
create function public.simulate_order_payment(
  p_order_id   uuid,
  p_card_brand text,
  p_card_last4 text,
  p_succeed    boolean
)
returns void
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_uid     uuid := private.require_active_user();
  v_order   public.orders;
  v_brand   text := nullif(btrim(p_card_brand), '');
  v_outcome text;
begin
  select * into v_order from public.orders where id = p_order_id for update;
  if not found or v_order.buyer_id <> v_uid then
    raise exception 'order_not_found' using errcode = 'P0002';
  end if;
  if v_order.status <> 'pending_payment' then
    raise exception 'order_not_awaiting_payment' using errcode = '40001';
  end if;
  if v_order.payment_method = 'bank_transfer' then
    raise exception 'not_a_card_payment' using errcode = '22023';
  end if;
  if v_brand is null or char_length(v_brand) > 30 then
    raise exception 'invalid_card_brand' using errcode = '22023';
  end if;
  if p_card_last4 is null or p_card_last4 !~ '^[0-9]{4}$' then
    raise exception 'invalid_card_last4' using errcode = '22023';
  end if;

  if p_succeed is not true then
    raise exception 'payment_declined' using errcode = 'P0001';
  end if;

  v_outcome := public.record_payment_event(
    p_gateway_event_id  => 'demo-' || gen_random_uuid()::text,
    p_event_type        => 'payment.succeeded',
    p_amount            => v_order.total_amount,
    p_currency          => v_order.currency,
    p_gateway_reference => 'DEMO-' || upper(replace(gen_random_uuid()::text, '-', '')),
    p_order_id          => p_order_id,
    p_card_brand        => v_brand,
    p_card_last4        => p_card_last4);
  if v_outcome <> 'applied' then
    raise exception 'payment_not_applied' using errcode = '40001';
  end if;
end;
$$;

comment on function public.simulate_order_payment(uuid, text, text, boolean) is
  'DEMO ONLY, no real money: pays an order as the gateway webhook would. Replace with a real gateway (ARCHITECTURE.md §15).';

revoke all on function public.simulate_order_payment(uuid, text, text, boolean) from public, anon;
grant execute on function public.simulate_order_payment(uuid, text, text, boolean) to authenticated;

-- ---------------------------------------------------------------------
-- 6. Views
-- ---------------------------------------------------------------------

create or replace view public.v_marketplace_items
with (security_invoker = true) as
select i.id,
       i.item_name,
       i.description,
       i.price,
       i.stock_quantity,
       i.stock_quantity > 0 as in_stock,
       i.is_active,
       i.created_at,
       i.updated_at,
       i.seller_id,
       s.display_name as seller_name,
       s.avatar_path as seller_avatar_path,
       s.is_verified_business as seller_is_verified_business,
       s.rating_avg as seller_rating_avg,
       s.rating_count as seller_rating_count,
       i.seller_id = (select auth.uid()) as is_mine,
       i.removed_at,
       i.removal_reason,
       i.category,
       coalesce(
         (select array_agg(ph.storage_path order by ph.position)
            from public.marketplace_item_photos ph
           where ph.item_id = i.id),
         '{}'::text[]) as photo_paths
  from public.marketplace_items i
  join public.v_public_profiles s on s.id = i.seller_id
 where i.deleted_at is null
   and (i.is_active or i.seller_id = (select auth.uid()));

create or replace view public.v_admin_marketplace_items
with (security_invoker = true) as
select i.id,
       i.item_name,
       i.description,
       i.price,
       i.stock_quantity,
       i.is_active,
       case
         when i.removed_at is not null then 'removed'
         when not i.is_active then 'hidden'
         when i.stock_quantity <= 0 then 'out_of_stock'
         else 'live'
       end as status,
       i.created_at,
       i.updated_at,
       i.seller_id,
       s.display_name as seller_name,
       s.avatar_path as seller_avatar_path,
       s.is_verified_business as seller_is_verified_business,
       s.rating_avg as seller_rating_avg,
       s.rating_count as seller_rating_count,
       i.removed_at,
       i.removal_reason,
       rb.full_name as removed_by_name,
       (select count(distinct oi.order_id)::integer
          from public.order_items oi
         where oi.item_id = i.id) as order_count,
       (select count(*)::integer
          from public.help_reports h
         where h.target_item_id = i.id
           and h.status in ('open', 'in_review')) as open_report_count,
       i.category,
       coalesce(
         (select array_agg(ph.storage_path order by ph.position)
            from public.marketplace_item_photos ph
           where ph.item_id = i.id),
         '{}'::text[]) as photo_paths
  from public.marketplace_items i
  join public.v_public_profiles s on s.id = i.seller_id
  left join public.users rb on rb.id = i.removed_by
 where i.deleted_at is null
   and (select private.is_admin());

create or replace view public.v_my_orders
with (security_invoker = true) as
select o.id,
       o.status,
       o.payment_method,
       o.total_amount,
       o.currency,
       o.card_brand,
       o.card_last4,
       o.paid_at,
       o.created_at,
       o.updated_at,
       case
         when o.buyer_id = (select auth.uid()) then 'buyer'
         else 'seller'
       end as my_role,
       o.buyer_id,
       bu.full_name as buyer_name,
       bu.avatar_path as buyer_avatar_path,
       o.seller_id,
       su.full_name as seller_name,
       su.avatar_path as seller_avatar_path,
       li.line_count,
       li.unit_count,
       o.status = 'delivered'
         and not exists (
           select 1 from public.reviews r
            where r.order_id = o.id
              and r.reviewer_id = (select auth.uid())
         ) as can_review,
       o.delivery_address
  from public.orders o
  join public.users bu on bu.id = o.buyer_id
  join public.users su on su.id = o.seller_id
  left join lateral (
    select count(*)::integer as line_count,
           coalesce(sum(oi.quantity), 0)::integer as unit_count
      from public.order_items oi
     where oi.order_id = o.id
  ) li on true
 where o.buyer_id = (select auth.uid())
    or o.seller_id = (select auth.uid());
