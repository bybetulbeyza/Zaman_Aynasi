-- Hesap özellikleri: hesabı silme + profil fotoğrafı deposu. Supabase > SQL Editor'da çalıştırın.

-- 1) Kullanıcı kendi hesabını silebilir. auth.users satırı silinince profiles ve user_progress
--    satırları da (on delete cascade) otomatik gider.
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;

-- 2) Profil fotoğrafları: herkese açık okunur, yalnızca kendi klasörüne yazılır (<kullanıcı id>/avatar.jpg)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 2097152, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = true,
      file_size_limit = 2097152,
      allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp'];

drop policy if exists "avatars: kendi klasorunu oku" on storage.objects;
create policy "avatars: kendi klasorunu oku" on storage.objects
  for select to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "avatars: kendi klasorune yaz" on storage.objects;
create policy "avatars: kendi klasorune yaz" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "avatars: kendi dosyasini guncelle" on storage.objects;
create policy "avatars: kendi dosyasini guncelle" on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "avatars: kendi dosyasini sil" on storage.objects;
create policy "avatars: kendi dosyasini sil" on storage.objects
  for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
