-- Koza Han (place_id = 5) hotspot'larının 3B model konumları. Mevcut satırlara konum eklenir,
-- yeni satır açılmaz; fotoğraf konumları (x_percent/y_percent) olduğu gibi kalır.
-- Model metre cinsinden, orijin zemin ortası, ana cephe (taç kapı) -Z yönünde.
-- İki sürümde (Günümüz/Tarihî) bu üç bölge birebir aynı geometride olduğu için konumlar ortak.
update public."Hotspots" set model_pos = '0 7 -4.6',      model_normal = '0 0 -1'
  where place_id = 5 and id = 10;  -- Sekizgen Köşk Mescit (avlu ortası, üst gövde)
update public."Hotspots" set model_pos = '0 11.2 -32.7',  model_normal = '0 0 -1'
  where place_id = 5 and id = 11;  -- Taç Kapı Taş Oymacılığı (ana cephe, kemer üstü)
update public."Hotspots" set model_pos = '12 3.4 17.9',   model_normal = '0 0 -1'
  where place_id = 5 and id = 12;  -- Tarihi İpek Loncası Revakları (avlunun kuzey revakı)
