# Panduan Setup Supabase — NeumoAI-D (App + Website Dokter)

Panduan menyambungkan aplikasi Flutter **NeumoAI-D** dan website dokter
**NeumoAIweb** ke Supabase, termasuk pemasangan model ML.

## Konfigurasi Proyek

- **Project URL**: `https://nminszdmovdhlhuolaai.supabase.co`
- **Anon public key**: (lihat kredensial di `.env` website / `--dart-define` app)

---

## 1. Jalankan Skema SQL (sekali)

Di **Supabase Dashboard → SQL Editor → New query**, jalankan:

- Dari Flutter: `backend/supabase_schema.sql`
- (Atau dari website: `NeumoAIweb/supabase/migrations/0001_init.sql` + `0002_bucket.sql`)

Yang dibuat:
- Tabel `public.screenings` (skema konsisten untuk app & website)
- Storage bucket `audio`

> **PENTING**: Pakai **satu skema saja**. Kolom tabel harus identik antara app
> dan website, kalau tidak data tidak terbaca.

---

## 2. Setup Aplikasi Flutter

Kredensial dimasukkan lewat `--dart-define` (tidak disimpan di kode):

```powershell
cd D:\NeumoAI-D
flutter run --dart-define=SUPABASE_URL=https://nminszdmovdhlhuolaai.supabase.co `
            --dart-define=SUPABASE_ANON_KEY=eyJ...
```

Untuk build release:

```powershell
flutter build apk --release `
  --dart-define=SUPABASE_URL=https://nminszdmovdhlhuolaai.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

Tanpa kredensial, app **tetap jalan offline** (semua panggilan Supabase
jadi no-op, klasifikasi on-device tetap berfungsi).

### Model on-device
Model `neumoaid_pneumonia_v1_int8.tflite` sudah disalin ke
`assets/models/neumoaid_pneumonia_v1.tflite` dan didaftarkan di `pubspec.yaml`.
Klasifikasi dijalankan di `lib/core/ml/cough_classifier.dart` (dengan handling
kuantisasi int8).

---

## 3. Setup Website Dokter (NeumoAIweb)

Di `D:\NeumoAIweb`:

1. Buat file `.env` (sudah dibuat):
   ```env
   VITE_SUPABASE_URL=https://nminszdmovdhlhuolaai.supabase.co
   VITE_SUPABASE_ANON_KEY=eyJ...
   ```
2. Jalankan:
   ```bash
   pnpm install
   pnpm dev        # lokal: http://localhost:5173
   pnpm build      # produksi
   ```

### Model Grad-CAM
Model `neumoaid_pneumonia_v1.onnx` sudah disalin ke
`public/models/mobilenetv2.onnx`. `src/lib/model.ts` sudah diperbaiki agar
cocok dengan model (input `[1,224,224,3]`, output sigmoid 1 nilai).

---

## 4. Alur Data

```
[HP Flutter]
  rekam (WAV) → DSP on-device (224x224x3) → TFLite klasifikasi
    → hasil tampil offline (Drift lokal)
    → online: upload audio ke bucket `audio` + insert baris `screenings`
        (status 'awaiting', audio_url = path storage)

[Supabase]
  storage bucket `audio` · tabel `screenings`

[Website Dokter]
  login → baca `screenings` → putar audio (dari bucket)
    → ONNX Runtime Web hitung Grad-CAM di browser → tampilkan heatmap
```

---

## 5. Kolom Tabel `screenings` (konsisten)

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | id skrining |
| child_id | text NOT NULL | id anak |
| child_name | text | (opsional) |
| user_id | uuid | pemilik (opsional untuk anon) |
| date | timestamptz | waktu skrining |
| symptoms | text[] | gejala |
| audio_duration | numeric | durasi audio |
| risk_level | text | low/medium/high |
| disease | text | hasil klasifikasi |
| confidence | numeric | keyakinan AI |
| audio_url | text | path storage (childId/<file>.wav) |
| status | text | awaiting/accepted/rejected/done |
| outcome | text | catatan dokter |
| model_version | text | versi model |
| trend | numeric[] | tren |
| vitals | jsonb | data vital |
| created_at | timestamptz | auto |

---

## 6. Troubleshooting

- **Data tidak muncul di website** → cek skema tabel identik + RLS policy
  `screenings_read_all` mengizinkan `true`.
- **Audio tidak bisa diputar** → pastikan bucket `audio` punya policy read
  (public/authenticated) dan `audio_url` berisi path storage (bukan URL penuh).
- **Klasifikasi selalu placeholder** → pastikan `.tflite` ada di
  `assets/models/` dan terdaftar pubspec.
- **Website Grad-CAM kosong/placeholder** → pastikan `.onnx` ada di
  `public/models/mobilenetv2.onnx` dan model ter-load di browser.

---

## 7. Menunggu dari Kaggle (bila belum)

Jika training Kaggle belum selesai, app memakai **placeholder** (Pneumonia 87%)
dan website memakai **fallback heatmap**. Setelah selesai, file model di atas
langsung dipakai tanpa perubahan kode.
