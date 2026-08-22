create or replace function public.verify_event_qr(
  p_event_id uuid,
  p_donor_id uuid
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
  select * into selected_event
  from public.donation_events
  where id = p_event_id and created_by = auth.uid();

  if not found then
    raise exception 'Only the event owner can scan attendance';
  end if;

  if selected_event.status = 'cancelled' or selected_event.starts_at > now() then
    raise exception 'Attendance scanning is available only after the event starts';
  end if;

  select * into selected_registration
  from public.event_registrations
  where event_id = p_event_id
    and donor_id = p_donor_id
    and status = 'registered'
  for update;

  if not found then
    raise exception 'Active donor registration not found';
  end if;

  if not exists (
    select 1 from public.profiles
    where id = p_donor_id
      and (next_eligible_date is null or next_eligible_date <= current_date)
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
    p_donor_id,
    current_date,
    'verified',
    auth.uid(),
    now(),
    p_event_id
  )
  returning id into new_donation_id;

  insert into public.reward_transactions (
    donor_id,
    points,
    transaction_type,
    donation_id
  )
  values (p_donor_id, 100, 'earned', new_donation_id);

  update public.profiles
  set next_eligible_date = current_date + 60,
      updated_at = now()
  where id = p_donor_id;

  update public.event_registrations
  set status = 'attended', attended_at = now()
  where id = selected_registration.id;

  return new_donation_id;
end;
$$;

revoke all on function public.verify_event_qr(uuid, uuid) from public;
grant execute on function public.verify_event_qr(uuid, uuid) to authenticated;
