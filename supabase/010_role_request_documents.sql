alter table public.role_requests
add column if not exists proof_paths text[] not null default '{}',
add column if not exists proof_names text[] not null default '{}';

update public.role_requests
set proof_paths = array[proof_path],
    proof_names = array['Supporting document']
where proof_path is not null
  and cardinality(proof_paths) = 0;

update storage.buckets
set public = false,
    file_size_limit = 5242880,
    allowed_mime_types = array[
      'image/jpeg',
      'image/png',
      'image/webp',
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    ]
where id = 'role-request-proofs';

drop policy if exists role_requests_insert on public.role_requests;
create policy role_requests_insert on public.role_requests
for insert to authenticated
with check (
  user_id = auth.uid()
  and requested_role::text in ('admin', 'hospital')
  and cardinality(proof_paths) between 1 and 5
  and cardinality(proof_names) = cardinality(proof_paths)
  and proof_path = proof_paths[1]
  and not exists (
    select 1
    from unnest(proof_paths) as document_path
    where document_path not like auth.uid()::text || '/%'
  )
  and exists (
    select 1 from public.profiles
    where id = auth.uid() and role::text = 'donor'
  )
);
