# NeumoAI-D Flutter Migration — Plan 2A: Fitur Pendukung (Education, Notifications, Profile)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the last three stub screens (Education, Notifications, Profile) with real implementations, add the Article detail screen + EditProfile/Privacy/Settings screens, and route them properly — completing the Parents-facing feature set.

**Architecture:** Same feature-first modular structure as Plan 1. Each feature gets `screens/` (+ `widgets/` where needed) under `lib/features/<fitur>`. All data flows through existing Riverpod providers; nothing new is added to `data/` or `state/` in this plan. No changes to models, repositories, or sync.

**Tech Stack:** Flutter 3.29, `flutter_riverpod`, `go_router` 16, existing `core/widgets` (Neumo*), `AppColors`, `package:collection`.

**Scope note:** This plan covers ONLY Plan 2 Part A (supporting feature screens). Local-Drift swap (Part B) and quality polish (Part C) are separate follow-up plans.

## Global Constraints

- All UI copy in **Bahasa Indonesia**. No i18n layer — do NOT port the React "Bahasa"/language feature.
- Search box in Education **must actually filter** articles by title and category (decision made).
- File paths are `lib/features/<fitur>/screens/*.dart` unless stated otherwise.
- **go_router 16 API:** route builders MUST use `state.uri.queryParameters` (never the removed `state.queryParameters`). Navigation to a route with a query param uses a URL string: `context.go('/article?articleId=a1')`.
- Theme keys (`themeKeyProvider`) are `'light' | 'dark' | 'system'` strings; the segmented "Auto" option must use key `'system'`.
- Notifiers: `profileProvider.notifier.updateProfile(...)` (NOT `.update`); `notificationsProvider.notifier.markRead(id)`; `themeKeyProvider.notifier.setThemeKey(key)`.
- Use `withValues(alpha:)`, not `withOpacity`. Use `package:collection` for `firstOrNull` where needed.
- `flutter analyze` zero issues and `flutter test` zero failures at every task boundary.
- Widget tests must set `GoogleFonts.config.allowRuntimeFetching = false;` in `setUp` and (when a screen uses `pendingSyncProvider` or connectivity) override `connectivityServiceProvider` + `syncQueueProvider` with a fake/empty so no plugin channel is hit. Tests that must see a screen's lower sections may set a tall viewport: `tester.view.physicalSize = const Size(800, 2000); tester.view.devicePixelRatio = 1.0; addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);`
- The React legacy screens referenced for faithful porting live in `dump_file/src/screens/` (education.tsx, notifications.tsx, profile.tsx).

---

### Task 1: Education list screen (with working search)

**Files:**
- Replace: `lib/features/education/screens/education_screen.dart` (currently a minimal stub)
- Create: `test/features/education/education_screen_test.dart`

**Interfaces:**
- Consumes: `articlesProvider` (`FutureProvider<List<Article>>`, `.valueOrNull ?? const []`), `NeumoTopBar`, `NeumoField`, `NeumoChip`, `AppColors`, go_router.
- Produces: `EducationScreen` — search that filters articles by title/category, category chips (`Semua/Pneumonia/Deteksi/Gizi/Darurat`), a featured "Artikel Unggulan" card (→ `/article?articleId=a1`), "Darurat" action (→ `/article?articleId=a6`), article grid (→ `/article?articleId=<id>`), "Kenali Penyakit" (4 static cards), "Tips Sehat" (4 static tips).

- [ ] **Step 1: Write the failing test**

`test/features/education/education_screen_test.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neumoi_d/core/connectivity/connectivity_service.dart';
import 'package:neumoi_d/core/sync/sync_queue.dart';
import 'package:neumoi_d/core/theme/app_theme.dart';
import 'package:neumoi_d/features/education/screens/education_screen.dart';
import 'package:neumoi_d/state/app_providers.dart';

class _FakeConnectivity implements ConnectivityService {
  final _controller = StreamController<bool>.broadcast();
  @override
  Stream<bool> get isOnline => _controller.stream;
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('education lists articles and filters by category', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(overrides: [
      connectivityServiceProvider.overrideWithValue(_FakeConnectivity()),
      syncQueueProvider.overrideWithValue(SyncQueue()),
    ]);
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/education',
      routes: [
        GoRoute(path: '/education', builder: (_, __) => const EducationScreen()),
        GoRoute(path: '/article', builder: (_, state) => Scaffold(body: Text('ARTIKEL ${state.uri.queryParameters['articleId']}'))),
        GoRoute(path: '/symptoms', builder: (_, __) => const Scaffold(body: Text('symptoms'))),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router, theme: buildLightTheme()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Edukasi Napas'), findsOneWidget);
    expect(find.text('Kenali 4 Tanda Bahaya Napas Cepat pada Anak'), findsWidgets);

    // Category filter: only Darurat article remains
    await tester.tap(find.text('Darurat'));
    await tester.pumpAndSettle();
    expect(find.text('Nutrisi untuk Memperkuat Daya Tahan Anak'), findsNothing);
    expect(find.text('Pertolongan Pertama saat Anak Sesak Napas'), findsOneWidget);
  });

  testWidgets('search filters by title', (tester) async {
    final container = ProviderContainer(overrides: [
      connectivityServiceProvider.overrideWithValue(_FakeConnectivity()),
      syncQueueProvider.overrideWithValue(SyncQueue()),
    ]);
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/education',
      routes: [
        GoRoute(path: '/education', builder: (_, __) => const EducationScreen()),
        GoRoute(path: '/article', builder: (_, state) => Scaffold(body: Text('ARTIKEL ${state.uri.queryParameters['articleId']}'))),
        GoRoute(path: '/symptoms', builder: (_, __) => const Scaffold(body: Text('symptoms'))),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router, theme: buildLightTheme()),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Napas per Menit');
    await tester.pumpAndSettle();

    expect(find.text('Panduan Menghitung Napas per Menit Sesuai Usia'), findsOneWidget);
    expect(find.text('Pertolongan Pertama saat Anak Sesak Napas'), findsNothing);
  });

  testWidgets('tapping featured card navigates to article', (tester) async {
    final container = ProviderContainer(overrides: [
      connectivityServiceProvider.overrideWithValue(_FakeConnectivity()),
      syncQueueProvider.overrideWithValue(SyncQueue()),
    ]);
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/education',
      routes: [
        GoRoute(path: '/education', builder: (_, __) => const EducationScreen()),
        GoRoute(path: '/article', builder: (_, state) => Scaffold(body: Text('ARTIKEL ${state.uri.queryParameters['articleId']}'))),
        GoRoute(path: '/symptoms', builder: (_, __) => const Scaffold(body: Text('symptoms'))),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router, theme: buildLightTheme()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Artikel Unggulan').first);
    await tester.pumpAndSettle();
    expect(find.text('ARTIKEL a1'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/education/education_screen_test.dart`
