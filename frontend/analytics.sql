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

-- TEK rapor görünümü: gün gün uygulama açılışı ve envanter yayınlarına tıklama.
-- Supabase > Table Editor > analytics_gunluk (ya da SQL Editor: select * from analytics_gunluk;)
create or replace view public.analytics_gunluk as
  select (created_at at time zone 'Europe/Istanbul')::date as gun,
         count(distinct device_id) filter (where event = 'app_open')                          as acan_cihaz,
         count(*)                  filter (where event = 'inventory_click')                    as tiklama,
         count(distinct device_id) filter (where event = 'inventory_click')                    as tiklayan_cihaz,
         round(100.0 * count(distinct device_id) filter (where event = 'inventory_click')
               / nullif(count(distinct device_id) filter (where event = 'app_open'), 0), 1)   as tiklama_orani_yuzde,
         count(*) filter (where event = 'inventory_click' and meta->>'from' = 'place_card')    as eser_kartindan,
         count(*) filter (where event = 'inventory_click' and meta->>'from' = 'about')         as hakkindan
  from public.analytics_events
  group by 1
  order by 1 desc;

revoke all on public.analytics_gunluk from anon, authenticated;

-- Önceki sürümleri çalıştırdıysanız eski görünümleri kaldırın (tablo ve veri kalır):
drop view if exists public.analytics_inventory_clicks, public.analytics_app_opens,
                    public.analytics_summary, public.analytics_top_places, public.analytics_daily_active;
