# Desain — Migrasi NeumoAI-D ke Flutter (Android, Parents)

Tanggal: 2026-08-05
Status: Disetujui untuk implementasi
Rujukan: PRD `2026-08-05-prd.md`

## 1. Keputusan Arsitektur

| Keputusan | Pilihan | Alasan |
|---|---|---|
| Bahasa | Dart + Flutter 3.29 (stable) | Sudah terpasang (Dart 3.7) |
| State management | Riverpod (`flutter_riverpod`) | Compile-safe, mudah di-test, cocok untuk repository layer |
| Routing | `go_router` | Stack + back support, declarative, StatefulShellRoute untuk 4 tab |
| Database lokal | Drift (SQLite) | Typo-safe, query kompleks, migrasi baik untuk skrining + antrean sync |
| Konektivitas | `connectivity_plus` | Deteksi online/offline sebagai stream |
| Font | Inter (via `google_fonts`) | Konsisten dengan versi React |
| Format tanggal | `intl` (locale `id_ID`) | Format tanggal Indonesia |
| Bahasa | Indonesia saja (tanpa i18n) | Sesuai PRD |
| Platform target | Android | Sesuai PRD |
| Backend | Mock dulu; struktur siap API | Sesuai PRD |

## 2. Struktur Folder

```
lib/
├── main.dart
├── app.dart                            # MaterialApp.router + tema
├── core/
│   ├── theme/
│   │   ├── app_colors.dart             # token warna light + dark
│   │   ├── app_theme.dart              # ThemeData Material 3
│   │   └── app_text.dart               # text styles (Inter)
│   ├── navigation/
│   │   └── app_router.dart             # go_router config
│   ├── connectivity/
│   │   ├── connectivity_service.dart   # stream status online/offline
│   │   └── connectivity_provider.dart
│   ├── sync/
│   │   ├── sync_queue.dart             # antrean pending item generik
│   │   ├── sync_service.dart           # retry saat koneksi kembali
│   │   └── sync_provider.dart
│   ├── utils/
│   │   └── formatters.dart             # tanggal, berat, durasi
│   └── widgets/                        # widget bersama
│       ├── neumo_button.dart, neumo_card.dart, neumo_chip.dart,
│       ├── neumo_field.dart, segmented.dart, progress_bar.dart,
│       ├── ring.dart, avatar.dart, empty_state.dart,
│       ├── top_bar.dart, bottom_nav.dart,
│       ├── sync_status.dart, notif_bell.dart
├── models/                             # domain murni (mirror types.ts)
│   ├── child.dart, vaccination.dart, screening.dart, profile.dart,
│   ├── article.dart, app_notification.dart, health_center.dart,
│   └── growth_record.dart, enums.dart
├── data/
│   ├── repositories/                   # interface abstract
│   │   ├── child_repository.dart, screening_repository.dart,
│   │   ├── notification_repository.dart, article_repository.dart,
│   │   ├── health_center_repository.dart, profile_repository.dart
│   ├── local/                          # Drift (offline-first)
│   │   ├── app_database.dart           # AppDatabase (Drift)
│   │   ├── tables.dart                 # children, screenings, screenings_sync,
│   │   │                               #   notifications, meta
│   │   └── local_repositories.dart     # implementasi Drift dari interface repo
│   ├── mock/
│   │   ├── mock_data.dart
│   │   └── mock_repositories.dart
│   └── api/                            # (kosong; ApiRepository nanti: local + api)
├── state/
│   ├── app_providers.dart              # wiring global (tema, repo, sync)
│   └── (nanti bila besar: providers/child_providers.dart, dst.)
└── features/                           # 1 folder per fitur
    ├── splash/
    ├── onboarding/
    ├── auth/                           # login, register, forgot
    ├── home/
    ├── children/                       # daftar + form
    ├── screening/                      # gejala, rekam, proses
    ├── result/
    ├── history/
    ├── education/                      # daftar + artikel
    ├── notifications/
    └── profile/                        # profil, edit, privasi, pengaturan
```

**Pola baku tiap fitur:**

```
features/<fitur>/
├── screens/        # halaman-halaman
├── widgets/        # widget khusus fitur ini
└── providers/      # state lokal/ephemeral layar (mis. progress rekam)
```

- Provider di `features/<fitur>/providers/` hanya untuk state yang dipakai satu fitur/layar (validasi form, progress rekam).
- Provider global (tema, sesi, wiring repository) di `state/app_providers.dart`.

## 3. Tema & Design System

Token warna (dari `src/index.css`):

| Token | Light | Dark |
|---|---|---|
| bg | `#F7FAFC` | `#070C18` |
| surface | `#FFFFFF` | `#10182B` |
| surface-2 | `#F1F5F9` | `#182238` |
| ink (teks) | `#0B1B33` | `#F1F5F9` |
| muted | `#64748B` | `#94A3B8` |
| faint | `#94A3B8` | `#64748B` |
| border (line) | `#E2E8F0` | `#1F2B42` |
| primary | `#1D7AFC` (deep `#1564D4`) | sama |
| secondary | `#3ECF8E` (deep `#2BB377`) | sama |
| accent | `#FF8A00` (deep `#E07700`) | sama |
| danger | `#EF4444` (deep `#DC2626`) | sama |
| warning | `#F59E0B` | success `#10B981` |

