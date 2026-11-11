-- Ulu Camii (heritage_places id 9) hotspot'larının 3D model konumları.
-- Konumlar ulu_camii_model_yeni.glb / _eski.glb geometrisinden hesaplandı (iki modelde yapı aynı koordinatlarda):
--   giriş (taç kapı) kuzeyde z = -27.5, kıble duvarı z = +27.5, 20 kubbe 5x4 (merkezler x = 0, ±13.6, ±27.2; z = ±6.9, ±20.6),
--   tepesi açık "göz"lü kubbe x = 0, z = -6.9 (şadırvanın üstü), minareler ön köşelerde x = ±30, z ≈ -31.
-- İç mekândaki öğeler dışarıdan görünen en yakın yüzeye konur (Koza Han'daki gibi). model_normal noktanın baktığı yön.
-- Supabase → SQL Editor'de çalıştır.
begin;

-- İç Şadırvan: tam üstündeki açık kubbe gözünün kenarı
update public."Hotspots" set model_pos = '0 21.1 -6.9', model_normal = '0 1 0' where id = 19;

-- Kündekari Minberi: mihrabın sağında (kıbleye bakınca sağ = batı = -x), kıble duvarı
update public."Hotspots" set model_pos = '-5.5 7 27.6', model_normal = '0 0 1' where id = 20;

-- Müezzin Mahfili: şadırvanın batısındaki kubbe üstü (YAKLAŞIK; uygulamada kontrol et)
update public."Hotspots" set model_pos = '-13.6 20.9 -6.9', model_normal = '0 1 0' where id = 21;

-- Kuşbakışı Minareler: batı minaresinin şerefesi (ön yüz)
update public."Hotspots" set model_pos = '-30 29 -34.4', model_normal = '0 0 -1' where id = 22;

-- Sürgündeki Paşanın Mihrabı: kıble duvarının ortası
update public."Hotspots" set model_pos = '0 9 27.6', model_normal = '0 0 1' where id = 23;

-- İç Taraftan Kubbeler ve Hat Yazıları: ön sıradaki bir kubbenin girişe bakan yamacı
update public."Hotspots" set model_pos = '13.6 19.8 -24.6', model_normal = '0 0.88 -0.47' where id = 24;

commit;
