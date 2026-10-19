-- =====================================================================
-- 14_reviews.sql  ·  ratings between people who actually did business
--
-- Review fixes here:
--   #4  reviewer_id is always the signed-in user.
--   #6  every review is tied to exactly one completed project or
--       delivered order, and the target must be the other party
--       (validateContext). One review per reviewer per project/order,
--       no self-reviews, rating 1-5.
--   #8  ON DELETE RESTRICT.   #13 timestamps.
-- =====================================================================

create table public.reviews (
  id             uuid primary key default gen_random_uuid(),
  reviewer_id    uuid not null default auth.uid()
                 references public.users (id) on delete restrict,
  target_user_id uuid not null references public.users (id) on delete restrict,
  project_id     uuid references public.projects (id) on delete restrict,
  order_id       uuid references public.orders (id) on delete restrict,
  rating         smallint not null check (rating between 1 and 5),
  comment        text check (comment is null or char_length(comment) <= 2000),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  constraint reviews_one_context check (num_nonnulls(project_id, order_id) = 1),
  constraint reviews_not_self check (reviewer_id <> target_user_id),
  constraint reviews_once_per_project unique (reviewer_id, project_id),
  constraint reviews_once_per_order unique (reviewer_id, order_id)
);

comment on table public.reviews is
  'Insert {target_user_id, project_id | order_id, rating, comment}. Allowed only between the two parties of a completed project or delivered order.';

create index reviews_target_user_id_idx on public.reviews (target_user_id, created_at desc);
create index reviews_project_id_idx on public.reviews (project_id);
create index reviews_order_id_idx on public.reviews (order_id);

create trigger reviews_set_updated_at
  before update on public.reviews
  for each row execute function private.set_updated_at();

-- validateContext(): the reviewer and target are the two parties of a
-- finished job or order.
create or replace function private.is_valid_review_context(
  p_reviewer uuid,
  p_target uuid,
  p_project_id uuid,
  p_order_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when p_project_id is not null then exists (
      select 1 from public.projects p
      where p.id = p_project_id
        and p.status = 'completed'
        and ((p.owner_id = p_reviewer and p.taker_id = p_target)
          or (p.taker_id = p_reviewer and p.owner_id = p_target))
    )
    when p_order_id is not null then exists (
      select 1 from public.orders o
      where o.id = p_order_id
        and o.status = 'delivered'
        and ((o.buyer_id = p_reviewer and o.seller_id = p_target)
          or (o.seller_id = p_reviewer and o.buyer_id = p_target))
    )
    else false
  end;
$$;

revoke all on function private.is_valid_review_context(uuid, uuid, uuid, uuid) from public;
grant execute on function private.is_valid_review_context(uuid, uuid, uuid, uuid) to authenticated, service_role;

-- ---------------------------------------------------------------------
-- Row level security + column grants
-- ---------------------------------------------------------------------
alter table public.reviews enable row level security;

-- Reputation is public to signed-in users.
create policy reviews_select
  on public.reviews for select
  to authenticated
  using (true);

create policy reviews_insert_party
  on public.reviews for insert
  to authenticated
  with check (
    reviewer_id = (select auth.uid())
    and (select private.is_active_user())
    and private.is_valid_review_context((select auth.uid()), target_user_id, project_id, order_id)
  );

create policy reviews_update_own
  on public.reviews for update
  to authenticated
  using (reviewer_id = (select auth.uid()))
  with check (reviewer_id = (select auth.uid()));

-- A reported review can't be deleted (help_reports holds a restrict FK).
create policy reviews_delete_own
  on public.reviews for delete
  to authenticated
  using (reviewer_id = (select auth.uid()));

revoke all on table public.reviews from anon, authenticated;
grant select, delete on table public.reviews to authenticated;
grant insert (target_user_id, project_id, order_id, rating, comment) on table public.reviews to authenticated;
grant update (rating, comment) on table public.reviews to authenticated;
;
