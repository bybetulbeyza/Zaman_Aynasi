-- Yeşil Külliye (16), Yeşil Medrese (23) ve Yeşil Türbe (11) hotspot'larının 3D model konumları.
-- Konumlar yüklenen .glb dosyalarının geometrisinden hesaplandı; her eserde eski ve yeni model aynı
-- koordinatlarda (Y yukarı). model_normal noktanın baktığı yön. Supabase → SQL Editor'de çalıştır.
begin;

-- ---------------------------------------------------------------------------
-- Yeşil Külliye (yesil_kulliye_gunumuz.glb / yesil_kulliye_model_eski-3.glb)
-- Kök ötelemesi (-7.175, 0, 40.5) dahil dünya koordinatları. Noktalar her yapının çatısında;
-- dokununca "Yapıya git" ile o yapının sayfası açılır.
-- ---------------------------------------------------------------------------
-- Yeşil Camii: ana kubbenin tepesi (minareler ön cephede z ≈ 27.9, kubbe z ≈ 44.8)
update public."Hotspots" set model_pos = '-7.3 21.1 44.8', model_normal = '0 1 0' where id = 59;
-- Yeşil Türbe: kubbe ve alem tepesi
update public."Hotspots" set model_pos = '26.8 25.8 18.5', model_normal = '0 1 0' where id = 60;
-- Yeşil (Sultaniye) Medresesi: yapının en yüksek noktası (dershane kubbesi, batı kanadı)
update public."Hotspots" set model_pos = '-29.7 13.3 -37.5', model_normal = '0 1 0' where id = 61;

-- ---------------------------------------------------------------------------
-- Yeşil Medrese (yesil_medresesi-4.glb / yesil_medresesi_model_eski.glb)
-- Giriş güneyde (z ≈ -18.5), dershane kuzeyde (kubbe z 10.4…19.2), avlu ortada.
-- ---------------------------------------------------------------------------
-- Çini Kaplı Tavan: çinili giriş tonozunun ağzı (tonoz y 2.6…4.9, z -18.2…-12.7)
update public."Hotspots" set model_pos = '0 4.2 -18.55', model_normal = '0 0 -1' where id = 83;
-- Mezar Taşlı Bahçe ve Cephe: avludaki sarıklı mezar taşı sergisi
update public."Hotspots" set model_pos = '-6 1.95 -0.15', model_normal = '0 1 0' where id = 86;
-- Sanduka Tipi Mezar: avludaki sandukanın kapağı
update public."Hotspots" set model_pos = '-3.8 1 4.05', model_normal = '0 1 0' where id = 88;
-- Kabartma Kitabe Levhası: dershane cephesindeki mermer kitabe paneli (avluya bakar)
update public."Hotspots" set model_pos = '0 7.15 8.94', model_normal = '0 0 -1' where id = 90;

-- ---------------------------------------------------------------------------
-- Yeşil Türbe (yesil_turbe_model_yeni.glb / _eski.glb)
-- İç mekân modellenmemiş: iç mekân noktası giriş kapısına konur.
-- "Devlet Hatun Türbesi" (id 42) modelde yok; 3D'de gösterilmez, yalnızca fotoğrafta kalır.
-- ---------------------------------------------------------------------------
-- İç Mekan ve Sandukalar: türbenin kapısı (kapı yüzeyi z = -9.6)
update public."Hotspots" set model_pos = '0 2.8 -9.75', model_normal = '0 0 -1' where id = 39;

commit;
