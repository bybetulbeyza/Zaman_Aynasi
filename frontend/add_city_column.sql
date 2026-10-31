-- Eserlerin şehri. Yeni şehir eklerken bu kolonu doldurmanız yeterli: pasaport, şehir çipleri ve
-- sayaçlar uygulamada otomatik o şehre göre gruplanır.
alter table public.heritage_places add column if not exists city text default 'Bursa';
update public.heritage_places set city = 'Bursa' where city is null;
