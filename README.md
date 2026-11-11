<div align="center">

# 🏛️ Zaman Aynası

### Geçmişi gör, hikâyeyi keşfet, mirası sahiplen.

**Kök&Kod Hackathon 2026 · Vakıf Eserleri · Bursa**

*Önünden geçmek yerine, bilerek bakmak.*

</div>

## 📖 Proje Hakkında

**Zaman Aynası**, Bursa'nın vakıf eserlerini daha erişilebilir ve etkileşimli biçimde keşfetmeyi amaçlayan bir dijital açık hava müzesidir. Tarihî envanterdeki bilgileri; geçmiş-bugün karşılaştırmaları, etkileşimli noktalar, kısa hikâye videoları, sesli anlatımlar ve tematik gezi rotalarıyla buluşturur.

Projemiz, **Kök&Kod Hackathon** kapsamında geliştirilmiştir. Çıkış noktamız, Vakıf Katılım'ın *Vakıf Eserleri Envanteri* çalışmasında Bursa için yer alan **385 vakıf eseri**, **34.952 fotoğraf** ve **3 ciltlik** kapsamlı tarihî bilgiyi daha geniş bir kitleyle buluşturmaktır.

> **Amacımız:** Envanteri yalnızca okutmak değil; kültürel mirası göstermek, dinletmek ve yerinde keşfettirmek.

## ✨ Temel Özellikler

| Özellik | Açıklama |
| --- | --- |
| 🕰️ **Geçmiş & Bugün** | Split-slider ile tarihî ve güncel fotoğrafları karşılaştırma; seçili eserlerde geçmiş ve günümüzü temsil eden 3D modeller. |
| 📍 **Etkileşimli Hotspotlar** | Eser fotoğraflarındaki özel noktalardan mimari ve tarihî ayrıntılara erişim; adım adım eser turu. |
| 🎬 **Kısa Hikâye Videoları** | Eser ve hotspot hikâyelerini altyazılı, dikey mikro-sinematiklerle keşfetme. |
| 🎧 **Sesli Rehber** | Sesli anlatım, yazılı içerik ve altyazı ile farklı ihtiyaçlara uygun erişim. |
| 🗺️ **Tematik & Kişisel Rotalar** | Hazır rotalar veya başlangıç noktası, süre ve ilgi alanına göre kişiselleştirilmiş yürüyüş rotaları. |
| 🏅 **Görevler & Mühür Pasaportu** | Yerinde tamamlanan görevlerle dijital mühür toplama, unvan kazanma ve paylaşılabilir kartlar. |
| 🏛️ **Külliye Yapısı** | Yeşil Külliye gibi büyük alanları cami, türbe ve medrese gibi ayrı keşif sayfalarına ayırma. |
| 🌐 **Erişilebilirlik** | Türkçe/İngilizce dil desteği, üç yazı boyutu, yüksek kontrast, koyu mod ve ekran okuyucu etiketleri. |

## 🧒 Yadigâr: Hikâyelerin Rehberi

**Yadigâr**, hikâye videolarında kullanıcılara eşlik eden, tutarlı bir görsel kimliğe sahip küçük bir karakterdir. Konuşarak hikâyenin önüne geçmek yerine izleyiciyi eserin ayrıntılarına yönlendirir.

Video üretim akışımız:

**Envanter bilgisi → Kısa senaryo → Karakter kareleri → AI destekli hareket → Seslendirme ve altyazı**

Yapay zekâ ile üretilen tarihî sahneler **“Tarihî canlandırma / AI üretimi”** olarak etiketlenir; gerçek arşiv görüntüleriyle karıştırılmaması hedeflenir.

## 🔎 Kaynak Güvenilirliği

- Tarihî bilgilerin kaynağı olarak *Vakıf Eserleri Envanteri* cilt ve sayfa referansları kullanılır.
- Yapay zekâ ile oluşturulan tarihî canlandırmalar açıkça etiketlenir.
- Kullanıcılar eserlere ilişkin hata veya yanlış bilgi bildirimi gönderebilir.
- İçerikler birden fazla dilde sunulacak şekilde tasarlanmıştır.

## 🚀 Gelecek Planları

Vakıf eserlerinin yanında kullanılabilecek **dijital bilgilendirme ekranları** ile geçmiş-bugün karşılaştırmalarının ve kısa tarihî hikâyelerin, uygulama açılmadan da ziyaretçilere sunulması hedeflenmektedir. İçerik mimarisi, yeni şehir ve eserlerle genişletilebilecek biçimde kurgulanmıştır.

## 🛠️ Uygulamayı Çalıştırma

Gereksinimler: [Flutter](https://docs.flutter.dev/get-started/install) (stable) ve bir [Mapbox](https://account.mapbox.com/) public token (`pk.…`).

```bash
git clone https://github.com/bybetulbeyza/Zaman_Aynasi.git
cd Zaman_Aynasi
flutter pub get
```

Proje kökünde `env.json` dosyası oluştur (git'e eklenmez):

```json
{
  "MAPBOX_TOKEN": "pk.SENIN_MAPBOX_TOKENIN"
}
```

Çalıştır veya APK al:

```bash
flutter run --dart-define-from-file=env.json
flutter build apk --release --dart-define-from-file=env.json
```

> `env.json` olmadan uygulama açılır ama harita ve yürüyüş bilgileri görünmez. Supabase bağlantısı kod içinde hazırdır, ayrıca ayar gerekmez.

## 👥 Ekip

| İsim | Sorumluluk |
| --- | --- |
| **Betül Beyza Demirel** | Takım Kaptanı · Veri Toplama ve İçerik |
| **Mehmethan Ural** | Backend · Veri Katmanı |
| **Mehtap Aslan** | Frontend · Kullanıcı Deneyimi |
| **Güneş Çakmak** | UX/UI · Arayüz Tasarımı |

## 📦 Proje Dosyaları (Google Drive)

Zaman Aynası projesinin **sunumuna, demo videosuna ve APK dosyasına** aşağıdaki Google Drive klasöründen ulaşabilirsiniz.

[📁 Google Drive – Proje Dosyaları](https://drive.google.com/drive/folders/1pzoYKLE0r9O389Aks8fgrbegtpA4A8dE)

## 📚 Kaynak

**Vakıf Katılım — Vakıf Eserleri Envanteri (Bursa, 2025)**. Projede tarihî bilgi ve arşiv görselleri için temel başvuru kaynağıdır.

---

<div align="center">

**Zaman Aynası — Kültürel mirası dijital deneyimle buluşturuyoruz.**

*Kök&Kod Hackathon · 2026*

</div>
