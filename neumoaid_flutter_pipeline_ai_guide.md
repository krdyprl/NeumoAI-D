# NeumoAid — Panduan Implementasi Pipeline Audio & Deep Learning di Flutter

> Dokumen ini ditulis untuk menjadi konteks bagi AI assistant (mis. Claude Code) yang akan membantu mengimplementasikan pipeline audio dan inferensi deep learning pada aplikasi mobile NeumoAid. Baca seluruh dokumen sebelum mulai menulis kode — beberapa urutan tahap bersifat wajib dan tidak boleh ditukar (lihat Bagian 3).

## 1. Konteks Proyek

NeumoAid adalah aplikasi mobile Flutter untuk skrining dini pneumonia pada balita berdasarkan analisis akustik suara batuk. Aplikasi bersifat **offline-first**: proses rekam, olah, dan klasifikasi audio harus tetap berfungsi tanpa koneksi internet. Hanya visualisasi Grad-CAM (explainability) yang bergantung pada koneksi, karena dihitung di server.

Sumber audio adalah **mikrofon tunggal (mono) smartphone** — bukan microphone array. Teknik yang membutuhkan multi-mikrofon (GCC-PHAT, beamforming) tidak relevan dan tidak digunakan di proyek ini.

## 2. Pipeline Lengkap (Referensi Utama)

```
Audio Smartphone (native rate, ~44.1/48 kHz)
        ↓
Voice Activity Detection (VAD)
        ↓
RNNoise / WebRTC Noise Suppression (di native rate)
        ↓
Band-pass Filter (100–5000 Hz)
        ↓
Resampling → 16 kHz + Normalization
        ↓
Cough Segmentation (Energy Threshold)
        ↓
STFT → Mel Filter Bank → Log-Mel Spectrogram
        ↓
Resize + Channel Matching (224×224×3)
        ↓
CNN (MobileNetV2 / EfficientNet-Lite)
        ↓
Classification (Normal/Pneumonia + Confidence)
        ↓
Grad-CAM  ← TIDAK di on-device, lihat Bagian 4
        ↓
Output
```

## 3. Pemetaan Implementasi per Tahap

| # | Tahap | Teknologi/Binding | Bahasa | Catatan |
|---|-------|-------------------|--------|---------|
| 1 | Audio Capture | Package `record` (atau setara) | Dart | Rekam pada sample rate native perangkat, jangan resample dulu di titik ini |
| 2 | VAD | Model Silero VAD via TFLite | Dart + `tflite_flutter` | Alternatif ke WebRTC VAD (C library) agar tidak perlu binding native terpisah dari CNN |
| 3 | RNNoise / WebRTC NS | Native library C, dibungkus lewat Dart FFI | Dart FFI + native (NDK untuk Android) | **Wajib dijalankan di sample rate native (48kHz), sebelum resampling** — lihat Bagian 4 |
| 4 | Band-pass Filter | Implementasi DSP manual | Dart murni | Filter 100–5000 Hz |
| 5 | Resampling (16kHz) + Normalization | Implementasi DSP manual | Dart murni | Dijalankan **setelah** tahap RNNoise (langkah 3) |
| 6 | Cough Segmentation | Energy threshold sederhana | Dart murni | |
| 7 | STFT → Mel Filter Bank → Log-Mel Spectrogram | Library FFT Dart | Dart murni | Cek dulu status maintenance library FFT yang dipilih (lihat Bagian 6) |
| 8 | Resize + Channel Matching (224×224×3) | Manipulasi array/tensor | Dart murni | Duplikasi channel 1→3, resize ke ukuran input CNN |
| 9 | CNN Inference | Model `.tflite` terkuantisasi int8 | Dart + `tflite_flutter` | Model disiapkan lebih dulu di Python (lihat Bagian 7) |
| 10 | Classification Output | Parsing output tensor | Dart murni | Label + confidence score, langsung ditampilkan ke user meski offline |
| 11 | Grad-CAM | Model full-precision, backend | **Tidak di Flutter** | Lihat Bagian 4 |

## 4. Batasan Teknis Kritis (Wajib Dipatuhi)

