revoke update on public.profiles from authenticated;

grant update (
  full_name,
  blood_type,
  phone,
  date_of_birth,
  notifications_enabled
)
on public.profiles to authenticated;