Expected: FAIL (screen is still the stub; finds no "Edukasi Napas").

- [ ] **Step 3: Implement the education screen**

`lib/features/education/screens/education_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neumo_chip.dart';
import '../../../core/widgets/neumo_field.dart';
import '../../../core/widgets/neumo_top_bar.dart';
import '../../../models/article.dart';
import '../../../state/app_providers.dart';

class EducationScreen extends ConsumerStatefulWidget {
  const EducationScreen({super.key});

  @override
  ConsumerState<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends ConsumerState<EducationScreen> {
  static const List<String> _cats = ['Semua', 'Pneumonia', 'Deteksi', 'Gizi', 'Darurat'];

  static const List<(String, String, String, List<Color>)> _diseases = [
    ('Apa itu Pneumonia?', '🫁', 'Infeksi paru-paru yang menjadi penyebab utama kematian anak balita. Waspadai sejak dini.', [Color(0xFFEF4444), Color(0xFFF97316)]),
    ('Gejala Pneumonia', '🌡️', 'Batuk, napas cepat, tarikan dinding dada, demam, dan hilang nafsu makan.', [AppColors.primary, AppColors.secondary]),
    ('Pencegahan', '💉', 'Vaksinasi lengkap, ASI eksklusif, gizi baik, dan jauhkan dari asap rokok.', [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
    ('Kapan ke Dokter', '🚨', 'Napas cepat, bibir membiru, atau sulit minum — segera ke fasilitas kesehatan.', [AppColors.secondary, Color(0xFFA7F3D0)]),
  ];

  static const List<(String, String, String)> _tips = [
    ('💧', 'Cukupi cairan', 'Berikan ASI/cairan hangat lebih sering saat batuk.'),
    ('🛌', 'Istirahat cukup', 'Posisikan kepala sedikit lebih tinggi saat tidur.'),
    ('🧴', 'Hindari iritan', 'Jauhkan anak dari asap rokok dan polusi.'),
    ('🌡️', 'Pantau suhu', 'Cek suhu tubuh rutin dan catat perkembangan.'),
  ];

  String _cat = 'Semua';
  String _query = '';
  late final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Article> _applyFilter(List<Article> all) {
    var list = _cat == 'Semua' ? List.of(all) : all.where((a) => a.category == _cat).toList();
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((a) => a.title.toLowerCase().contains(q) || a.category.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? AppColors.darkInk : AppColors.lightInk;
    final articles = _applyFilter(ref.watch(articlesProvider).valueOrNull ?? const <Article>[]);

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          NeumoTopBar(
            title: 'Edukasi Napas',
            right: GestureDetector(
              onTap: () => context.go('/article?articleId=a6'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: dark ? AppColors.darkDangerSoft : AppColors.lightDangerSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🆘 Darurat',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.dangerDeep)),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              children: [
                NeumoField(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v),
                  placeholder: 'Cari artikel, penyakit, atau tips…',
                  icon: Icons.search,
                ),
                const SizedBox(height: 16),
                // Featured
                GestureDetector(
                  onTap: () => context.go('/article?articleId=a1'),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primary, AppColors.primaryDeep]),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: NeumoChip(tone: NeumoTone.warning, child: const Text('Artikel Unggulan')),
                      ),
                      const SizedBox(height: 18),
                      Text('Kenali 4 Tanda Bahaya Napas Cepat pada Anak',
                          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white, height: 1.3)),
                      const SizedBox(height: 6),
                      const Text('4 menit baca · Pneumonia', style: TextStyle(fontSize: 12.5, color: Colors.white70)),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                // Category chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    for (final c in _cats)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _cat = c),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _cat == c ? AppColors.primary : (dark ? AppColors.darkSurface : AppColors.lightSurface),
                              borderRadius: BorderRadius.circular(999),
                              border: _cat == c ? null : Border.all(color: AppColors.lightBorder),
                            ),
                            child: Text(c,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _cat == c ? Colors.white : (dark ? AppColors.darkMuted : AppColors.lightMuted))),
                          ),
                        ),
                      ),
                  ]),
                ),
                const SizedBox(height: 20),
                Text('Artikel Terbaru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ink)),
                const SizedBox(height: 12),
                // Article grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.15,
                  children: [
                    for (final a in articles) _ArticleCard(article: a),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Kenali Penyakit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ink)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    for (final (name, emoji, desc, colors) in _diseases)
                      _DiseaseCard(name: name, emoji: emoji, desc: desc, colors: colors),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Tips Sehat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ink)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    for (final (icon, title, desc) in _tips)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: dark ? AppColors.darkSurface : AppColors.lightSurface2,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.lightBorder),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(icon, style: const TextStyle(fontSize: 24)),
                          const Spacer(),
                          Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.lightMuted, height: 1.4)),
                        ]),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article});

  final Article article;

  NeumoTone _tone() => switch (article.tag) {
        'Penting' => NeumoTone.warning,
        'Panduan' => NeumoTone.secondary,
        'Tips' => NeumoTone.accent,
        _ => NeumoTone.primary,
      };

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final muted = dark ? AppColors.darkMuted : AppColors.lightMuted;
    final ink = dark ? AppColors.darkInk : AppColors.lightInk;
    return GestureDetector(
      onTap: () => context.go('/article?articleId=${article.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.lightBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.lightPrimarySoft, borderRadius: BorderRadius.circular(12)),
              child: const Text('📄', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 8),
            NeumoChip(tone: _tone(), child: Text(article.tag)),
          ]),
          const Spacer(),
          Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ink, height: 1.25)),
          const SizedBox(height: 6),
          Text('⏱️ ${article.readTime} · ${article.category}',
              style: TextStyle(fontSize: 12, color: muted)),
        ]),
      ),
    );
  }
}

class _DiseaseCard extends StatelessWidget {
  const _DiseaseCard({required this.name, required this.emoji, required this.desc, required this.colors});

  final String name;
  final String emoji;
  final String desc;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final muted = dark ? AppColors.darkMuted : AppColors.lightMuted;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 24)),
        ),
        const Spacer(),
        Text(name, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(desc, style: TextStyle(fontSize: 12.5, color: muted, height: 1.4)),
      ]),
    );
  }
}
```

