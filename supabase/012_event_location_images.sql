alter table public.donation_events
add column if not exists latitude double precision,
add column if not exists longitude double precision,
add column if not exists image_path text;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'event-images',
  'event-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists event_images_staff_insert on storage.objects;
create policy event_images_staff_insert on storage.objects
for insert to authenticated
with check (
  bucket_id = 'event-images'
  and (storage.foldername(name))[1] = auth.uid()::text
  and exists (
    select 1 from public.profiles
    where id = auth.uid() and role::text in ('admin', 'system_admin')
  )
);

drop policy if exists event_images_owner_update on storage.objects;
create policy event_images_owner_update on storage.objects
for update to authenticated
using (
  bucket_id = 'event-images'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'event-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists event_images_owner_delete on storage.objects;
create policy event_images_owner_delete on storage.objects
for delete to authenticated
using (
  bucket_id = 'event-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);
