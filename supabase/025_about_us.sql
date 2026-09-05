create table if not exists public.about_us (
  id smallint primary key default 1 check (id = 1),
  title text not null check (char_length(trim(title)) between 1 and 100),
  content text not null check (char_length(trim(content)) between 1 and 10000),
  updated_at timestamptz not null default now()
);

insert into public.about_us (id, title, content)
values (
  1,
  'About MyDarah',
  E'MyDarah connects donors, blood-donation organisations, and hospitals in one place. The app helps donors discover donation opportunities, respond to emergency blood requests, track verified donations, and receive rewards for their contribution.\n\nOur goal is to make blood donation more accessible, organised, and timely for the community.'
)
on conflict (id) do nothing;

alter table public.about_us enable row level security;
grant select, update on public.about_us to authenticated;
revoke insert, delete on public.about_us from authenticated;

drop policy if exists about_us_read on public.about_us;
create policy about_us_read on public.about_us
for select to authenticated
using (true);

drop policy if exists about_us_system_admin_update on public.about_us;
create policy about_us_system_admin_update on public.about_us
for update to authenticated
using (public.is_system_admin())
with check (public.is_system_admin() and id = 1);