Note: `_DiseaseCard` name is used above (`_DiseaseCard`); the widget class declared as `_DiseaseCard` matching. `_TipsCard` is inlined in the grid instead of a class. The grid `childAspectRatio` on the disease grid matches `_DiseaseCard` content; if overflow warnings appear in tests, increase the ratio to 1.35.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/education/education_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Analyze + full test + commit**

```powershell
flutter analyze
flutter test
git add lib/features/education test/features/education
git commit -m "feat(education): education list with working search and article cards"
```

Expected: analyze clean, all tests pass.

---

### Task 2: Article detail screen

**Files:**
- Create: `lib/features/education/screens/article_screen.dart`
- Create: `test/features/education/article_screen_test.dart`

**Interfaces:**
- Consumes: `articlesProvider`, `NeumoTopBar`, `NeumoChip`, `NeumoButton`, go_router.
- Produces: `ArticleScreen({String? articleId})` — gradient header (emoji 🫁, category chip warning tone, title, read time), "Poin Penting" (static numbered list), "Kapan Harus ke Dokter?" (static list with 🔴/🟡), CTA button "Sudah punya gejala? Cek sekarang" → `/symptoms`. Falls back to the first article when `articleId` doesn't match; shows an empty state when no articles exist.

- [ ] **Step 1: Write the failing test**

`test/features/education/article_screen_test.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neumoi_d/core/connectivity/connectivity_service.dart';
import 'package:neumoi_d/core/sync/sync_queue.dart';
import 'package:neumoi_d/core/theme/app_theme.dart';
import 'package:neumoi_d/features/education/screens/article_screen.dart';
import 'package:neumoi_d/state/app_providers.dart';

class _FakeConnectivity implements ConnectivityService {
  final _controller = StreamController<bool>.broadcast();
  @override
  Stream<bool> get isOnline => _controller.stream;
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('article screen shows article and navigates to symptoms', (tester) async {
    final container = ProviderContainer(overrides: [
      connectivityServiceProvider.overrideWithValue(_FakeConnectivity()),
      syncQueueProvider.overrideWithValue(SyncQueue()),
    ]);
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/article?articleId=a3',
      routes: [
        GoRoute(path: '/article', builder: (_, state) => ArticleScreen(articleId: state.uri.queryParameters['articleId'])),
        GoRoute(path: '/symptoms', builder: (_, __) => const Scaffold(body: Text('symptoms'))),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router, theme: buildLightTheme()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Panduan Menghitung Napas per Menit Sesuai Usia'), findsOneWidget);
    expect(find.text('Poin Penting'), findsOneWidget);
    expect(find.text('Kapan Harus ke Dokter?'), findsWidgets);

    await tester.tap(find.text('Sudah punya gejala? Cek sekarang'));
    await tester.pumpAndSettle();
    expect(find.text('symptoms'), findsOneWidget);
  });

  testWidgets('article screen falls back to first article', (tester) async {
    final container = ProviderContainer(overrides: [
      connectivityServiceProvider.overrideWithValue(_FakeConnectivity()),
      syncQueueProvider.overrideWithValue(SyncQueue()),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildLightTheme(), home: const ArticleScreen(articleId: 'does-not-exist')),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Kenali 4 Tanda Bahaya Napas Cepat pada Anak'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/education/article_screen_test.dart`
Expected: FAIL (file does not exist).

- [ ] **Step 3: Implement the article screen**

`lib/features/education/screens/article_screen.dart`:

