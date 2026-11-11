-- Yeşil Camii (heritage_places id 10) hotspot'larının 3D model konumları.
-- Konumlar yüklenen yesil_camii_model_yeni.glb / _eski.glb geometrisinden hesaplandı (iki modelde yapı aynı koordinatlarda):
--   ön cephe z = -16, taç kapı z = -17.7'ye kadar çıkar; giriş holü kubbesi z ≈ -13.4 (tepe y 15.4);
--   büyük kubbe merkezi z ≈ -3.1, feneri y 28.6'ya kadar; kıble duvarı z = +16 (x ±7.15).
-- İç mekândaki öğeler dışarıdan görünen en yakın yüzeye konur. model_normal noktanın baktığı yön.
-- Supabase → SQL Editor'de çalıştır.
begin;

-- Taç Kapı: mukarnaslı kavsara (nişin önü)
update public."Hotspots" set model_pos = '0 7.9 -17.7', model_normal = '0 0 -1' where id = 25;

-- Taç Kapı Detay: celi sülüs kitabe paneli (kavsaranın üstü)
update public."Hotspots" set model_pos = '0 10.15 -17.74', model_normal = '0 0 -1' where id = 26;

-- Hünkar Mahfili: üst katta, giriş holünün üstünde → giriş kubbesinin tepesi
update public."Hotspots" set model_pos = '0 15.4 -13.4', model_normal = '0 1 0' where id = 28;

-- Minber ve Kitabeli Duvar: kıble duvarı, mihrabın sağı (kıbleye bakınca sağ = -x)
update public."Hotspots" set model_pos = '-2.5 6 16.05', model_normal = '0 0 1' where id = 30;

-- Fıskiyeli Orta Harim: havuzun tam üstündeki büyük kubbe feneri
update public."Hotspots" set model_pos = '0 28.6 -3.1', model_normal = '0 1 0' where id = 32;

commit;
