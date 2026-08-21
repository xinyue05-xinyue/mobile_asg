create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  message text not null,
  type text not null check (type in ('emergency', 'event', 'role', 'reward', 'general')),
  reference_type text,
  reference_id uuid,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.notifications enable row level security;
grant select on public.notifications to authenticated;
revoke insert, update, delete on public.notifications from authenticated;
grant update (is_read) on public.notifications to authenticated;

drop policy if exists notifications_select_own on public.notifications;
create policy notifications_select_own on public.notifications
for select to authenticated
using (user_id = auth.uid());

drop policy if exists notifications_update_own on public.notifications;
create policy notifications_update_own on public.notifications
for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create index if not exists notifications_user_created_idx
on public.notifications(user_id, created_at desc);

create index if not exists notifications_user_unread_idx
on public.notifications(user_id, is_read)
where is_read = false;

create or replace function public.notify_emergency_request()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notifications (
    user_id, title, message, type, reference_type, reference_id
  )
  select
    profile.id,
    'Emergency blood request',
    new.blood_type || ' blood is needed before ' ||
      to_char(new.deadline at time zone 'Asia/Kuala_Lumpur', 'DD/MM/YYYY HH24:MI') || '.',
    'emergency',
    'emergency_request',
    new.id
  from public.profiles profile
  where profile.role::text = 'donor'
    and profile.blood_type = new.blood_type
    and profile.notifications_enabled
    and (
      profile.next_eligible_date is null
      or profile.next_eligible_date <= current_date
    );
  return new;
end;
$$;

drop trigger if exists notify_emergency_request_trigger
on public.emergency_requests;
create trigger notify_emergency_request_trigger
after insert on public.emergency_requests
for each row execute function public.notify_emergency_request();

create or replace function public.notify_event_registration()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  selected_event public.donation_events%rowtype;
begin
  select * into selected_event
  from public.donation_events
  where id = new.event_id;

  insert into public.notifications (
    user_id, title, message, type, reference_type, reference_id
  ) values (
    new.donor_id,
    'Event registration confirmed',
    'You registered for ' || selected_event.title || ' on ' ||
      to_char(selected_event.starts_at at time zone 'Asia/Kuala_Lumpur', 'DD/MM/YYYY HH24:MI') || '.',
    'event',
    'donation_event',
    new.event_id
  );
  return new;
end;
$$;

drop trigger if exists notify_event_registration_trigger
on public.event_registrations;
create trigger notify_event_registration_trigger
after insert on public.event_registrations
for each row execute function public.notify_event_registration();

create or replace function public.notify_role_request_result()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.status = 'pending' and new.status in ('approved', 'rejected') then
    insert into public.notifications (
      user_id, title, message, type, reference_type, reference_id
    ) values (
      new.user_id,
      case when new.status = 'approved'
        then 'Access application approved'
        else 'Access application update'
      end,
      case when new.status = 'approved'
        then 'Your ' || new.requested_role::text || ' access has been approved. Log in again to open your new portal.'
        else 'Your ' || new.requested_role::text || ' access application was not approved.'
      end,
      'role',
      'role_request',
      new.id
    );
  end if;
  return new;
end;
$$;

drop trigger if exists notify_role_request_result_trigger
on public.role_requests;
create trigger notify_role_request_result_trigger
after update of status on public.role_requests
for each row execute function public.notify_role_request_result();

create or replace function public.notify_reward_earned()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.points > 0 then
    insert into public.notifications (
      user_id, title, message, type, reference_type, reference_id
    ) values (
      new.donor_id,
      'Reward points earned',
      'Your donation was verified and ' || new.points || ' points were added to your account.',
      'reward',
      'reward_transaction',
      new.id
    );
  end if;
  return new;
end;
$$;

drop trigger if exists notify_reward_earned_trigger
on public.reward_transactions;
create trigger notify_reward_earned_trigger
after insert on public.reward_transactions
for each row execute function public.notify_reward_earned();