```dart
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neumo_button.dart';
import '../../../core/widgets/neumo_chip.dart';
import '../../../core/widgets/neumo_top_bar.dart';
import '../../../models/article.dart';
import '../../../state/app_providers.dart';

class ArticleScreen extends ConsumerWidget {
  const ArticleScreen({super.key, this.articleId});

  final String? articleId;

  static const List<String> _points = [
    'Perhatikan pola napas anak: hitung napas per menit saat anak tenang.',
    'Tarikan dinding dada yang kuat menandakan anak berusaha keras bernapas.',
    'Bibir dan kuku membiru adalah tanda darurat — segera ke IGD.',
    'Batuk selama 2 minggu atau lebih perlu pemeriksaan medis.',
  ];

  static const List<(String, bool)> _redFlags = [
    ('Napas lebih cepat dari 40×/menit (anak 1–5 tahun)', true),
    ('Sulit makan/minum atau muntah terus-menerus', true),
    ('Demam tinggi lebih dari 3 hari', false),
    ('Batuk mengganggu tidur lebih dari 1 minggu', false),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articles = ref.watch(articlesProvider).valueOrNull ?? const <Article>[];
    final article = articles.where((a) => a.id == articleId).firstOrNull ?? articles.firstOrNull;

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const NeumoTopBar(title: 'Artikel'),
          Expanded(
            child: article == null
                ? const Center(child: Text('Artikel tidak ditemukan', style: TextStyle(color: AppColors.lightMuted)))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                    children: [
                      // Header banner
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primary, AppColors.secondary]),
                        ),
                        child: Column(children: [
                          const Text('🫁', style: TextStyle(fontSize: 56)),
                          const SizedBox(height: 16),
                          NeumoChip(tone: NeumoTone.warning, child: Text(article.category)),
                          const SizedBox(height: 16),
                          Text(article.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, height: 1.3)),
                          const SizedBox(height: 6),
                          Text('⏱️ ${article.readTime} baca · NeumoAI-D Edukasi',
                              style: const TextStyle(fontSize: 12.5, color: Colors.white70)),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      // Poin Penting
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.lightBorder),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Poin Penting', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.lightInk)),
                          const SizedBox(height: 14),
                          for (var i = 0; i < _points.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(color: AppColors.lightPrimarySoft, borderRadius: BorderRadius.circular(8)),
                                  child: Text('${i + 1}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(_points[i], style: const TextStyle(fontSize: 13.5, color: AppColors.lightInk, height: 1.5))),
                              ]),
                            ),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      // Kapan harus ke dokter
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.lightBorder),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Kapan Harus ke Dokter?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.lightInk)),
                          const SizedBox(height: 12),
                          for (final (text, danger) in _redFlags)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(danger ? '🔴' : '🟡', style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5, color: AppColors.lightInk, height: 1.4))),
                              ]),
                            ),
                        ]),
                      ),
                      const SizedBox(height: 20),
                      NeumoButton(
                        expand: true,
                        size: NeumoSize.lg,
                        label: 'Sudah punya gejala? Cek sekarang',
                        onPressed: () => context.go('/symptoms'),
                      ),
                    ]),
          ),
        ]),
      ),
    );
  }
}
```

> The CTA is a single-line labelled button (the React original had a subtitle line). This is a deliberate, minor faithful-diff simplification; keep the button label exactly as written above.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/education/article_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Analyze + full test + commit**

```powershell
flutter analyze
flutter test
git add lib/features/education/screens/article_screen.dart test/features/education/article_screen_test.dart
git commit -m "feat(education): article detail screen"
```

Expected: analyze clean, all tests pass.

---

### Task 3: Notifications screen

**Files:**
- Replace: `lib/features/notifications/screens/notifications_screen.dart` (currently a minimal stub)
- Create: `test/features/notifications/notifications_screen_test.dart`

**Interfaces:**
- Consumes: `notificationsProvider` (`AsyncNotifierProvider<List<AppNotification>>`; `.valueOrNull ?? const []`, `notifier.markRead(id)`), `NeumoTopBar`, go_router.
- Produces: `NotificationsScreen` — filter chips (`Semua/AI/Medis/Vaksin/Pengingat`), per-type emoji + soft background (`ai 🤖 secondary-soft`, `medical 🩺 danger-soft`, `vaccination 💉 primary-soft`, `reminder ⏰ accent-soft`), unread pill in the top bar ("n baru"), per-item read/unread styling (bold title + blue dot when unread), tap → `markRead(id)` and, for `ai`/`medical` types, `context.go('/result')`.

- [ ] **Step 1: Write the failing test**

`test/features/notifications/notifications_screen_test.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neumoi_d/core/connectivity/connectivity_service.dart';
import 'package:neumoi_d/core/sync/sync_queue.dart';
import 'package:neumoi_d/core/theme/app_theme.dart';
import 'package:neumoi_d/features/notifications/screens/notifications_screen.dart';
import 'package:neumoi_d/state/app_providers.dart';

class _FakeConnectivity implements ConnectivityService {
  final _controller = StreamController<bool>.broadcast();
  @override
  Stream<bool> get isOnline => _controller.stream;
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('notifications lists, filters, and marks read', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(overrides: [
      connectivityServiceProvider.overrideWithValue(_FakeConnectivity()),
      syncQueueProvider.overrideWithValue(SyncQueue()),
    ]);
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/notifications',
      routes: [
        GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
        GoRoute(path: '/result', builder: (_, __) => const Scaffold(body: Text('result-page'))),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router, theme: buildLightTheme()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Notifikasi'), findsOneWidget);
    expect(find.text('Hasil skrining Arya tersedia'), findsOneWidget);

    // Filter: only medical type
    await tester.tap(find.text('Medis'));
    await tester.pumpAndSettle();
    expect(find.text('Hasil skrining Arya tersedia'), findsNothing);
    expect(find.text('Saran dari dr. Rina'), findsOneWidget);

    // Tap an AI notification -> navigate to result + mark read
    await tester.tap(find.text('Semua'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hasil skrining Arya tersedia'));
    await tester.pumpAndSettle();
    expect(find.text('result-page'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/notifications/notifications_screen_test.dart`
