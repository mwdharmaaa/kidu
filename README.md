# Qidu - Studio Offline Audio Player (Flutter Android)

**Qidu** adalah aplikasi pemutar musik lokal resolusi tinggi untuk Android dengan antarmuka modern bernuansa *fluid ambient blur*, kontrol pemutaran lengkap, serta dukungan equalizer hardware native.

---

## 🚀 Fitur Utama

### 1. Kualitas Audio Lossless & Hi-Res
- **Lossless Audio**: Decoding audio resolusi tinggi hingga 24-bit/48 kHz (FLAC, ALAC, WAV).
- **Hi-Res Lossless**: Format bit-for-bit tanpa kompresi hingga 24-bit/192 kHz.
- **Badge Audio Dinamis**: Indikator kualitas interaktif (*LOSSLESS*, *HI-RES LOSSLESS*, *HIGH QUALITY*) di layar pemutar.

### 2. Pengaturan Audio Lengkap
- **Sound Check (Normalisasi Volume)**: Menyeimbangkan tingkat kenyaringan suara antar-lagu secara otomatis.
- **Crossfade**: Transisi transparan dan halus antar-lagu (dapat diatur 1–12 detik).
- **Gapless Playback**: Menghilangkan jeda sunyi antar-trek pada album konsep atau rekaman konser.
- **Sleep Timer**: Pengatur waktu mati otomatis (15 menit, 30 menit, 1 jam, atau di akhir trek yang sedang diputar).

### 3. Kontrol Pemutaran & Manajemen File
- **Shuffle & Loop**: Pengacakan daftar putar dan mode pengulangan (Repeat All, Repeat One, Off).
- **Delete Audio**: Hapus berkas lagu yang tidak diinginkan langsung dari memori penyimpanan dengan dialog konfirmasi aman.
- **Pencarian Cepat**: Cari lagu dan artis dalam pustaka lokal secara instan.

### 4. 10-Band Hardware Equalizer
- Terhubung langsung ke hardware audio Android (`AudioPipeline` + `AndroidEqualizer`).
- Preset terkalibrasi (*Flat, Bass Booster, Bass Reducer, Classical, Electronic, Hip-Hop, Pop, Rock, Vocal Booster*).
- Slider grafik vertikal per-frekuensi (60 Hz s/d 14 kHz) dengan penunjuk decibel (-15 dB s/d +15 dB).

### 5. Background Playback & Lock Screen
- Kontrol pemutaran di bar notifikasi dan lock screen dengan `just_audio_background`.
- Latar belakang gradasi dinamis yang beradaptasi dengan palet warna cover lagu.

---

## 📁 Struktur Direktori

```
qidu/
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml   <-- Izin storage, audio service & notification
├── lib/
│   ├── main.dart                 <-- Inisialisasi background service & QiduApp
│   ├── theme/
│   │   └── qidu_theme.dart       <-- Palet warna OLED Dark & aksen Qidu
│   ├── services/
│   │   └── audio_player_manager.dart <-- Core audio player & equalizer engine
│   └── views/
│       ├── home/
│       │   └── home_screen.dart   <-- Library musik & pencarian lagu
│       ├── player/
│       │   ├── player_screen.dart <-- Fullscreen player dengan badge Lossless
│       │   └── widgets/
│       │       └── mini_player.dart <-- Floating frosted-glass mini player
│       ├── equalizer/
│       │   └── equalizer_screen.dart <-- Tampilan 10-band equalizer & presets
│       └── settings/
│           └── settings_screen.dart  <-- Pengaturan Lossless, Sound Check, Crossfade, Timer
└── pubspec.yaml                  <-- Konfigurasi dependensi Qidu
```

---

## 🛠️ Cara Menjalankan Project

```bash
# 1. Masuk ke direktori project
cd qidu

# 2. Ambil semua dependencies
flutter pub get

# 3. Jalankan di perangkat Android / Emulator
flutter run
```
