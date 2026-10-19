create or replace function blockchain_sync.snapshot(p_project_id uuid)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare
  v jsonb;
begin
  select jsonb_build_object(
           'id',              p.id,
           'owner',           left(u.full_name, 500),
           'ownerId',         p.owner_id,
           'ownerEmail',      lower(btrim(au.email)),
           'contractor',      left(b.company_name, 500),
           'contractorId',    p.taker_id,
           'contractorEmail', lower(btrim(tu.email)),
           'agreedPrice',     o.amount,
           'currency',        'SAR',
           'milestone',  coalesce((select jsonb_agg(jsonb_strip_nulls(jsonb_build_object(
                                      'description', t.description,
                                      'startDate',   t.start_date,
                                      'finishDate',  t.finish_date,
                                      'status',      t.status)) order by t.created_at, t.id)
                                     from public.project_tasks t where t.project_id = p.id), '[]'::jsonb),
           'payments',   coalesce((select jsonb_agg(jsonb_strip_nulls(jsonb_build_object(
                                      'id',     x.id,
                                      'amount', x.amount,
                                      'date',   (coalesce(x.paid_at, x.updated_at) at time zone 'Asia/Riyadh')::date,
                                      'note',   left(nullif(btrim(x.description), ''), 500)))
                                    order by coalesce(x.paid_at, x.updated_at), x.stage_number, x.id)
                                     from public.project_payments x
                                    where x.project_id = p.id and x.status = 'paid'), '[]'::jsonb))
    into v
    from public.projects p
    join public.users u      on u.id = p.owner_id
    join public.businesses b on b.user_id = p.taker_id
    left join auth.users au  on au.id = p.owner_id
    left join auth.users tu  on tu.id = p.taker_id
    join lateral (select po.amount from public.project_offers po
                   where po.project_id = p.id and po.status = 'accepted'
                   order by po.decided_at desc nulls last limit 1) o on true
   where p.id = p_project_id and p.taker_id is not null;
  return v;
end $$;

create or replace function blockchain_sync.on_auth_user_email_change()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  r record;
begin
  if new.email is distinct from old.email then
    for r in select p.id from public.projects p where p.owner_id = new.id or p.taker_id = new.id loop
      perform blockchain_sync.mark(r.id);
    end loop;
  end if;
  return null;
exception when others then
  raise warning 'blockchain_sync.on_auth_user_email_change failed: %', sqlerrm;
  return null;
end $$;

revoke all on function blockchain_sync.on_auth_user_email_change() from public, anon, authenticated;

drop trigger if exists blockchain_sync_auth_email on auth.users;
create trigger blockchain_sync_auth_email after update of email on auth.users
  for each row execute function blockchain_sync.on_auth_user_email_change();

select blockchain_sync.resync();
;
