-- Yeşil İmareti (heritage_places id 22) kapsamdan çıkarıldı: eser ve ona bağlı her şey silinir.
-- Silinenler:
--   * user_progress: kullanıcıların kazandığı İmaret mührü ve tamamladığı İmaret görevleri
--   * place_activities: eserin keşif görevleri (place_id = 22)
--   * Hotspots: İmaret'e ait hotspot'lar (place_id = 22; eski #80-82 dahil) ve
--     Yeşil Külliye sayfasındaki "Yeşil İmareti" yönlendirme hotspot'u (id 62)
--   * heritage_places: eserin kendisi (id 22)
-- analytics_events / feedback kayıtlarına dokunulmaz (geçmiş istatistik; place_id metin olarak kalır).
-- Geri alınamaz. Supabase → SQL Editor'de çalıştır.
begin;

-- Kullanıcıların İmaret mührü ve İmaret görevleri (giriş yapanların bulut yedeği); görevler silinmeden önce.
delete from public.user_progress where kind = 'stamp' and ref_id = 22;
delete from public.user_progress
where kind = 'activity'
  and ref_id in (select id from public.place_activities where place_id::text = '22');

delete from public.place_activities where place_id::text = '22';

delete from public."Hotspots"
where place_id::text = '22'
   or target_place_id::text = '22'
   or id in (80, 81, 82)
   or (id = 62 and title = 'Yeşil İmareti');

delete from public.heritage_places where id = 22;

commit;
