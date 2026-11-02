-- Yapı (alt eser) yönlendirme hotspot'ları artık hem eski hem güncel fotoğrafta görünür.
-- Hotspot'un asıl konumu x_percent / y_percent (target_side tarafındaki fotoğraf).
-- Karşı fotoğraftaki konumu farklıysa aşağıdaki iki sütuna yaz (0-1 arası, sol üstten); boş bırakılırsa aynı koordinat kullanılır.
alter table public."Hotspots"
  add column if not exists alt_x_percent double precision,
  add column if not exists alt_y_percent double precision;

-- Örnek: id = 123 numaralı hotspot'un karşı fotoğraftaki yeri
-- update public."Hotspots" set alt_x_percent = 0.55, alt_y_percent = 0.40 where id = 123;