Expected: FAIL (screen is still the stub).

- [ ] **Step 3: Implement the notifications screen**

`lib/features/notifications/screens/notifications_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neumo_top_bar.dart';
import '../../../models/app_notification.dart';
import '../../../models/enums.dart';
import '../../../state/app_providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  static const List<(String, String)> _filters = [
    ('all', 'Semua'),
    ('ai', 'AI'),
    ('medical', 'Medis'),
    ('vaccination', 'Vaksin'),
    ('reminder', 'Pengingat'),
  ];

  String _filter = 'all';

  Color _softFor(BuildContext context, NotifType type) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch (type) {
      NotifType.vaccination => dark ? AppColors.darkPrimarySoft : AppColors.lightPrimarySoft,
      NotifType.reminder => dark ? AppColors.darkAccentSoft : AppColors.lightAccentSoft,
      NotifType.ai => dark ? AppColors.darkSecondarySoft : AppColors.lightSecondarySoft,
      NotifType.medical => dark ? AppColors.darkDangerSoft : AppColors.lightDangerSoft,
    };
  }

  String _emojiFor(NotifType type) => switch (type) {
        NotifType.vaccination => '💉',
        NotifType.reminder => '⏰',
        NotifType.ai => '🤖',
        NotifType.medical => '🩺',
      };

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? AppColors.darkInk : AppColors.lightInk;
    final muted = dark ? AppColors.darkMuted : AppColors.lightMuted;
    final faint = dark ? AppColors.darkFaint : AppColors.lightFaint;
    final notifications = ref.watch(notificationsProvider).valueOrNull ?? const <AppNotification>[];
    final unread = notifications.where((n) => !n.read).length;
    final list = _filter == 'all'
        ? notifications
        : notifications.where((n) => n.type.name == _filter).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          NeumoTopBar(
            title: 'Notifikasi',
            right: unread > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.lightPrimarySoft, borderRadius: BorderRadius.circular(999)),
                    child: Text('$unread baru',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  )
                : null,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    for (final (key, label) in _filters)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _filter = key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _filter == key ? AppColors.primary : (dark ? AppColors.darkSurface : AppColors.lightSurface),
                              borderRadius: BorderRadius.circular(999),
                              border: _filter == key ? null : Border.all(color: AppColors.lightBorder),
                            ),
                            child: Text(label,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _filter == key ? Colors.white : muted)),
                          ),
                        ),
                      ),
                  ]),
                ),
                const SizedBox(height: 16),
                if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: Text('Belum ada notifikasi', style: TextStyle(color: AppColors.lightMuted))),
                  ),
                for (final n in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () {
                        ref.read(notificationsProvider.notifier).markRead(n.id);
                        if (n.type == NotifType.ai || n.type == NotifType.medical) {
                          context.go('/result');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: dark ? AppColors.darkSurface : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: n.read ? AppColors.lightBorder : AppColors.primary.withValues(alpha: 0.25)),
                        ),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: _softFor(context, n.type), borderRadius: BorderRadius.circular(16)),
                            child: Text(_emojiFor(n.type), style: const TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Expanded(
                                  child: Text(n.title,
                                      style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: n.read ? FontWeight.w600 : FontWeight.bold,
                                          color: n.read ? muted : ink)),
                                ),
                                if (!n.read)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 6, top: 5),
                                    child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                                  ),
                              ]),
                              const SizedBox(height: 4),
                              Text(n.body,
                                  style: TextStyle(fontSize: 13, color: n.read ? faint : muted, height: 1.4)),
                              const SizedBox(height: 6),
                              Text(n.time, style: TextStyle(fontSize: 11, color: faint)),
                            ]),
                          ),
                        ]),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
```

Note: the migration of the app into the new folder uses `NotifType` from `lib/models/enums.dart`; filter keys use `n.type.name` which for our enums is `vaccination/reminder/ai/medical` — these match the filter keys declared above (`ai`, `medical`, `vaccination`, `reminder`).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/notifications/notifications_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Analyze + full test + commit**

```powershell
flutter analyze
flutter test
git add lib/features/notifications test/features/notifications
git commit -m "feat(notifications): notifications list with filters and mark-read"
```

Expected: analyze clean, all tests pass.

---

### Task 4: Profile screens (Profile, EditProfile, Privacy, Settings)

**Files:**
- Replace: `lib/features/profile/screens/profile_screen.dart` (currently a minimal stub)
- Create: `lib/features/profile/screens/edit_profile_screen.dart`
- Create: `lib/features/profile/screens/privacy_screen.dart`
- Create: `lib/features/profile/screens/settings_screen.dart`
- Create: `test/features/profile/profile_screen_test.dart`
- Create: `test/features/profile/edit_profile_screen_test.dart`
- Create: `test/features/profile/settings_screen_test.dart`

