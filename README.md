# Kidu - Local Music Player with Hardware Equalizer (Flutter Android)

**Kidu** adalah aplikasi pemutar musik lokal modern untuk Android yang memadukan estetika Apple Music (OLED dark mode, dynamic album art color blur, frosted glass mini player) dengan keandalan equalizer hardware native Android.

---

## 🚀 Fitur Utama

1. **Apple Music Visual Design**:
   - Dynamic Mesh Gradient Background yang otomatis berubah warna mengikuti cover album lagu yang sedang diputar (`palette_generator`).
   - Frosted glass blur effect pada Mini Player (`BackdropFilter`).
   - Modern scrubbing timeline slider.
   - Clean SF-styled typography & icon sets (`cupertino_icons`).

2. **10-Band Hardware Equalizer (`just_audio` AndroidEqualizer)**:
   - Terhubung langsung ke hardware audio Android (`AudioPipeline` + `AndroidEqualizer`).
   - Preset lengkap bawaan Android (*Flat, Rock, Pop, Hip Hop, Jazz, Classical, Heavy Metal*, dll.).
   - Slider grafik vertikal per-frekuensi (60 Hz s/d 14 kHz) dengan penunjuk decibel (-15 dB s/d +15 dB).
   - Master switch toggle (ON/OFF) & tombol Reset to Flat.

3. **Background Playback & Lock Screen Notification**:
   - Didukung oleh `just_audio_background` (`audio_service`).
   - Kontrol Play, Pause, Next, Previous langsung dari Android Notification Bar & Lock Screen.

4. **Media Library Scanner**:
   - Menggunakan `on_audio_query` untuk memindai audio lokal dan thumbnail cover art secara cepat.
   - Menangani izin penyimpanan Android 13+ (`READ_MEDIA_AUDIO`) dan Android 12 ke bawah (`READ_EXTERNAL_STORAGE`).

---

## 📁 Struktur Direktori

```
kidu/
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml   <-- Izin storage, audio service & notification
├── lib/
│   ├── main.dart                 <-- Inisialisasi background service & App root (KiduApp)
│   ├── theme/
│   │   └── apple_music_theme.dart<-- Palet warna & dark theme Apple Music
│   ├── services/
│   │   └── audio_player_manager.dart <-- Core audio player & equalizer engine
│   └── views/
│       ├── home/
│       │   └── home_screen.dart   <-- Library musik & pencarian lagu
│       ├── player/
│       │   ├── player_screen.dart <-- Fullscreen player dengan background dinamis
│       │   └── widgets/
│       │       └── mini_player.dart <-- Floating frosted-glass mini player
│       └── equalizer/
│           └── equalizer_screen.dart <-- Tampilan 10-band equalizer & presets
└── pubspec.yaml                  <-- Konfigurasi dependensi Kidu
```

---

## 🛠️ Cara Menjalankan Project

```bash
# 1. Masuk ke direktori project
cd kidu

# 2. Ambil semua dependencies
flutter pub get

# 3. Hubungkan perangkat Android / Emulator dan jalankan
flutter run
```
