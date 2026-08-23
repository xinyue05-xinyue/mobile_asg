create table if not exists public.reward_items (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text not null,
  category text not null check (category in ('voucher', 'merchandise')),
  points_cost integer not null check (points_cost > 0),
  stock_quantity integer not null default 0 check (stock_quantity >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.reward_redemptions (
  id uuid primary key default gen_random_uuid(),
  donor_id uuid not null references public.profiles(id) on delete cascade,
  reward_item_id uuid not null references public.reward_items(id),
  points_spent integer not null check (points_spent > 0),
  redemption_code text not null unique,
  status text not null default 'issued'
    check (status in ('issued', 'collected', 'cancelled')),
  created_at timestamptz not null default now()
);

alter table public.reward_items enable row level security;
alter table public.reward_redemptions enable row level security;

grant select on public.reward_items to authenticated;
grant select on public.reward_redemptions to authenticated;
revoke insert, update, delete on public.reward_redemptions from authenticated;

drop policy if exists reward_items_read on public.reward_items;
create policy reward_items_read on public.reward_items
for select to authenticated using (is_active or public.is_system_admin());

drop policy if exists reward_redemptions_read on public.reward_redemptions;
create policy reward_redemptions_read on public.reward_redemptions
for select to authenticated using (
  donor_id = auth.uid() or public.is_system_admin()
);

insert into public.reward_items
  (id, name, description, category, points_cost, stock_quantity)
values
  ('10000000-0000-0000-0000-000000000001', 'RM5 Healthy Meal Voucher',
   'RM5 voucher from a participating healthy-food partner.', 'voucher', 200, 100),
  ('10000000-0000-0000-0000-000000000002', 'MyDarah Tote Bag',
   'Reusable MyDarah canvas tote bag. Collect from the organiser.', 'merchandise', 300, 50),
  ('10000000-0000-0000-0000-000000000003', 'MyDarah Donor T-shirt',
   'Limited-edition donor T-shirt. Size is confirmed during collection.', 'merchandise', 500, 30),
  ('10000000-0000-0000-0000-000000000004', 'RM20 Pharmacy Voucher',
   'RM20 voucher from a participating pharmacy.', 'voucher', 800, 40)
on conflict (id) do update set
  name = excluded.name,
  description = excluded.description,
  category = excluded.category,
  points_cost = excluded.points_cost,
  is_active = true;

create or replace function public.redeem_reward(p_reward_item_id uuid)
returns table (
  redemption_id uuid,
  redemption_code text,
  remaining_points integer
)
language plpgsql
security definer
set search_path = public
as $$
declare
  selected_item public.reward_items%rowtype;
  current_points integer;
  new_redemption_id uuid;
  new_code text;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  select * into selected_item
  from public.reward_items
  where id = p_reward_item_id and is_active
  for update;

  if not found then raise exception 'Reward is not available'; end if;
  if selected_item.stock_quantity <= 0 then raise exception 'Reward is out of stock'; end if;

  select coalesce(sum(points), 0)::integer into current_points
  from public.reward_transactions
  where donor_id = auth.uid();

  if current_points < selected_item.points_cost then
    raise exception 'Not enough reward points';
  end if;

  new_code := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10));
  insert into public.reward_redemptions (
    donor_id, reward_item_id, points_spent, redemption_code
  ) values (
    auth.uid(), selected_item.id, selected_item.points_cost, new_code
  ) returning id into new_redemption_id;

  insert into public.reward_transactions (donor_id, points, transaction_type)
  values (auth.uid(), -selected_item.points_cost, 'redeemed');

  update public.reward_items
  set stock_quantity = stock_quantity - 1
  where id = selected_item.id;

  return query select
    new_redemption_id,
    new_code,
    current_points - selected_item.points_cost;
end;
$$;

revoke all on function public.redeem_reward(uuid) from public;
grant execute on function public.redeem_reward(uuid) to authenticated;

create index if not exists reward_redemptions_donor_idx
on public.reward_redemptions(donor_id, created_at desc);
