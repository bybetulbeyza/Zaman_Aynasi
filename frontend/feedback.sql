-- Uygulama içi geri bildirim formu. Uygulama yalnızca EKLEYEBİLİR; okuma/silme yok.
create table if not exists public.feedback_messages (
  id          bigint generated always as identity primary key,
  created_at  timestamptz not null default now(),
  category    text not null check (category in ('bug', 'idea', 'content', 'thanks')),
  message     text not null check (char_length(message) between 3 and 1000),
  contact     text check (char_length(contact) <= 120),   -- isteğe bağlı e-posta
  place_id    text check (char_length(place_id) <= 20),    -- eser sayfasından gönderildiyse
  device_id   text check (char_length(device_id) <= 40),
  lang        text check (lang in ('tr', 'en'))
);

alter table public.feedback_messages enable row level security;
drop policy if exists "feedback insert only" on public.feedback_messages;
create policy "feedback insert only" on public.feedback_messages
  for insert to anon, authenticated with check (true);

-- Sizin okumanız için (Table Editor / SQL Editor); API'de kapalı.
create or replace view public.feedback_inbox as
  select f.created_at, f.category, f.message, f.contact, p.name as eser, f.lang
  from public.feedback_messages f
  left join public.heritage_places p on p.id::text = f.place_id
  order by f.created_at desc;
revoke all on public.feedback_inbox from anon, authenticated;
