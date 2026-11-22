create or replace function private.storage_uuid_or_null(p_value text)
returns uuid
language plpgsql
immutable
security definer
set search_path = pg_temp
as $$
begin
  return nullif(btrim(p_value), '')::uuid;
exception when invalid_text_representation then
  return null;
end;
$$;

create or replace function private.storage_path_hotel_id(p_name text)
returns uuid
language sql
immutable
security definer
set search_path = private, pg_temp
as $$
  select private.storage_uuid_or_null(split_part(p_name, '/', 1));
$$;

create or replace function private.storage_path_entity_type(p_name text)
returns text
language sql
immutable
security definer
set search_path = pg_temp
as $$
  select lower(split_part(p_name, '/', 2));
$$;

create or replace function private.storage_path_entity_id(p_name text)
returns uuid
language sql
immutable
security definer
set search_path = private, pg_temp
as $$
  select private.storage_uuid_or_null(split_part(p_name, '/', 3));
$$;

create or replace function private.storage_path_is_valid(p_name text)
returns boolean
language sql
immutable
security definer
set search_path = private, pg_temp
as $$
  select coalesce(array_length(string_to_array(p_name, '/'), 1), 0) = 4
     and p_name not like '%//%'
     and p_name not like '%/./%'
     and p_name not like '%/../%'
     and p_name not like './%'
     and p_name not like '../%'
     and split_part(p_name, '/', 4) not like '%/%'
     and private.storage_uuid_or_null(split_part(p_name, '/', 1)) is not null
     and private.storage_uuid_or_null(split_part(p_name, '/', 3)) is not null
     and split_part(p_name, '/', 2) <> '';
$$;

