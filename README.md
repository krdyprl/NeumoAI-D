# NeumoAI-D

**NeummoAi-D (Napas Anak Indonesia)** — platform skrining dini penyakit pneumonia pada anak menggunakan AI analisis suara batuk.

Dibangun untuk orang tua, pengasuh, dan kader Posyandu sebagai deteksi awal pneumonia melalui suara batuk si kecil.

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

- React 19 + TypeScript
- Vite 8
- Tailwind CSS v4
- Font Inter
- Desain sistem Material-style (Material Design 3)

## Menjalankan

```bash
pnpm install
pnpm dev
```

Build produksi:

```bash
pnpm build
```

## Lisensi

© 2026 NeummoAi-D. Skrining AI bukan pengganti diagnosis medis profesional.
