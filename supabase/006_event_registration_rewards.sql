alter table public.donations
add column if not exists event_id uuid
references public.donation_events(id);

create table if not exists public.event_registrations (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.donation_events(id) on delete cascade,
  donor_id uuid not null
    constraint event_registrations_donor_id_fkey
    references public.profiles(id) on delete cascade,
  status text not null default 'registered'
    check (status in ('registered', 'attended', 'cancelled')),
  registered_at timestamptz not null default now(),
  attended_at timestamptz,
  unique (event_id, donor_id)
);

alter table public.event_registrations enable row level security;
grant select, insert on public.event_registrations to authenticated;
revoke update, delete on public.event_registrations from authenticated;

drop policy if exists event_registrations_select on public.event_registrations;
create policy event_registrations_select on public.event_registrations
for select to authenticated
using (
  donor_id = auth.uid()
  or exists (
    select 1 from public.donation_events event
    where event.id = event_id and event.created_by = auth.uid()
  )
  or public.is_system_admin()
);

drop policy if exists event_registrations_insert on public.event_registrations;
create policy event_registrations_insert on public.event_registrations
for insert to authenticated
with check (
  donor_id = auth.uid()
  and exists (
    select 1 from public.donation_events event
    where event.id = event_id
      and event.status = 'upcoming'
      and event.starts_at > now()
  )
);

create or replace function public.cancel_event_registration(
  p_registration_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.event_registrations
  set status = 'cancelled'
  where id = p_registration_id
    and donor_id = auth.uid()
    and status = 'registered';

  if not found then
    raise exception 'Active registration not found';
  end if;
end;
$$;

create or replace function public.verify_event_donation(
  p_registration_id uuid,
  p_next_eligible_date date
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  selected_registration public.event_registrations%rowtype;
  selected_event public.donation_events%rowtype;
  new_donation_id uuid;
begin
  select * into selected_registration
  from public.event_registrations
  where id = p_registration_id and status = 'registered'
  for update;

  if not found then
    raise exception 'Active registration not found';
  end if;

  select * into selected_event
  from public.donation_events
  where id = selected_registration.event_id
    and created_by = auth.uid();

  if not found then
    raise exception 'Only the event owner can verify attendance';
  end if;

  if not exists (
    select 1 from public.profiles
    where id = auth.uid() and role::text in ('admin', 'system_admin')
  ) then
    raise exception 'Admin access required';
  end if;

  if p_next_eligible_date <= current_date then
    raise exception 'Next eligible date must be in the future';
  end if;

  if selected_event.status = 'cancelled' or selected_event.starts_at > now() then
    raise exception 'The event is not available for attendance verification';
  end if;

  if not exists (
    select 1 from public.profiles
    where id = selected_registration.donor_id
      and (
        next_eligible_date is null
        or next_eligible_date <= current_date
      )
  ) then
    raise exception 'Donor is not currently eligible';
  end if;

  insert into public.donations (
    donor_id,
    donation_date,
    verification_status,
    verified_by,
    verified_at,
    event_id
  )
  values (
    selected_registration.donor_id,
    current_date,
    'verified',
    auth.uid(),
    now(),
    selected_registration.event_id
  )
  returning id into new_donation_id;

  insert into public.reward_transactions (
    donor_id,
    points,
    transaction_type,
    donation_id
  )
  values (
    selected_registration.donor_id,
    100,
    'earned',
    new_donation_id
  );

  update public.profiles
  set next_eligible_date = p_next_eligible_date,
      updated_at = now()
  where id = selected_registration.donor_id;

  update public.event_registrations
  set status = 'attended', attended_at = now()
  where id = p_registration_id;

  return new_donation_id;
end;
$$;

revoke all on function public.cancel_event_registration(uuid) from public;
grant execute on function public.cancel_event_registration(uuid)
to authenticated;

revoke all on function public.verify_event_donation(uuid, date) from public;
grant execute on function public.verify_event_donation(uuid, date)
to authenticated;

create index if not exists event_registrations_event_idx
on public.event_registrations(event_id, status);
