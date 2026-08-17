# NeumoAid — Panduan Instalasi untuk Developer & Juri

Dokumen ini memandu instalasi dan menjalankan **NeumoAid (Napas Anak Indonesia)** — platform
skrining dini pneumonia pada anak menggunakan AI analisis suara batuk.

Panduan terbagi menjadi 3 bagian:

| Bagian | Topik | Sifat |
|---|---|---|
| [1. Aplikasi Flutter](#bagian-1--aplikasi-flutter) | Menjalankan aplikasi utama | **Wajib** |
| [2. Backend Supabase](#bagian-2--backend-supabase) | Sinkronisasi data ke cloud | Opsional |
| [3. Reproduce Model AI](#bagian-3--reproduce-model-ai-opsional) | Training model batuk | Opsional / lanjutan |

> **Jalur tercepat untuk juri:** cukup lakukan **Bagian 1**. Aplikasi bersifat
> **offline-first** — perekaman, pengolahan audio, dan klasifikasi AI tetap berfungsi
> tanpa koneksi internet maupun kredensial backend.

---

## Daftar Isi

- [Bagian 0 — Gambaran Proyek](#bagian-0--gambaran-proyek)
- [Bagian 1 — Aplikasi Flutter](#bagian-1--aplikasi-flutter)
  - [1.1 Prasyarat](#11-prasyarat)
  - [1.2 Instalasi Flutter SDK](#12-instalasi-flutter-sdk)
  - [1.3 Mengambil & Mempersiapkan Source Code](#13-mengambil--mempersiapkan-source-code)
  - [1.4 Instalasi Dependensi](#14-instalasi-dependensi)
  - [1.5 Menjalankan Aplikasi](#15-menjalankan-aplikasi)
  - [1.6 Mode Offline vs Online](#16-mode-offline-vs-online)
  - [1.7 Membangun APK Release](#17-membangun-apk-release)
- [Bagian 2 — Backend Supabase](#bagian-2--backend-supabase)
  - [2.1 Prasyarat](#21-prasyarat)
  - [2.2 Membuat Proyek Supabase](#22-membuat-proyek-supabase)
  - [2.3 Menjalankan Skema SQL](#23-menjalankan-skema-sql)
  - [2.4 Menyambungkan Aplikasi](#24-menyambungkan-aplikasi)
- [Bagian 3 — Reproduce Model AI (opsional)](#bagian-3--reproduce-model-ai-opsional)
  - [3.1 Prasyarat](#31-prasyarat)
  - [3.2 Menjalankan Notebook](#32-menjalankan-notebook)
  - [3.3 Memasang Model ke Aplikasi](#33-memasang-model-ke-aplikasi)
- [Bagian 4 — Troubleshooting](#bagian-4--troubleshooting)
- [Lisensi & Disclaimer](#lisensi--disclaimer)

---

## Bagian 0 — Gambaran Proyek

**NeumoAid** adalah aplikasi mobile Flutter untuk deteksi awal pneumonia pada balita melalui
analisis akustik suara batuk. Dibangun untuk orang tua, pengasuh, dan kader Posyandu.

### Arsitektur

```
[Smartphone — FLUTTER]
  record (mikrofon) → DSP on-device → TFLite klasifikasi (offline)
    → hasil tampil lokal (Drift/SQLite)
    → online: upload audio + metadata → Supabase

[Supabase]
  Auth · tabel `screenings` · storage bucket `audio`

[TrainAI — Python]
  dataset (Liao 2022 + COUGHVID) → preprocessing → CNN (MobileNetV2)
    → export model .tflite (int8) → dibundel ke aplikasi
```

### Komponen & file penting

| Komponen | Lokasi | Keterangan |
|---|---|---|
| Aplikasi Flutter | `lib/`, `assets/` | Aplikasi utama (Riverpod, Drift, go_router, TFLite) |
| Model TFLite on-device | `assets/models/neumoaid_pneumonia_v1.tflite` | Model klasifikasi batuk (sudah tersedia) |
| Skema Supabase | `backend/supabase_schema.sql` | Tabel `screenings` + bucket `audio` |
| Notebook training | `trainAI/neumoaid_pneumonia_training.ipynb` | Reproduce model (opsional) |

### Kebutuhan minimal

| Kebutuhan | Bagian 1 (Wajib) | Bagian 2 (Opsional) | Bagian 3 (Opsional) |
|---|---|---|---|
| Flutter SDK | ✅ | — | — |
| Android emulator / device | ✅ | — | — |
| Akun Supabase | — | ✅ | — |
| Python + dataset | — | — | ✅ |

---

## Bagian 1 — Aplikasi Flutter

### 1.1 Prasyarat

| Prasyarat | Versi | Catatan |
|---|---|---|
| Flutter SDK | Dart SDK ^3.7.2 | Wajib |
| Android Studio (atau VS Code) | Terbaru | Editor + Android toolchain |
| Android SDK & platform-tools | API 34+ | Via Android Studio |
| Emulator / device fisik | Android 7.0+ | Untuk menjalankan aplikasi |
| Git | Terbaru | Untuk clone repository |

**Verifikasi awal** setelah Flutter terinstal:

```bash
flutter doctor
```

Pastikan baris `Flutter` dan `Android toolchain` berstatus **OK** (tanpa tanda `!`).
Jika ada masalah (mis. `Android license status unknown`), jalankan:

```bash
flutter doctor --android-licenses
```

### 1.2 Instalasi Flutter SDK

Jika belum punya Flutter, ikuti langkah resmi:

1. Kunjungi https://docs.flutter.dev/get-started/install → pilih platform (Windows/macOS/Linux).
2. Unduh Flutter SDK stable, ekstrak ke folder (mis. `C:\flutter`).
3. Tambahkan `flutter` ke `PATH`.
4. Verifikasi:

```bash
flutter --version
```

### 1.3 Mengambil & Mempersiapkan Source Code

```bash
git clone <url-repository-neumoai> neumoaid
cd neumoaid
```

Buka folder proyek di editor pilihan Anda. Struktur penting:

```
lib/            # Kode aplikasi Flutter
assets/         # Gambar, font, model (.tflite)
backend/        # Skema Supabase (+ backend opsional)
trainAI/        # Notebook training model (opsional)
docs/           # Dokumentasi (lisensi, panduan Supabase)
```

### 1.4 Instalasi Dependensi

Unduh semua package dari `pubspec.yaml`:

```bash
flutter pub get
```

**Regenerasi codegen Drift** (wajib saat model database berubah — jalankan sekali agar aman):

```bash
dart run build_runner build --delete-conflicting-outputs
```

> Perintah di atas menghasilkan file `.g.dart` untuk database Drift/SQLite.
> Jika muncul error versi, pastikan `flutter pub get` sudah dijalankan lebih dulu.

### 1.5 Menjalankan Aplikasi

1. Buka emulator (Android Studio → Device Manager → launch) atau sambungkan device fisik
   (aktifkan USB debugging).
2. Jalankan:

```bash
flutter run
```

3. Tunggu hingga aplikasi terbuild dan muncul di emulator/device.

**Alur demo:** onboarding → daftar anak → fitur skrining → tekan "Rekam" → suara batuk
direkam (5 detik) → hasil klasifikasi (tingkat risiko + keyakinan AI) ditampilkan.

> Aplikasi berjalan **offline-first**: tanpa kredensial backend, seluruh fitur klasifikasi
> tetap berfungsi. Lihat Bagian 1.6.

### 1.6 Mode Offline vs Online

- **Offline (default):** `flutter run` tanpa `--dart-define`. Klasifikasi on-device TFLite
  tetap jalan, data disimpan lokal di Drift/SQLite. Panggilan Supabase menjadi no-op.
- **Online (Supabase sync):** tambahkan kredensial saat menjalankan (lihat Bagian 2.4).

### 1.7 Membangun APK Release

Untuk membangun file APK yang bisa diinstal langsung ke device:

```bash
flutter build apk --release
```

APK dihasilkan di `build/app/outputs/flutter-apk/app-release.apk`.
(Untuk mode online, tambahkan `--dart-define` seperti di Bagian 2.4.)

---

## Bagian 2 — Backend Supabase

Bagian ini opsional — diperlukan hanya jika ingin menguji **sinkronisasi data** skrining
(hasil dari app muncul di website dokter / dashboard).

### 2.1 Prasyarat

- Akun di [supabase.com](https://supabase.com) (gratis).
- Project URL & anon public key dari proyek Supabase Anda.

### 2.2 Membuat Proyek Supabase

1. Buka https://supabase.com → **New project**.
2. Isi nama proyek & password database (simpan password-nya).
3. Setelah dibuat, buka **Project Settings → API** untuk melihat:
   - **Project URL** (contoh: `https://xxxxxxxx.supabase.co`)
   - **anon public key** (`eyJ...`)
4. Salin kedua nilai tersebut — akan dipakai di Bagian 2.4.

### 2.3 Menjalankan Skema SQL

1. Di dashboard Supabase, buka **SQL Editor → New query**.
2. Salin isi file `backend/supabase_schema.sql`.
3. Klik **Run**.

Skema ini membuat:

- Tabel `public.screenings` (hasil skrining: disease, confidence, risk_level, dll.)
- Storage bucket `audio` (untuk menyimpan rekaman batuk)
- Policy RLS agar data bisa dibaca/diisi untuk demo

### 2.4 Menyambungkan Aplikasi

Kredensial dimasukkan lewat `--dart-define` (tidak disimpan di kode). Ganti `<PROJECT_URL>`
dan `<ANON_KEY>` dengan nilai dari Bagian 2.2.

**Mode development (Windows PowerShell):**

```powershell
flutter run --dart-define=SUPABASE_URL=<PROJECT_URL> `
            --dart-define=SUPABASE_ANON_KEY=<ANON_KEY>
```

**Mode development (Linux/macOS):**

```bash
flutter run \
  --dart-define=SUPABASE_URL=<PROJECT_URL> \
  --dart-define=SUPABASE_ANON_KEY=<ANON_KEY>
```

**Build APK release (mode online):**

```powershell
flutter build apk --release `
  --dart-define=SUPABASE_URL=<PROJECT_URL> `
  --dart-define=SUPABASE_ANON_KEY=<ANON_KEY>
```

> **Verifikasi sinkronisasi:** setelah menjalankan skrining, buka **Supabase Dashboard →
> Table Editor → `screenings`** dan pastikan baris baru muncul. Rekaman audio berada di
> **Storage → `audio`**.

---

## Bagian 3 — Reproduce Model AI (opsional)

Bagian ini hanya untuk juri/developer yang ingin **melatih ulang model klasifikasi batuk**
dari awal. Model `.tflite` sudah tersedia di `assets/models/`, sehingga bagian ini **tidak
wajib** untuk menjalankan aplikasi.

> **Penting:** Notebook ini adalah *pipeline validation* (eksperimen awal), **bukan** model
> final untuk laporan/resensi. Baca peringatan di dalam notebook sebelum mengutip angkanya.

### 3.1 Prasyarat

- **Python 3** dengan Jupyter/Kaggle/Colab.
- **Data (butuh akses):**
  - Kelas Pneumonia: Liao et al. 2022 (figshare) — 82 rekaman.
  - Kelas Healthy: dataset COUGHVID (publik).
- Install package: `tensorflow`, `librosa`, `soundfile`, `scipy`, `numpy`,
  `scikit-learn`, `webrtcvad`, `noisereduce`, `pyrnnoise`, `ffmpeg`.

### 3.2 Menjalankan Notebook

**Opsi A — Kaggle (dianjurkan):**

1. Buat dataset Kaggle berisi data audio (mengikuti struktur path di notebook bagian CONFIG).
2. Buka `trainAI/neumoaid_pneumonia_training.ipynb` → **Copy Code** ke notebook Kaggle
   atau upload notebook.
3. Jalankan sel secara berurutan (Ctrl+F9 / Run all).

**Opsi B — Colab:**

1. Upload notebook ke Google Colab.
2. Pasang Google Drive (sel akan otomatis `drive.mount`).
3. Pastikan data berada di path yang dikonfigurasi (variabel `DATA_ROOT`).

**Opsi C — Lokal:**

```bash
pip install -r backend/requirements.txt
jupyter notebook trainAI/neumoaid_pneumonia_training.ipynb
```

Sesuaikan variabel `DATA_ROOT`, `DATA_PREFIX`, `PNEUMONIA_DIR`, dan `COUGHVID_AUDIO_DIR`
di bagian **CONFIG** dengan lokasi dataset Anda.

### 3.3 Memasang Model ke Aplikasi

1. Setelah notebook selesai, file `neumoaid_pneumonia_v1.tflite` dihasilkan di `OUTPUT_DIR`.
2. Salin ke `assets/models/neumoaid_pneumonia_v1.tflite` (menimpa model lama).
3. Pastikan nama file cocok dengan deklarasi di `pubspec.yaml`:

```yaml
assets:
  - assets/models/
```

4. Rebuild aplikasi:

```bash
flutter pub get
flutter run
```

---

## Bagian 4 — Troubleshooting

| Gejala | Kemungkinan penyebab | Solusi |
|---|---|---|
| Klasifikasi selalu placeholder (Pneumonia 87%) | File `.tflite` tidak terbaca | Pastikan `assets/models/neumoaid_pneumonia_v1.tflite` ada & terdaftar di `pubspec.yaml`. |
| Error codegen Drift (`*.g.dart` tidak ada) | `build_runner` belum dijalankan | Jalankan `dart run build_runner build --delete-conflicting-outputs`. |
| `flutter doctor` menampilkan Android license error | Lisensi SDK belum diterima | `flutter doctor --android-licenses`. |
| Aplikasi tidak terhubung ke Supabase | Kredensial belum/salah diisi | Pastikan `--dart-define` diisi URL + anon key yang benar (Bagian 2.4). |
| Data tidak muncul di tabel `screenings` | RLS policy / skema salah | Jalankan ulang `backend/supabase_schema.sql`; pastikan policy `screenings_insert_public`. |
| Audio tidak bisa diputar | Bucket `audio` tak punya policy read | Pastikan bucket `audio` dibuat (lihat skema SQL). |
| `flutter pub get` gagal | Versi SDK tidak sesuai | Pastikan Dart SDK ^3.7.2 (`flutter --version`). |

---

## Lisensi & Disclaimer

© 2026 NeumoAid. Skrining AI bukan pengganti diagnosis medis profesional.

- Lisensi lengkap: `docs/LISENSI.md`
- Panduan Supabase mendetail: `docs/supabase-guide.md`
