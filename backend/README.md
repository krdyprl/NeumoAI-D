# Integrasi Backend (Supabase) — NeumoAI-D

Aplikasi Flutter **offline-first**: klasifikasi batuk on-device (TFLite),
rekam audio nyata, dan sinkronisasi data ke **Supabase** untuk website dokter
([NeumoAIweb](D:\NeumoAIweb)).

## Arsitektur

```
[HP Flutter — OFFLINE-FIRST]
  record (WAV) → DSP on-device (resample→16k, log-mel) → TFLite classify
    → hasil tampil offline → simpan lokal Drift
    → online: upload audio + metadata → Supabase

[Supabase]
  Auth · Postgres `screenings` · Storage bucket `audio`

[Website Dokter (NeumoAIweb)]
  login → daftar skrining → play audio → Grad-CAM (ONNX Web di browser)
```

## Setup Supabase

1. Buka [supabase.com](https://supabase.com) → buat proyek baru.
2. Salin **Project URL** dan **anon public key**.
3. Di **SQL Editor**, jalankan skema: `backend/supabase_schema.sql`
   (sudah selaras dengan skema website dokter: tabel `screenings` + bucket `audio`).
4. Jalankan aplikasi dengan kredensial:
   ```powershell
   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
               --dart-define=SUPABASE_ANON_KEY=eyJ...
   ```

## Alur data

- **Rekam**: `record_screen.dart` merekam WAV 5 detik sungguhan.
- **Klasifikasi on-device**: `core/ml/cough_classifier.dart` memakai
  `assets/models/neumoaid_pneumonia_v1.tflite` (dari Kaggle). Selama model
  belum ada, memakai placeholder (disease=Pneumonia, confidence=87).
- **Sync**: `record_screen._syncToSupabase` mengunggah audio ke bucket
  `audio` dan menyisipkan baris ke tabel `screenings` (skema website dokter:
  `id` uuid, `child_id`, `audio_url`, `status='awaiting'`).

## Kolom tabel `screenings` (selaras NeumoAIweb)

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | generate di app (uuid v4) |
| child_id | text NOT NULL | id anak |
| child_name | text | (opsional) |
| date | timestamptz | waktu skrining |
| symptoms | text[] | daftar gejala |
| audio_duration | numeric | durasi audio |
| risk_level | text | low/medium/high |
| disease | text | hasil klasifikasi |
| confidence | numeric | keyakinan AI |
| audio_url | text | path storage (childId/<file>.wav) |
| status | text | awaiting/accepted/rejected/done |
| created_at | timestamptz | auto |

## Menunggu dari Kaggle

- `assets/models/neumoaid_pneumonia_v1.tflite` → on-device klasifikasi.
- (untuk website) `public/models/mobilenetv2.onnx` → Grad-CAM di browser.
