import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/tour_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/neumo_chip.dart';
import '../../../core/widgets/neumo_field.dart';
import '../../../core/widgets/neumo_showcase.dart';
import '../../../core/widgets/neumo_top_bar.dart';
import '../../../models/article.dart';
import '../../../state/app_providers.dart';

class EducationScreen extends ConsumerStatefulWidget {
  const EducationScreen({super.key});

  @override
  ConsumerState<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends ConsumerState<EducationScreen> {
  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _featuredKey = GlobalKey();
  final GlobalKey _categoryKey = GlobalKey();
  final GlobalKey _articlesKey = GlobalKey();

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tourControllerProvider.notifier).registerSteps('/education', [
        TourStep(_searchKey, 'Edukasi Napas',
            'Cari artikel tentang pneumonia, gizi, atau kesehatan anak. Baca rekomendasi penting untuk memahami kondisi si kecil.'),
      ]);
    });
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
    final all = ref.watch(articlesProvider).valueOrNull ?? const <Article>[];
    final articles = _applyFilter(all);
    final featured = all.where((a) => a.id == 'a1').firstOrNull ?? all.firstOrNull;
    final darurat = all.where((a) => a.tag == 'Darurat').firstOrNull ?? all.lastOrNull;

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          NeumoTopBar(
            title: 'Edukasi Napas',
            right: GestureDetector(
              onTap: () => context.push('/article?articleId=${darurat?.id}'),
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
              padding: pagePaddingWithBottomNav,
              children: [
                NeumoShowcase(
                  key: _searchKey,
                  title: 'Cari Artikel',
                  description: 'Ketik kata kunci untuk mencari artikel tentang pneumonia, gizi, atau kesehatan anak.',
                  child: NeumoField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v),
                    placeholder: 'Cari artikel, kata, atau topik…',
                    icon: Icons.search,
                  ),
                ),
                const SizedBox(height: 16),
                // Featured
                NeumoShowcase(
                  key: _featuredKey,
                  title: 'Artikel Unggulan',
                  description: 'Artikel rekomendasi penting yang harus dibaca untuk memahami kondisi anak.',
                  child: GestureDetector(
                    onTap: () => context.push('/article?articleId=${featured?.id}'),
                    child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.primaryDeep],
                      ),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      NeumoChip(tone: NeumoTone.warning, child: const Text('Artikel Unggulan')),
                      const SizedBox(height: 18),
                      Text(featured?.title ?? '',
                          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white, height: 1.3)),
                      const SizedBox(height: 6),
                      Text('${featured?.readTime ?? ''} baca · ${featured?.category ?? ''}',
                          style: const TextStyle(fontSize: 12.5, color: Colors.white70)),
                    ]),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Category chips
                NeumoShowcase(
                  key: _categoryKey,
                  title: 'Filter Kategori',
                  description: 'Pilih kategori seperti Pneumonia, Deteksi, Gizi, atau Darurat untuk menyaring artikel.',
                  child: SingleChildScrollView(
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
                ),
                const SizedBox(height: 20),
                Text('Artikel Terbaru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ink)),
                const SizedBox(height: 12),
                // Article grid
                NeumoShowcase(
                  key: _articlesKey,
                  title: 'Daftar Artikel',
                  description: 'Semua artikel terbaru yang tersedia. Tap untuk membaca selengkapnya.',
                  child: LayoutBuilder(
                    builder: (context, constraints) => Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final a in articles)
                          SizedBox(
                            width: (constraints.maxWidth - 12) / 2,
                            child: _ArticleCard(article: a),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Kenali Penyakit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ink)),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) => Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final (name, emoji, desc, colors) in _diseases)
                        SizedBox(
                          width: (constraints.maxWidth - 12) / 2,
                          child: _DiseaseCard(name: name, emoji: emoji, desc: desc, colors: colors),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Tips Sehat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ink)),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) => Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final (icon, title, desc) in _tips)
                        SizedBox(
                          width: (constraints.maxWidth - 12) / 2,
                          child: _TipCard(icon: icon, title: title, desc: desc),
                        ),
                    ],
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
      onTap: () => context.push('/article?articleId=${article.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.lightBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
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
          const SizedBox(height: 14),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
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
        const SizedBox(height: 12),
        Text(name, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(desc, style: TextStyle(fontSize: 12.5, color: muted, height: 1.4)),
      ]),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.icon, required this.title, required this.desc});

  final String icon;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurface : AppColors.lightSurface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(desc,
              style: TextStyle(fontSize: 12, color: dark ? AppColors.darkMuted : AppColors.lightMuted, height: 1.4)),
        ],
      ),
    );
  }
}