-- Anonim kullanım sayacı (jüri geri bildirimi için). Ad/e-posta/konum tutulmaz.
-- Supabase > SQL Editor'da çalıştırın.

create table if not exists public.analytics_events (
  id          bigint generated always as identity primary key,
  created_at  timestamptz not null default now(),
  event       text not null check (char_length(event) <= 40),
  place_id    text check (char_length(place_id) <= 20),
  device_id   text not null check (char_length(device_id) <= 40),  -- rastgele, cihaza özel
  session_id  text check (char_length(session_id) <= 40),
  lang        text check (lang in ('tr', 'en')),
  meta        jsonb
);

create index if not exists analytics_events_event_idx on public.analytics_events (event, created_at);
create index if not exists analytics_events_place_idx on public.analytics_events (place_id);

-- Uygulama (anon) yalnızca EKLEYEBİLİR; okuma/silme/güncelleme izni yoktur.
alter table public.analytics_events enable row level security;
drop policy if exists "analytics insert only" on public.analytics_events;
create policy "analytics insert only" on public.analytics_events
  for insert to anon, authenticated with check (true);

-- Rapor: envanter yayınlarına (cilt sitesi) uygulamadan tıklama — günlük, nereden (eser kartı / hakkında)
create or replace view public.analytics_inventory_clicks as
  select (created_at at time zone 'Europe/Istanbul')::date as gun,
         meta->>'from' as kaynak,
         count(*) as tiklama,
         count(distinct device_id) as farkli_cihaz
  from public.analytics_events where event = 'inventory_click'
  group by 1, 2 order by 1 desc, 3 desc;

-- Karşılaştırma için: uygulamayı açan farklı cihaz sayısı (tıklayan / açan = tıklama oranı)
create or replace view public.analytics_app_opens as
  select (created_at at time zone 'Europe/Istanbul')::date as gun,
         count(distinct device_id) as acan_cihaz
  from public.analytics_events where event = 'app_open'
  group by 1 order by 1 desc;

revoke all on public.analytics_inventory_clicks, public.analytics_app_opens
  from anon, authenticated;

-- (Önceki sürümü çalıştırdıysanız artık gereksiz görünümleri kaldırabilirsiniz:)
-- drop view if exists public.analytics_summary, public.analytics_top_places, public.analytics_daily_active;
