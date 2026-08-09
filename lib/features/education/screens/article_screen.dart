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
    'Tarikan dinding dada yang kuat adalah gejala anak sedang berusaha keras bernapas.',
    'Bibir dan kuku membiru adalah tanda darurat — segera ke IGD.',
    'Batuk selama 2 minggu atau lebih perlu pemeriksaan medis.',
  ];

  static const List<(String, bool)> _redFlags = [
    ('Napas lebih cepat lebih dari 40× per menit (anak 1–5 tahun)', true),
    ('Sulit makan atau minum atau muntah terus-menerus', true),
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
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primary, AppColors.secondary],
                          ),
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
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkSurface
                              : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.lightBorder),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Poin Penting',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.lightInk)),
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
                                Expanded(child: Text(_points[i],
                                    style: const TextStyle(fontSize: 13.5, color: AppColors.lightInk, height: 1.5))),
                              ]),
                            ),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      // Kapan harus ke dokter
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkSurface
                              : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.lightBorder),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Kapan Harus ke Dokter?',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.lightInk)),
                          const SizedBox(height: 12),
                          for (final (text, danger) in _redFlags)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(danger ? '🔴' : '🟡', style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(text,
                                        style: const TextStyle(fontSize: 13.5, color: AppColors.lightInk, height: 1.4))),
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
                    ],
                  ),
          ),
        ]),
      ),
    );
  }
}