create or replace function private.storage_guest_owns_entity(p_entity_type text, p_entity_id uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = public, private, pg_temp
as $$
begin
  if p_entity_type = 'guest' then
    return exists (
      select 1 from public.guests
      where id = p_entity_id and auth_user_id = auth.uid()
    );
  elsif p_entity_type = 'reservation' then
    return private.guest_owns_reservation(p_entity_id);
  elsif p_entity_type = 'folio' then
    return private.guest_owns_folio(p_entity_id);
  elsif p_entity_type = 'payment' then
    return private.guest_owns_payment(p_entity_id);
  elsif p_entity_type = 'receipt' then
    return private.guest_owns_receipt(p_entity_id);
  end if;
  return false;
end;
$$;

create or replace function private.storage_has_finance_read()
returns boolean
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select private.has_permission('receipt.read')
      or private.has_permission('ledger.read')
      or private.has_permission('folio.read')
      or private.has_role('accountant')
      or private.has_role('manager')
      or private.has_role('owner');
$$;

create or replace function private.storage_has_hr_read()
returns boolean
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select private.has_permission('staff.read_hr')
      or private.has_role('owner')
      or private.has_role('manager');
$$;

create or replace function private.storage_room_is_public(p_room_id uuid, p_hotel_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select exists (
    select 1 from public.rooms
    where id = p_room_id
      and hotel_id = p_hotel_id
      and is_active
      and operational_status = 'available'
  );
$$;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('public-media', 'public-media', true, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('room-images', 'room-images', false, 10485760, array['image/jpeg', 'image/png', 'image/webp']),
  ('guest-evidence', 'guest-evidence', false, 10485760, array['image/jpeg', 'image/png', 'application/pdf']),
  ('receipts', 'receipts', false, 10485760, array['application/pdf', 'image/jpeg', 'image/png']),
  ('report-exports', 'report-exports', false, 20971520, array['application/pdf', 'text/csv', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet']),
  ('staff-documents', 'staff-documents', false, 10485760, array['image/jpeg', 'image/png', 'application/pdf'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists public_media_read on storage.objects;
create policy public_media_read on storage.objects for select to anon, authenticated
using (bucket_id = 'public-media');

drop policy if exists public_media_write on storage.objects;
create policy public_media_write on storage.objects for insert to authenticated
with check (
  bucket_id = 'public-media'
  and private.storage_path_is_valid(name)
  and private.has_permission('content.manage')
  and exists (select 1 from public.hotels where id = private.storage_path_hotel_id(name))
);

drop policy if exists public_media_update on storage.objects;
create policy public_media_update on storage.objects for update to authenticated
using (
  bucket_id = 'public-media'
  and private.has_permission('content.manage')
)
with check (
  bucket_id = 'public-media'
  and private.storage_path_is_valid(name)
  and private.has_permission('content.manage')
);

drop policy if exists public_media_delete on storage.objects;
create policy public_media_delete on storage.objects for delete to authenticated
using (bucket_id = 'public-media' and private.has_permission('content.manage'));

drop policy if exists room_images_read on storage.objects;
create policy room_images_read on storage.objects for select to anon, authenticated
using (
  bucket_id = 'room-images'
  and private.storage_path_is_valid(name)
  and private.storage_path_entity_type(name) = 'room'
  and private.storage_room_is_public(private.storage_path_entity_id(name), private.storage_path_hotel_id(name))
);

drop policy if exists room_images_write on storage.objects;
create policy room_images_write on storage.objects for insert to authenticated
with check (
  bucket_id = 'room-images'
  and private.storage_path_is_valid(name)
  and private.storage_path_entity_type(name) = 'room'
  and private.has_permission('rooms.manage')
);

drop policy if exists room_images_update on storage.objects;
create policy room_images_update on storage.objects for update to authenticated
using (bucket_id = 'room-images' and private.has_permission('rooms.manage'))
with check (
  bucket_id = 'room-images'
  and private.storage_path_is_valid(name)
  and private.storage_path_entity_type(name) = 'room'
  and private.has_permission('rooms.manage')
);

drop policy if exists room_images_delete on storage.objects;
create policy room_images_delete on storage.objects for delete to authenticated
using (bucket_id = 'room-images' and private.has_permission('rooms.manage'));

drop policy if exists guest_evidence_read on storage.objects;
create policy guest_evidence_read on storage.objects for select to authenticated
using (
  bucket_id = 'guest-evidence'
  and private.storage_path_is_valid(name)
  and (
    private.has_permission('payment.transfer.verify')
    or private.storage_has_hr_read()
    or private.storage_guest_owns_entity(private.storage_path_entity_type(name), private.storage_path_entity_id(name))
  )
);

drop policy if exists guest_evidence_update on storage.objects;
create policy guest_evidence_update on storage.objects for update to authenticated
using (
  bucket_id = 'guest-evidence'
  and (
    private.has_permission('payment.transfer.verify')
    or private.storage_has_hr_read()
  )
)
with check (
  bucket_id = 'guest-evidence'
  and private.storage_path_is_valid(name)
  and (
    private.has_permission('payment.transfer.verify')
    or private.storage_has_hr_read()
  )
);

drop policy if exists guest_evidence_delete on storage.objects;
create policy guest_evidence_delete on storage.objects for delete to authenticated
using (
  bucket_id = 'guest-evidence'
  and (
    private.has_permission('payment.transfer.verify')
    or private.storage_has_hr_read()
  )
);

drop policy if exists receipts_read on storage.objects;
create policy receipts_read on storage.objects for select to authenticated
using (
  bucket_id = 'receipts'
  and private.storage_path_is_valid(name)
  and (
    private.storage_has_finance_read()
    or private.storage_guest_owns_entity(private.storage_path_entity_type(name), private.storage_path_entity_id(name))
  )
);

drop policy if exists report_exports_read on storage.objects;
create policy report_exports_read on storage.objects for select to authenticated
using (
  bucket_id = 'report-exports'
  and private.storage_path_is_valid(name)
  and (
    storage.objects.owner = auth.uid()
    or private.has_permission('reports.operational')
    or private.has_permission('reports.financial')
    or private.has_permission('reports.inventory')
    or private.has_permission('reports.staff')
    or private.has_role('accountant')
    or private.has_role('manager')
    or private.has_role('owner')
  )
);

drop policy if exists staff_documents_read on storage.objects;
create policy staff_documents_read on storage.objects for select to authenticated
using (
  bucket_id = 'staff-documents'
  and private.storage_path_is_valid(name)
  and (
    private.storage_has_hr_read()
    or (
      private.storage_path_entity_type(name) = 'profile'
      and private.storage_path_entity_id(name) = auth.uid()
    )
  )
);

drop policy if exists staff_documents_write on storage.objects;
create policy staff_documents_write on storage.objects for insert to authenticated
with check (
  bucket_id = 'staff-documents'
  and private.storage_path_is_valid(name)
  and (
    private.has_permission('staff.manage')
    or (
      private.storage_path_entity_type(name) = 'profile'
      and private.storage_path_entity_id(name) = auth.uid()
    )
  )
);

drop policy if exists staff_documents_update on storage.objects;
create policy staff_documents_update on storage.objects for update to authenticated
using (
  bucket_id = 'staff-documents'
  and (
    private.has_permission('staff.manage')
    or (
      private.storage_path_entity_type(name) = 'profile'
      and private.storage_path_entity_id(name) = auth.uid()
    )
  )
)
with check (
  bucket_id = 'staff-documents'
  and private.storage_path_is_valid(name)
  and (
    private.has_permission('staff.manage')
    or (
      private.storage_path_entity_type(name) = 'profile'
      and private.storage_path_entity_id(name) = auth.uid()
    )
  )
);

drop policy if exists staff_documents_delete on storage.objects;
create policy staff_documents_delete on storage.objects for delete to authenticated
using (
  bucket_id = 'staff-documents'
  and private.has_permission('staff.manage')
);