- Material 3: `ColorScheme.fromSeed(seedColor: #1D7AFC)` lalu overwrite token di atas.
- Mode gelap: `ThemeMode.system` + toggle; nilai tema disimpan di Drift (tabel `meta`).
- Font: Inter (google_fonts), default text theme.
- Widget bersama di `core/widgets` (mirror `components/ui.tsx` & `layout.tsx`):
  `NeumoButton` (7 varian), `NeumoCard`, `NeumoChip`, `NeumoField`, `Segmented`, `ProgressBar`, `Ring`, `Avatar`, `EmptyState`, `TopBar`, `BottomNav` (glass effect), `SyncStatus`, `NotifBell`.
- Ikon: Material Icons bawaan (mapping dari ikon SVG inline: home, mic, book, user, bell, back, chevron, plus, check, close, search, wave, share, download, shield, calendar, clock, chart, moon, sun, logout, edit, heart, cloud, upload, location, warning, refresh).

## 4. Routing & Navigasi

- `go_router` dengan rute declarative untuk 19 layar.
- 4 tab utama (Beranda / Riwayat / Edukasi / Profil) memakai `StatefulShellRoute` agar bottom nav + state per tab.
- Layar fullscreen tanpa tab: splash, onboarding, login, register, forgot, processing.
- Parameter (childId, articleId, screeningId) → path/query parameter.
- Back behavior: `TopBar` back → `context.pop()`, sesuai UX React sekarang.
- Awal app: splash → (onboarding bila pertama kali) → home.

## 5. State & Data Flow

```
UI (features/) → Provider Riverpod → Interface Repository ──┬→ MockRepository (sekarang)
                                                            └→ ApiRepository (nanti)
                                                                 ├ data/local (Drift)
                                                                 └ data/api (HTTP)
```

- Model domain murni tanpa ketergantungan layer lain.
- Interface repository abstract di `data/repositories/`; implementasi mock di `data/mock/`.
- **Offline-first:**
  - `core/connectivity/` — `ConnectivityService` memakai `connectivity_plus`, expose stream online/offline.
  - `core/sync/` — `SyncQueue<T>` (item generik: type, data, timestamp) + `SyncService` yang memantau stream koneksi; saat offline→online auto-flush + retry item gagal.
  - `data/local/` (Drift) — tabel: `children`, `screenings`, `screenings_sync` (status pending/synced/failed), `notifications`, `meta` (tema).
  - `ApiRepository` (nanti): tulis ke lokal dulu → panggil API → tandai synced.
- Nilai `pendingSync` & banner offline di Home bersumber dari `SyncService`/Drift, bukan variabel simulasi.

## 6. Peta Porting Layar

| React (src/screens) | Flutter (lib/features) |
|---|---|
| auth.tsx (login/register/forgot) | auth/screens |
| SplashScreen, OnboardingScreen | splash/, onboarding/ |
| home.tsx | home/ |
| children.tsx (daftar + form) | children/ |
| screening.tsx (gejala/rekam/proses) | screening/screens (3) |
| result.tsx | result/ |
| history.tsx | history/ |
| education.tsx (daftar + artikel) | education/ |
| notifications.tsx | notifications/ |
| profile.tsx (profil/edit/privasi/settings) | profile/ |

## 7. Komponen Chart → CustomPainter

Mirror `components/charts.tsx` & `ui.tsx` sebagai widget `CustomPaint`:
- `Waveform` (bar animasi, 42 bar, interval 90ms)
- `Spectrogram` (grid heat 14×40)
- `GradCam` (grid 12×12 radial)
- `SHAPChart` (bar horizontal +/−)
- `LineChart` (line + area gradient + titik akhir)
- `BarChart`, `Sparkline`
- `Ring` (progress ring)

Animasi dari `index.css` → `AnimationController`/`TweenAnimationBuilder`:
`fade-up`, `fade-in`, `scale-in`, `pulse-ring`, `wave-bar`, `float`.

## 8. Dependencies

- `flutter_riverpod` (+ `riverpod` / `riverpod_annotation`)
- `go_router`
- `drift` + `drift_flutter` + `sqlite3_flutter_libs`
- `connectivity_plus`
- `google_fonts`
- `intl`
- (future) `record` + `permission_handler` untuk rekaman audio asli

## 9. Error Handling

- Repository mock & lokal: kembalikan `Future`/`Stream`; galat dibungkus hasil `AsyncValue`/`AsyncNotifier` (Riverpod).
- UI menampilkan state: `loading` / `error` (retry) / `data`.
- `SyncService` mencatat item gagal dengan `SyncStatus.failed` untuk retry; tidak membuang data.
- Pesan error dalam Bahasa Indonesia.

## 10. Testing

- Unit test: model, formatters, `SyncQueue` (pending → retry → flush), repository mock.
- Widget test: layar inti (Home, Symptoms, Result).
- Dukungan Drift in-memory (`NativeDatabase.memory()`) untuk test repository lokal.

## 11. Catatan Implementasi

- Mulai dari skeleton (`flutter create`) + dependensi + tema + router kosong.
- Prioritas: (1) fondasi core (theme, router, connectivity, sync, local), (2) fitur inti alur skrining (auth→home→children→screening→result→history), (3) fitur pendukung (education, notifications, profile/settings).
- Rekaman audio tetap simulasi 5 detik; struktur screen memudahkan swap ke `record` nanti.
- **Migrasi penuh (ganti total):** project React (src/, index.html, vite.config.ts, package.json, dist/, dsb.) akan dihapus/diganti dengan project Flutter di repo yang sama. Flutter skeleton dibuat terlebih dahulu, lalu file React dihapus setelah fondasi Flutter siap. Konfigurasi CI/AGENTS yang mengacu toolchain web perlu diperbarui pada tahap tersebut.
