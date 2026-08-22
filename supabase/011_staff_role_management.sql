create or replace function public.demote_staff_to_donor(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target_role text;
begin
  if not public.is_system_admin() then
    raise exception 'Only a system administrator can manage staff roles';
  end if;

  if p_user_id = auth.uid() then
    raise exception 'You cannot remove your own system administrator access';
  end if;

  select role::text into target_role
  from public.profiles
  where id = p_user_id
  for update;

  if not found then
    raise exception 'Account not found';
  end if;

  if target_role not in ('admin', 'hospital', 'hospital_admin') then
    raise exception 'Only organisation admin or hospital access can be removed';
  end if;

  update public.profiles
  set role = 'donor', updated_at = now()
  where id = p_user_id;
end;
$$;

revoke all on function public.demote_staff_to_donor(uuid) from public;
grant execute on function public.demote_staff_to_donor(uuid) to authenticated;
