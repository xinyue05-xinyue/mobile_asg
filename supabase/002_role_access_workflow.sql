alter type public.user_role add value if not exists 'admin';
alter type public.user_role add value if not exists 'hospital';
alter type public.user_role add value if not exists 'system_admin';

create table if not exists public.role_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  requested_role public.user_role not null,
  organisation_name text not null,
  staff_position text not null,
  reason text,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  reviewed_by uuid references public.profiles(id),
  reviewed_at timestamptz,
  rejection_reason text,
  created_at timestamptz not null default now(),
  check (requested_role::text in ('admin', 'hospital'))
);

create unique index if not exists role_requests_one_pending_idx
on public.role_requests(user_id)
where status = 'pending';

create or replace function public.is_system_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role::text = 'system_admin'
  );
$$;

create or replace function public.is_hospital_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid()
      and role::text in ('admin', 'hospital', 'system_admin', 'hospital_admin')
  );
$$;

alter table public.role_requests enable row level security;
grant select, insert on public.role_requests to authenticated;

drop policy if exists role_requests_select on public.role_requests;
create policy role_requests_select on public.role_requests
for select to authenticated
using (user_id = auth.uid() or public.is_system_admin());

drop policy if exists role_requests_insert on public.role_requests;
create policy role_requests_insert on public.role_requests
for insert to authenticated
with check (
  user_id = auth.uid()
  and requested_role::text in ('admin', 'hospital')
  and exists (
    select 1 from public.profiles
    where id = auth.uid() and role::text = 'donor'
  )
);

create or replace function public.review_role_request(
  p_request_id uuid,
  p_approve boolean,
  p_review_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  pending_request public.role_requests%rowtype;
begin
  if not public.is_system_admin() then
    raise exception 'Only a system administrator can review applications';
  end if;

  select * into pending_request
  from public.role_requests
  where id = p_request_id and status = 'pending'
  for update;

  if not found then
    raise exception 'Pending application not found';
  end if;

  update public.role_requests
  set status = case when p_approve then 'approved' else 'rejected' end,
      reviewed_by = auth.uid(),
      reviewed_at = now(),
      rejection_reason = case when p_approve then null else p_review_reason end
  where id = p_request_id;

  if p_approve then
    update public.profiles
    set role = pending_request.requested_role,
        updated_at = now()
    where id = pending_request.user_id;
  end if;
end;
$$;

revoke all on function public.review_role_request(uuid, boolean, text) from public;
grant execute on function public.review_role_request(uuid, boolean, text)
to authenticated;

drop policy if exists centres_admin_all on public.donation_centres;
create policy centres_admin_all on public.donation_centres
for all to authenticated
using (
  exists (
    select 1 from public.profiles
    where id = auth.uid() and role::text in ('admin', 'system_admin')
  )
)
with check (
  exists (
    select 1 from public.profiles
    where id = auth.uid() and role::text in ('admin', 'system_admin')
  )
);

drop policy if exists events_admin_all on public.donation_events;
create policy events_admin_all on public.donation_events
for all to authenticated
using (
  exists (
    select 1 from public.profiles
    where id = auth.uid() and role::text in ('admin', 'system_admin')
  )
)
with check (
  exists (
    select 1 from public.profiles
    where id = auth.uid() and role::text in ('admin', 'system_admin')
  )
);

drop policy if exists requests_admin_all on public.emergency_requests;
drop policy if exists requests_hospital_all on public.emergency_requests;
create policy requests_hospital_all on public.emergency_requests
for all to authenticated
using (
  hospital_id = auth.uid()
  and exists (
    select 1 from public.profiles
    where id = auth.uid() and role::text in ('hospital', 'system_admin')
  )
)
with check (
  hospital_id = auth.uid()
  and exists (
    select 1 from public.profiles
    where id = auth.uid() and role::text in ('hospital', 'system_admin')
  )
);

drop policy if exists rewards_admin_all on public.reward_transactions;
create policy rewards_admin_all on public.reward_transactions
for all to authenticated
using (
  exists (
    select 1 from public.profiles
    where id = auth.uid() and role::text in ('admin', 'system_admin')
  )
)
with check (
  exists (
    select 1 from public.profiles
    where id = auth.uid() and role::text in ('admin', 'system_admin')
  )
);
