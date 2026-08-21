grant select, insert, update on public.emergency_requests to authenticated;

revoke delete on public.emergency_requests from authenticated;