1. **RNNoise harus dijalankan pada sample rate native (umumnya 48kHz), sebelum tahap resampling ke 16kHz.** RNNoise didesain dan dilatih khusus untuk 48kHz (frame 20ms/480 sampel); menjalankannya setelah resampling ke 16kHz akan menghasilkan noise suppression yang tidak optimal.
2. **Grad-CAM tidak boleh diimplementasikan on-device.** Runtime TensorFlow Lite tidak mendukung komputasi gradien (backpropagation), yang dibutuhkan Grad-CAM. Implementasi Grad-CAM harus di server, menggunakan model full-precision (bukan versi terkuantisasi), dan hasilnya baru tersedia setelah data pemeriksaan disinkronkan dari device ke server.
3. **Model TFLite hasil kuantisasi harus divalidasi akurasinya terhadap model asli sebelum dibundel ke aplikasi.** Jangan asumsikan kuantisasi int8 otomatis mempertahankan akurasi — lakukan perbandingan eksplisit.
4. **Klasifikasi (label + confidence) harus tetap tampil ke user meski offline/belum sync.** Jangan buat UI menunggu Grad-CAM untuk menampilkan hasil awal — heatmap menyusul setelah sinkronisasi.
5. **RNNoise adalah satu-satunya komponen yang wajib native binding (FFI/NDK).** Tahap lain (band-pass, resampling, normalization, segmentation, STFT/Mel) feasible ditulis di Dart murni untuk klip audio pendek (~1–2 detik per episode batuk).

## 5. Strategi Rollout (Fase Implementasi)

Mengikuti pendekatan "mock dulu, integrasi bertahap" yang sudah diadopsi untuk arsitektur Flutter secara keseluruhan:

1. **Fase 1** — UI selesai dengan mock repository (data hasil skrining berupa data dummy).
2. **Fase 2** — Integrasi TFLite untuk CNN saja: pipeline minimal (resample → normalize → segment sederhana → log-mel → CNN), **tanpa VAD/RNNoise dulu**. Tujuan: memastikan alur end-to-end benar-benar jalan di device.
3. **Fase 3** — Tambahkan VAD (Silero via TFLite) dan noise suppression (RNNoise via FFI). Lakukan pengujian A/B (dengan vs tanpa tahap ini) terhadap akurasi klasifikasi akhir untuk memvalidasi manfaatnya.
4. **Fase 4** — Sambungkan sinkronisasi ke backend untuk Grad-CAM dan alur offline-first penuh (local storage, sync queue, status pending/synced).

**Catatan risiko:** Integrasi RNNoise via FFI (langkah 3 di tabel Bagian 3) adalah komponen dengan risiko waktu pengerjaan tertinggi karena butuh native compilation, bukan sekadar `flutter pub add`. Jika ini memakan waktu lebih lama dari perkiraan, fallback yang disarankan: jalankan pipeline tanpa RNNoise dulu (band-pass filter + normalization + energy threshold saja) agar Fase 2 tidak terhambat, lalu tambahkan RNNoise sebagai peningkatan kualitas pada Fase 3.

## 6. Catatan Dependency

Status package berikut (pub.dev) belum diverifikasi terkini oleh asisten AI (tidak ada akses browsing saat dokumen ini dibuat) — **cek ulang status maintenance dan API sebelum digunakan**:
- Package rekam audio (`record` atau setara)
- `tflite_flutter` untuk inferensi TFLite
- Library FFT Dart untuk STFT/Mel Filter Bank
- Model Silero VAD dalam format TFLite/ONNX yang kompatibel

## 7. Persiapan Model (Python, Sebelum Masuk Flutter)

Langkah ini dilakukan di sisi Python/training, sebelum model dibundel ke aplikasi:

1. Latih model CNN (MobileNetV2/EfficientNet-Lite) hingga performa tervalidasi (lihat metrik evaluasi: accuracy, precision, sensitivity/recall, specificity, F1-score, ROC-AUC, confusion matrix).
2. Konversi model ke format TFLite menggunakan `TFLiteConverter`, dengan *post-training quantization* int8, memakai representative dataset untuk kalibrasi.
3. Validasi: bandingkan akurasi model `.tflite` terkuantisasi terhadap model asli (full-precision) — pastikan tidak ada penurunan performa signifikan sebelum lanjut.
4. Setelah tervalidasi, letakkan file `.tflite` di folder `assets/` proyek Flutter dan daftarkan di `pubspec.yaml`.
5. Simpan juga versi full-precision model di backend untuk digunakan pada komputasi Grad-CAM (lihat Bagian 4, poin 2).
