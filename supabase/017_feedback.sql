create table if not exists public.feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  category text not null check (category in ('general', 'bug', 'suggestion', 'service')),
  message text not null check (char_length(trim(message)) between 10 and 2000),
  status text not null default 'open' check (status in ('open', 'reviewed', 'resolved')),
  admin_response text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.feedback enable row level security;
grant select, insert, update on public.feedback to authenticated;
revoke delete on public.feedback from authenticated;

drop policy if exists feedback_read on public.feedback;
create policy feedback_read on public.feedback
for select to authenticated
using (user_id = auth.uid() or public.is_system_admin());

drop policy if exists feedback_create on public.feedback;
create policy feedback_create on public.feedback
for insert to authenticated
with check (user_id = auth.uid() and status = 'open');

drop policy if exists feedback_admin_update on public.feedback;
create policy feedback_admin_update on public.feedback
for update to authenticated
using (public.is_system_admin())
with check (public.is_system_admin());

create index if not exists feedback_status_created_idx
on public.feedback(status, created_at desc);
