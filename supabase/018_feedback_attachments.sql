alter table public.feedback
add column if not exists attachment_paths text[] not null default '{}',
add column if not exists attachment_names text[] not null default '{}';

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'feedback-attachments',
  'feedback-attachments',
  false,
  5242880,
  array[
    'image/jpeg',
    'image/png',
    'image/webp',
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  ]
)
on conflict (id) do update
set public = false,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists feedback_attachments_insert on storage.objects;
create policy feedback_attachments_insert on storage.objects
for insert to authenticated
with check (
  bucket_id = 'feedback-attachments'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists feedback_attachments_select on storage.objects;
create policy feedback_attachments_select on storage.objects
for select to authenticated
using (
  bucket_id = 'feedback-attachments'
  and (
    (storage.foldername(name))[1] = auth.uid()::text
    or public.is_system_admin()
  )
);

drop policy if exists feedback_attachments_delete on storage.objects;
create policy feedback_attachments_delete on storage.objects
for delete to authenticated
using (
  bucket_id = 'feedback-attachments'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists feedback_create on public.feedback;
create policy feedback_create on public.feedback
for insert to authenticated
with check (
  user_id = auth.uid()
  and status = 'open'
  and cardinality(attachment_paths) <= 5
  and cardinality(attachment_names) = cardinality(attachment_paths)
  and not exists (
    select 1
    from unnest(attachment_paths) as attachment_path
    where attachment_path not like auth.uid()::text || '/%'
  )
);