**Interfaces:**
- Consumes: `profileProvider` (`notifier.updateProfile(Profile)`), `childrenProvider`, `notificationsProvider`, `pendingSyncProvider`, `themeKeyProvider` (`notifier.setThemeKey('light'|'dark'|'system')`), `NeumoTopBar`, `NeumoCard`, `NeumoButton`, `NeumoField`, `NeumoSegmented`, go_router.
- Produces:
  - `ProfileScreen` — gradient profile card (emoji, name, email, sync pill), menu rows (Kelola Anak → `/children`, Notifikasi → `/notifications`, Privasi & Keamanan → `/privacy`, Pengaturan → `/settings`), "Tampilan" segmented (Terang/Gelap/Auto → `light`/`dark`/`system`), "Keluar" button → `/login`, version footer.
  - `EditProfileScreen` — avatar box (emoji) + "Ubah Foto" (snackbar), fields NAMA/EMAIL/NOMOR HP (prefilled), "Simpan Perubahan" → `updateProfile(...)` then `context.pop()`.
  - `PrivacyScreen` — info card, 3 `Switch` rows (shareData/analytics/reminders), "Data Pribadi" actions (Unduh data saya → snackbar, Hapus akun dan data → confirm dialog → snackbar).
  - `SettingsScreen` — "Tampilan" segmented (Terang/Gelap → `light`/`dark`), "Tentang" card. No language section (Indonesia only).

- [ ] **Step 1: Write the failing tests**

`test/features/profile/profile_screen_test.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neumoi_d/core/connectivity/connectivity_service.dart';
import 'package:neumoi_d/core/sync/sync_queue.dart';
import 'package:neumoi_d/core/theme/app_theme.dart';
import 'package:neumoi_d/features/profile/screens/profile_screen.dart';
import 'package:neumoi_d/state/app_providers.dart';

class _FakeConnectivity implements ConnectivityService {
  final _controller = StreamController<bool>.broadcast();
  @override
  Stream<bool> get isOnline => _controller.stream;
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('profile shows user info, menu, and updates theme', (tester) async {
    final container = ProviderContainer(overrides: [
      connectivityServiceProvider.overrideWithValue(_FakeConnectivity()),
      syncQueueProvider.overrideWithValue(SyncQueue()),
    ]);
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        GoRoute(path: '/children', builder: (_, __) => const Scaffold(body: Text('children-page'))),
        GoRoute(path: '/notifications', builder: (_, __) => const Scaffold(body: Text('notif-page'))),
        GoRoute(path: '/privacy', builder: (_, __) => const Scaffold(body: Text('privacy-page'))),
        GoRoute(path: '/settings', builder: (_, __) => const Scaffold(body: Text('settings-page'))),
        GoRoute(path: '/login', builder: (_, __) => const Scaffold(body: Text('login-page'))),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router, theme: buildLightTheme()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Ibu Sari'), findsOneWidget);
    expect(find.text('Kelola Anak'), findsOneWidget);
    expect(find.text('Privasi & Keamanan'), findsOneWidget);

    // Theme segment -> dark
    await tester.tap(find.text('🌙 Gelap'));
    await tester.pumpAndSettle();
    expect(await container.read(themeKeyProvider.future), 'dark');

    // Menu navigation
    await tester.tap(find.text('Kelola Anak'));
    await tester.pumpAndSettle();
    expect(find.text('children-page'), findsOneWidget);
  });
}
```

`test/features/profile/edit_profile_screen_test.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neumoi_d/core/connectivity/connectivity_service.dart';
import 'package:neumoi_d/core/sync/sync_queue.dart';
import 'package:neumoi_d/core/theme/app_theme.dart';
import 'package:neumoi_d/features/profile/screens/edit_profile_screen.dart';
import 'package:neumoi_d/state/app_providers.dart';

class _FakeConnectivity implements ConnectivityService {
  final _controller = StreamController<bool>.broadcast();
  @override
  Stream<bool> get isOnline => _controller.stream;
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('edit profile updates the stored profile', (tester) async {
    final container = ProviderContainer(overrides: [
      connectivityServiceProvider.overrideWithValue(_FakeConnectivity()),
      syncQueueProvider.overrideWithValue(SyncQueue()),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildLightTheme(), home: const EditProfileScreen()),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Ibu Ratna');
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();

    final profile = await container.read(profileProvider.future);
    expect(profile.name, 'Ibu Ratna');
  });
}
```

`test/features/profile/settings_screen_test.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neumoi_d/core/connectivity/connectivity_service.dart';
import 'package:neumoi_d/core/sync/sync_queue.dart';
import 'package:neumoi_d/core/theme/app_theme.dart';
import 'package:neumoi_d/features/profile/screens/settings_screen.dart';
import 'package:neumoi_d/state/app_providers.dart';

class _FakeConnectivity implements ConnectivityService {
  final _controller = StreamController<bool>.broadcast();
  @override
  Stream<bool> get isOnline => _controller.stream;
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('settings switches theme to dark', (tester) async {
    final container = ProviderContainer(overrides: [
      connectivityServiceProvider.overrideWithValue(_FakeConnectivity()),
      syncQueueProvider.overrideWithValue(SyncQueue()),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildLightTheme(), home: const SettingsScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Tentang'), findsOneWidget);
    await tester.tap(find.text('🌙 Gelap'));
    await tester.pumpAndSettle();
    expect(await container.read(themeKeyProvider.future), 'dark');
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/profile`
Expected: FAIL (profile screen is a stub; edit/settings files do not exist).

- [ ] **Step 3: Implement the profile screens**

