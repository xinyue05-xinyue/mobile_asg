alter table public.donations
add column if not exists emergency_request_id uuid
references public.emergency_requests(id);

create table if not exists public.emergency_responses (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null
    references public.emergency_requests(id) on delete cascade,
  donor_id uuid not null
    constraint emergency_responses_donor_id_fkey
    references public.profiles(id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'completed', 'cancelled')),
  created_at timestamptz not null default now(),
  completed_at timestamptz,
  unique (request_id, donor_id)
);

alter table public.emergency_responses enable row level security;
grant select, insert on public.emergency_responses to authenticated;
revoke update, delete on public.emergency_responses from authenticated;

drop policy if exists emergency_responses_select on public.emergency_responses;
create policy emergency_responses_select on public.emergency_responses
for select to authenticated
using (
  donor_id = auth.uid()
  or exists (
    select 1
    from public.emergency_requests request
    where request.id = request_id
      and request.hospital_id = auth.uid()
  )
  or public.is_system_admin()
);

drop policy if exists emergency_responses_insert on public.emergency_responses;
create policy emergency_responses_insert on public.emergency_responses
for insert to authenticated
with check (
  donor_id = auth.uid()
  and exists (
    select 1
    from public.emergency_requests request
    join public.profiles profile on profile.id = auth.uid()
    where request.id = request_id
      and request.status = 'active'
      and request.deadline > now()
      and request.blood_type = profile.blood_type
      and (
        profile.next_eligible_date is null
        or profile.next_eligible_date <= current_date
      )
  )
);

create or replace function public.cancel_emergency_response(
  p_response_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.emergency_responses
  set status = 'cancelled'
  where id = p_response_id
    and donor_id = auth.uid()
    and status = 'pending';

  if not found then
    raise exception 'Pending response not found';
  end if;
end;
$$;

create or replace function public.verify_emergency_donation(
  p_response_id uuid,
  p_next_eligible_date date
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  selected_response public.emergency_responses%rowtype;
  selected_request public.emergency_requests%rowtype;
  new_donation_id uuid;
begin
  select * into selected_response
  from public.emergency_responses
  where id = p_response_id and status = 'pending'
  for update;

  if not found then
    raise exception 'Pending response not found';
  end if;

  select * into selected_request
  from public.emergency_requests
  where id = selected_response.request_id
    and hospital_id = auth.uid();

  if not found then
    raise exception 'Only the owning hospital can verify this donation';
  end if;

  if not exists (
    select 1 from public.profiles
    where id = auth.uid() and role::text in ('hospital', 'system_admin')
  ) then
    raise exception 'Hospital access required';
  end if;

  if p_next_eligible_date <= current_date then
    raise exception 'Next eligible date must be in the future';
  end if;

  if not exists (
    select 1 from public.profiles
    where id = selected_response.donor_id
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
    emergency_request_id
  )
  values (
    selected_response.donor_id,
    current_date,
    'verified',
    auth.uid(),
    now(),
    selected_response.request_id
  )
  returning id into new_donation_id;

  insert into public.reward_transactions (
    donor_id,
    points,
    transaction_type,
    donation_id
  )
  values (
    selected_response.donor_id,
    100,
    'earned',
    new_donation_id
  );

  update public.profiles
  set next_eligible_date = p_next_eligible_date,
      updated_at = now()
  where id = selected_response.donor_id;

  update public.emergency_responses
  set status = 'completed', completed_at = now()
  where id = p_response_id;

  return new_donation_id;
end;
$$;

revoke all on function public.cancel_emergency_response(uuid) from public;
grant execute on function public.cancel_emergency_response(uuid)
to authenticated;

revoke all on function public.verify_emergency_donation(uuid, date) from public;
grant execute on function public.verify_emergency_donation(uuid, date)
to authenticated;

create index if not exists emergency_responses_request_idx
on public.emergency_responses(request_id, status);
