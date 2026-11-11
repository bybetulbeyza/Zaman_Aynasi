<div align="center">

# 🏛️ Zaman Aynası · Mirror of Time

### See the past, discover the story, own the heritage.

**Kök&Kod Hackathon 2026 · Waqf Works · Bursa**

*Instead of walking past it, looking at it knowingly.*

**🇬🇧 English** · [🇹🇷 Türkçe](README.md)

</div>

## 📖 About the Project

**Zaman Aynası** ("Mirror of Time") is a digital open-air museum that makes the waqf (vakıf) heritage of Bursa easier and more interactive to explore. It brings the historical inventory to life with then-and-now comparisons, interactive hotspots, short story videos, audio narration and themed walking routes.

The project was developed for the **Kök&Kod Hackathon**. Our starting point is to bring the **385 waqf works**, **34,952 photographs** and **3 volumes** of historical information for Bursa in Vakıf Katılım's *Waqf Works Inventory* to a much wider audience.

> **Our goal:** not just to have the inventory read, but to show, let people listen to, and help them discover cultural heritage on site.

## ✨ Key Features

| Feature | Description |
| --- | --- |
| 🕰️ **Then & Now** | Compare historical and current photos with a split slider; 3D models of the past and the present for selected works. |
| 📍 **Interactive Hotspots** | Reach architectural and historical details through special points on photos; a step-by-step tour of each work. |
| 🎬 **Short Story Videos** | Explore stories of works and hotspots as vertical micro-cinematics with subtitles. |
| 🎧 **Audio Guide** | Audio narration, written text and subtitles, so everyone can access the same story. |
| 🗺️ **Themed & Personal Routes** | Ready-made routes, or walking routes tailored to your starting point, time and interests. |
| 🏅 **Tasks & Stamp Passport** | Collect digital stamps by completing tasks on site, earn titles and share cards. |
| 🏛️ **Complex Structure** | Large sites such as the Green Complex are split into separate pages for the mosque, tomb, madrasa and more. |
| 🌐 **Accessibility** | Turkish/English language support, three text sizes, high contrast, dark mode and screen reader labels. |

## 🧒 Yadigâr: The Guide of the Stories

**Yadigâr** is a small character with a consistent visual identity who accompanies users in the story videos. Rather than talking over the story, it guides the viewer toward the details of the work.

Our video production flow:

**Inventory information → Short script → Character frames → AI-assisted motion → Voice-over and subtitles**

Historical scenes created with AI are labelled **"Historical recreation / AI-generated"**, so they are not mistaken for real archive footage.

## 🔎 Source Reliability

- Historical information is sourced to the volume and page references of the *Waqf Works Inventory*.
- Historical recreations created with AI are clearly labelled.
- Users can report mistakes or wrong information about a work.
- Content is designed to be offered in more than one language.

## 🚀 Future Plans

Alongside the waqf works themselves, we aim to use **digital information screens** to present the then-and-now comparisons and short historical stories to visitors even without opening the app. The content architecture is built so it can grow with new cities and new works.

## 🛠️ Running the App

Requirements: [Flutter](https://docs.flutter.dev/get-started/install) (stable) and a [Mapbox](https://account.mapbox.com/) public token (`pk.…`).

```bash
git clone https://github.com/bybetulbeyza/Zaman_Aynasi.git
cd Zaman_Aynasi
flutter pub get
```

Create an `env.json` file in the project root (it is not committed to git):

```json
{
  "MAPBOX_TOKEN": "pk.YOUR_MAPBOX_TOKEN"
}
```

Run, or build an APK:

```bash
flutter run --dart-define-from-file=env.json
flutter build apk --release --dart-define-from-file=env.json
```

> Without `env.json` the app opens, but the map and walking info will not show. The Supabase connection is set up in the code, so no extra configuration is needed.

## 👥 Team

| Name | Role |
| --- | --- |
| **Betül Beyza Demirel** | Team Captain · Data Collection and Content |
| **Mehmethan Ural** | Backend · Data Layer |
| **Mehtap Aslan** | Frontend · User Experience |
| **Güneş Çakmak** | UX/UI · Interface Design |

## 📦 Project Files (Google Drive)

The **presentation, demo video and APK file** of Zaman Aynası are available in the Google Drive folder below.

[📁 Google Drive – Project Files](https://drive.google.com/drive/folders/1pzoYKLE0r9O389Aks8fgrbegtpA4A8dE)

## 📚 Source

**Vakıf Katılım — Waqf Works Inventory (Bursa, 2025)**. The main reference for the historical information and archive images in the project.

---

<div align="center">

**Zaman Aynası — Bringing cultural heritage together with digital experience.**

*Kök&Kod Hackathon · 2026*

</div>