`lib/features/profile/screens/profile_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neumo_button.dart';
import '../../../core/widgets/neumo_segmented.dart';
import '../../../core/widgets/neumo_top_bar.dart';
import '../../../data/mock/mock_data.dart';
import '../../../state/app_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(profileProvider).valueOrNull ?? MockData.profile;
    final children = ref.watch(childrenProvider).valueOrNull ?? const [];
    final pendingSync = ref.watch(pendingSyncProvider).valueOrNull ?? 0;
    final themeKey = ref.watch(themeKeyProvider).valueOrNull ?? 'system';

    final menuRows = <(String, String, String, String)>[
      ('👶', 'Kelola Anak', '${children.length} anak terdaftar', '/children'),
      ('🔔', 'Notifikasi', 'Jadwal vaksin, pengingat, alert AI', '/notifications'),
      ('🔒', 'Privasi & Keamanan', 'Kelola data & izin', '/privacy'),
      ('⚙️', 'Pengaturan', 'Tema & aplikasi', '/settings'),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
          children: [
            // Profile card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primary, Color(0xFF4A8FFC)]),
              ),
              child: Row(children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(22)),
                  child: Text(profile.emoji, style: const TextStyle(fontSize: 34)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(profile.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text(profile.email, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
                      child: Text(pendingSync == 0 ? 'Semua data tersinkronisasi' : 'Sinkronisasi tertunda ($pendingSync)',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ]),
                ),
                GestureDetector(
                  onTap: () => context.go('/edit-profile'),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.edit_outlined, size: 18, color: Colors.white),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            // Menu
            Container(
              decoration: BoxDecoration(
                color: dark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: Column(children: [
                for (final (emoji, label, sub, route) in menuRows)
                  InkWell(
                    onTap: () => context.go(route),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: dark ? AppColors.darkSurface2 : AppColors.lightSurface2, borderRadius: BorderRadius.circular(12)),
                          child: Text(emoji, style: const TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(label, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: dark ? AppColors.darkInk : AppColors.lightInk)),
                            Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.lightMuted)),
                          ]),
                        ),
                        const Icon(Icons.chevron_right, size: 20, color: AppColors.lightFaint),
                      ]),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 20),
            // Tampilan
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: dark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tampilan', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: dark ? AppColors.darkInk : AppColors.lightInk)),
                const SizedBox(height: 12),
                NeumoSegmented<String>(
                  options: const [
                    ('light', '☀️ Terang'),
                    ('dark', '🌙 Gelap'),
                    ('system', '🔄 Auto'),
                  ],
                  value: themeKey,
                  onChanged: (v) => ref.read(themeKeyProvider.notifier).setThemeKey(v),
                ),
                const SizedBox(height: 8),
                const Text('Mode gelap otomatis mengikuti sistem saat memilih "Auto".',
                    style: TextStyle(fontSize: 12, color: AppColors.lightMuted)),
              ]),
            ),
            const SizedBox(height: 24),
            NeumoButton(
              variant: NeumoVariant.danger,
              expand: true,
              size: NeumoSize.lg,
              label: 'Keluar',
              onPressed: () => context.go('/login'),
            ),
            const SizedBox(height: 12),
            const Center(child: Text('NeumoAI-D v1.0.0 · Made with 💙 di Indonesia',
                style: TextStyle(fontSize: 12, color: AppColors.lightFaint))),
          ],
        ),
      ),
    );
  }
}
```

`lib/features/profile/screens/edit_profile_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neumo_button.dart';
import '../../../core/widgets/neumo_field.dart';
import '../../../core/widgets/neumo_top_bar.dart';
import '../../../data/mock/mock_data.dart';
import '../../../models/profile.dart';
import '../../../state/app_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).valueOrNull ?? MockData.profile;
    _name = TextEditingController(text: profile.name);
    _email = TextEditingController(text: profile.email);
    _phone = TextEditingController(text: profile.phone);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final profile = ref.read(profileProvider).valueOrNull ?? MockData.profile;
    final updated = Profile(
      name: _name.text.trim().isEmpty ? profile.name : _name.text.trim(),
      email: _email.text.trim().isEmpty ? profile.email : _email.text.trim(),
      phone: _phone.text.trim().isEmpty ? profile.phone : _phone.text.trim(),
      emoji: profile.emoji,
      role: profile.role,
    );
    await ref.read(profileProvider.notifier).updateProfile(updated);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).valueOrNull ?? MockData.profile;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const NeumoTopBar(title: 'Edit Profil'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              children: [
                Center(
                  child: Column(children: [
                    Container(
                      width: 96,
                      height: 96,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0x291D7AFC), Color(0x293ECF8E)]),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                      ),
                      child: Text(profile.emoji, style: const TextStyle(fontSize: 52)),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fitur ubah foto segera hadir.'))),
                      child: const Text('Ubah Foto', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                NeumoField(label: 'NAMA', controller: _name),
                const SizedBox(height: 16),
                NeumoField(label: 'EMAIL', controller: _email, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                NeumoField(label: 'NOMOR HP', controller: _phone, keyboardType: TextInputType.phone),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: NeumoButton(expand: true, size: NeumoSize.lg, label: 'Simpan Perubahan', onPressed: _save),
          ),
        ]),
      ),
    );
  }
}
```

