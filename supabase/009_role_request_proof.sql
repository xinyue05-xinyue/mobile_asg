alter table public.role_requests
add column if not exists proof_path text;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'role-request-proofs',
  'role-request-proofs',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = false,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists role_request_proofs_insert on storage.objects;
create policy role_request_proofs_insert on storage.objects
for insert to authenticated
with check (
  bucket_id = 'role-request-proofs'
  and (storage.foldername(name))[1] = auth.uid()::text
  and exists (
    select 1
    from public.profiles
    where id = auth.uid() and role::text = 'donor'
  )
);

drop policy if exists role_request_proofs_select on storage.objects;
create policy role_request_proofs_select on storage.objects
for select to authenticated
using (
  bucket_id = 'role-request-proofs'
  and (
    (storage.foldername(name))[1] = auth.uid()::text
    or public.is_system_admin()
  )
);

drop policy if exists role_request_proofs_delete on storage.objects;
create policy role_request_proofs_delete on storage.objects
for delete to authenticated
using (
  bucket_id = 'role-request-proofs'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists role_requests_insert on public.role_requests;
create policy role_requests_insert on public.role_requests
for insert to authenticated
with check (
  user_id = auth.uid()
  and requested_role::text in ('admin', 'hospital')
  and proof_path is not null
  and proof_path like auth.uid()::text || '/%'
  and exists (
    select 1 from public.profiles
    where id = auth.uid() and role::text = 'donor'
  )
);
