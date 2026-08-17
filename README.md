# NeumoAid — Napas Anak Indonesia

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**NeumoAid (Napas Anak Indonesia)** — platform skrining dini penyakit pneumonia pada anak menggunakan AI analisis suara batuk.

Dibangun untuk orang tua, pengasuh, dan kader Posyandu sebagai deteksi awal pneumonia melalui suara batuk si kecil. Aplikasi bersifat **offline-first**: perekaman, pengolahan audio, dan klasifikasi tetap berfungsi tanpa koneksi internet.

## Fitur

- 🔐 Autentikasi (email & Google)
- 👶 Manajemen data anak (multi-anak, vaksinasi, riwayat medis)
- 🩺 Skrining AI: gejala → rekam suara (waveform) → analisis
- 📊 Laporan hasil: tingkat risiko, keyakinan AI, explainable AI (spektrogram, Grad-CAM, SHAP)
- 🏥 Rekomendasi dokter & fasilitas kesehatan terdekat
- 📈 Riwayat kesehatan, kalender, grafik pertumbuhan
- 📚 Edukasi pneumonia, tips sehat, panduan darurat
- 🔔 Notifikasi vaksinasi & pengingat
- 📴 Offline-first dengan status sinkronisasi
- 🌙 Mode gelap · 📱 Mobile-first & responsif

## Teknologi

- Flutter (Dart SDK ^3.7.2)
- State management: Riverpod (`flutter_riverpod`)
- Basis data lokal: Drift (SQLite) + `drift_flutter`
- Routing: `go_router`
- Rekam audio: `record`
- Machine Learning on-device: `tflite_flutter` (MobileNetV2 int8)
- Sinkronisasi & backend: Supabase (`supabase_flutter`)
- Konektivitas: `connectivity_plus`
- Font: Google Fonts / Inter

## Struktur Proyek

```
lib/
├── app.dart              # Root widget
├── core/                 # Connectivity, navigation, sync, theme, utils, widgets
├── data/                 # Local (Drift), mock, repositories
├── features/             # Fitur per-domain (auth, children, screening, result, ...)
├── models/               # Model domain
└── state/                # State global
```

Fitur per-domain di `lib/features/`:

```
auth | children | education | history | home | notifications
onboarding | profile | result | screening | splash
```

## Pipeline Audio & Deep Learning

Rancangan pipeline perekaman suara → pengolahan → inferensi CNN (VAD, noise suppression, mel-spectrogram, TFLite) terdokumentasi di:

- [neumoaid_flutter_pipeline_ai_guide.md](./neumoaid_flutter_pipeline_ai_guide.md)

## Menjalankan

```bash
flutter pub get
flutter run
```

Untuk menghubungkan ke Supabase (opsional, untuk sinkronisasi ke website dokter):

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://<PROJECT>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<ANON_KEY>
```

Menjalankan codegen Drift (saat model database diubah):

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Kredensial Demo

Akun demo (tersedia otomatis pada instalasi baru):

```
Email    : demoneumoaid@gmail.com
Password : 0k8a0r2d0y5naN
```

### Model Machine Learning

Model TFLite untuk klasifikasi on-device diletakkan di:

```
assets/models/neumoaid_pneumonia_v1.tflite
```

Model ini dihasilkan dari notebook training (Kaggle). Referensi pipeline:
[neumoaid_flutter_pipeline_ai_guide.md](./neumoaid_flutter_pipeline_ai_guide.md).

### Backend & Sinkronisasi

Skema Supabase (tabel `screenings` + bucket `audio`) dan dokumentasi:
`backend/README.md` serta `docs/supabase-guide.md`.

## Menjalankan Test

```bash
flutter test
```

## Lisensi

Dilisensikan di bawah [MIT License](./LICENSE). © 2026 NeumoAid.

Skrining AI bukan pengganti diagnosis medis profesional.