`lib/features/profile/screens/privacy_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neumo_top_bar.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _shareData = true;
  bool _analytics = false;
  bool _reminders = true;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? AppColors.darkInk : AppColors.lightInk;

    Widget row(String icon, String title, String desc, bool value, ValueChanged<bool> onChanged) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: dark ? AppColors.darkSurface2 : AppColors.lightSurface2, borderRadius: BorderRadius.circular(12)),
            child: Text(icon, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ink)),
              Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.lightMuted, height: 1.4)),
            ]),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ]),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: dark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('🛡️', style: TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Data kesehatan Anda dan anak terenkripsi end-to-end. Hasil skrining hanya dapat diakses oleh Anda dan tenaga medis yang Anda pilih.',
                    style: TextStyle(fontSize: 13, color: AppColors.lightMuted, height: 1.5),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: dark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: Column(children: [
                row('🩺', 'Bagikan hasil dengan dokter', 'Izinkan akses hasil skrining untuk konsultasi medis', _shareData, (v) => setState(() => _shareData = v)),
                row('📊', 'Analitik penggunaan', 'Bantu kami meningkatkan akurasi AI secara anonim', _analytics, (v) => setState(() => _analytics = v)),
                row('🔔', 'Pengingat kesehatan', 'Vaksinasi, skrining rutin, dan saran kesehatan', _reminders, (v) => setState(() => _reminders = v)),
              ]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: dark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Data Pribadi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ink)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Permintaan unduh data dikirim.'))),
                  child: const Align(alignment: Alignment.centerLeft, child: Text('Unduh data saya',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.primary))),
                ),
                TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Hapus akun dan data?'),
                      content: const Text('Seluruh data anak dan riwayat skrining akan dihapus permanen.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
                        TextButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Akun tidak dapat dihapus dalam mode demo.')));
                          },
                          child: const Text('Hapus', style: TextStyle(color: AppColors.danger)),
                        ),
                      ],
                    ),
                  ),
                  child: const Align(alignment: Alignment.centerLeft, child: Text('Hapus akun dan data',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.danger))),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
```

`lib/features/profile/screens/settings_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neumo_segmented.dart';
import '../../../core/widgets/neumo_top_bar.dart';
import '../../../state/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? AppColors.darkInk : AppColors.lightInk;
    final themeKey = ref.watch(themeKeyProvider).valueOrNull ?? 'system';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: dark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tampilan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ink)),
                const SizedBox(height: 12),
                NeumoSegmented<String>(
                  options: const [
                    ('light', '☀️ Terang'),
                    ('dark', '🌙 Gelap'),
                  ],
                  value: themeKey == 'dark' ? 'dark' : 'light',
                  onChanged: (v) => ref.read(themeKeyProvider.notifier).setThemeKey(v),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: dark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tentang', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ink)),
                const SizedBox(height: 8),
                const Text(
                  'NeumoAI-D (Napas Anak Indonesia) adalah platform skrining dini penyakit pernapasan pada anak menggunakan AI analisis suara batuk.',
                  style: TextStyle(fontSize: 13, color: AppColors.lightMuted, height: 1.5),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/profile`
Expected: PASS.

> If `NeumoSegmented` renders its labels with the sun/moon/auto emoji text and the test `find.text('🌙 Gelap')` needs to match exactly, keep the option labels exactly as `('dark', '🌙 Gelap')` — the finder matches the full string.

- [ ] **Step 5: Analyze + full test + commit**

```powershell
flutter analyze
flutter test
git add lib/features/profile test/features/profile
git commit -m "feat(profile): profile, edit profile, privacy, and settings screens"
```

Expected: analyze clean, all tests pass.

---

### Task 5: Router update + full verification

**Files:**
- Modify: `lib/core/navigation/app_router.dart` (replace placeholder routes with the real screens)

**Interfaces:**
- Consumes: `ArticleScreen`, `EditProfileScreen`, `PrivacyScreen`, `SettingsScreen` (Tasks 2 & 4).
- Produces: final route map where:
  - `/article` → `ArticleScreen(articleId: state.uri.queryParameters['articleId'])`
  - `/edit-profile` → `EditProfileScreen()`
  - `/privacy` → `PrivacyScreen()`
  - `/settings` → `SettingsScreen()`
  - `/education` shell branch stays `EducationScreen`
  - `/profile` shell branch stays `ProfileScreen`

- [ ] **Step 1: Update the router**

Edit `lib/core/navigation/app_router.dart`:

- Replace the imports block (remove nothing; keep all existing) and update the four routes. Concretely replace these lines:

```dart
      GoRoute(path: '/article', builder: (_, __) => const EducationScreen()),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/edit-profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/privacy', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const ProfileScreen()),
```

with:

```dart
      GoRoute(
        path: '/article',
        builder: (_, state) => ArticleScreen(
          articleId: state.uri.queryParameters['articleId'],
        ),
      ),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/edit-profile', builder: (_, __) => const EditProfileScreen()),
      GoRoute(path: '/privacy', builder: (_, __) => const PrivacyScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
```

Add the new imports at the top of the file (alphabetical among existing feature imports):

```dart
import '../../features/education/screens/article_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/privacy_screen.dart';
import '../../features/profile/screens/settings_screen.dart';
```

- [ ] **Step 2: Run analyze and the full test suite**

```powershell
flutter analyze
flutter test
```

Expected: analyze "No issues found!"; all tests pass (the existing `app_test.dart` still boots splash → onboarding → home; the new screens are exercised by their own tests).

- [ ] **Step 3: Run a debug APK build to confirm Android compiles**

```powershell
flutter build apk --debug
```

Expected: `Built build/app/outputs/flutter-apk/app-debug.apk` (this verifies the full Android toolchain still works after adding the screens).

- [ ] **Step 4: Commit**

```powershell
git add lib/core/navigation/app_router.dart
git commit -m "feat(router): route article, edit-profile, privacy, and settings to real screens"
```

---

## Plan 2A Completion

After Task 5, all Parents-facing feature screens are implemented: auth, home, children, screening (symptoms/record/processing), result, history, education (list + article), notifications, profile (profile/edit/privacy/settings). The app is a complete Android MVP with offline-first foundation (Plan 1) and the full feature set (Plan 2A). Next follow-ups (separate plans): Part B — swap Mock repositories for Drift-backed local repositories so domain data persists; Part C — quality polish (dark-mode button colors, result empty-state, CI workflow); then the real API/AI layer.
