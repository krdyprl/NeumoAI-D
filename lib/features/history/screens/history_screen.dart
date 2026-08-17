import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/tour_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/neumo_card.dart';
import '../../../core/widgets/neumo_chip.dart';
import '../../../core/widgets/neumo_empty_state.dart';
import '../../../core/widgets/neumo_segmented.dart';
import '../../../core/widgets/neumo_showcase.dart';
import '../../../core/widgets/neumo_top_bar.dart';
import '../../../data/mock/mock_data.dart';
import '../../../models/enums.dart';
import '../../../models/screening.dart';
import '../../../state/app_providers.dart';
import '../widgets/bar_chart.dart';
import '../widgets/line_chart.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final GlobalKey _tabKey = GlobalKey();
  final GlobalKey _screeningListKey = GlobalKey();
  final GlobalKey _growthKey = GlobalKey();

  String _tab = 'Skrining';
  String _metric = 'Berat';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tourControllerProvider.notifier).registerSteps('/history', [
        TourStep(_tabKey, 'Riwayat Kesehatan',
            'Pilih tab Skrining untuk hasil pemeriksaan AI, atau tab Pertumbuhan untuk grafik berat dan tinggi badan.'),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenings = ref.watch(screeningsProvider).valueOrNull ?? const [];
    final currentId = ref.watch(currentChildIdProvider).valueOrNull ?? '';
    final childScreenings = screenings.where((s) => s.childId == currentId).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const NeumoTopBar(title: 'Riwayat Kesehatan'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: NeumoShowcase(
              key: _tabKey,
              title: 'Pilih Tampilan',
              description: 'Pilih antara Skrining atau Pertumbuhan untuk melihat data riwayat.',
              child: NeumoSegmented<String>(
                options: const [('Skrining', 'Skrining'), ('Pertumbuhan', 'Pertumbuhan')],
                value: _tab,
                onChanged: (v) => setState(() => _tab = v),
              ),
            ),
          ),
          Expanded(
            child: NeumoShowcase(
              key: _tab == 'Skrining' ? _screeningListKey : _growthKey,
              title: _tab == 'Skrining' ? 'Riwayat Skrining' : 'Grafik Pertumbuhan',
              description: _tab == 'Skrining'
                  ? 'Tap kartu untuk melihat detail hasil skrining AI.'
                  : 'Grafik ini menampilkan perkembangan berat dan tinggi badan anak dari waktu ke waktu.',
              child: _tab == 'Skrining'
                  ? _ScreeningList(screenings: childScreenings)
                  : _GrowthTab(currentId: currentId, metric: _metric, onMetric: (m) => setState(() => _metric = m)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ScreeningList extends StatelessWidget {
  const _ScreeningList({required this.screenings});

  final List<Screening> screenings;

  @override
  Widget build(BuildContext context) {
    if (screenings.isEmpty) {
      return const NeumoEmptyState(
        icon: '📋', title: 'Belum ada skrining', desc: 'Hasil skrining anak akan muncul di sini.');
    }
    return ListView.separated(
      padding: pagePaddingWithBottomNav,
      itemCount: screenings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final s = screenings[i];
        final (tone, label) = switch (s.riskLevel) {
          RiskLevel.high => (NeumoTone.danger, 'Tinggi'),
          RiskLevel.medium => (NeumoTone.accent, 'Sedang'),
          RiskLevel.low => (NeumoTone.secondary, 'Rendah'),
        };
        return NeumoCard(
          onTap: () => context.push('/result?screeningId=${s.id}'),
          interactive: true,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: s.riskLevel == RiskLevel.high
                      ? AppColors.lightDangerSoft
                      : s.riskLevel == RiskLevel.medium
                          ? AppColors.lightAccentSoft
                          : AppColors.lightSecondarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(s.riskLevel == RiskLevel.low ? '😊' : s.riskLevel == RiskLevel.medium ? '😟' : '⚠️',
                    style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('${s.confidence}% · ${s.disease}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    NeumoChip(tone: tone, child: Text('Risiko $label')),
                  ]),
                  const SizedBox(height: 4),
                  Text(formatIdDate(DateTime.parse(s.date)),
                      style: const TextStyle(fontSize: 12, color: AppColors.lightMuted)),
                  const SizedBox(height: 2),
                  Text('${s.symptoms.join(', ')} · ${s.audioDuration} detik',
                      style: const TextStyle(fontSize: 12, color: AppColors.lightFaint)),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }
}

class _GrowthTab extends StatelessWidget {
  const _GrowthTab({required this.currentId, required this.metric, required this.onMetric});

  final String currentId;
  final String metric;
  final ValueChanged<String> onMetric;

  @override
  Widget build(BuildContext context) {
    final records = MockData.growth[currentId] ?? MockData.growth['c1'] ?? const [];
    final values = records.map((r) => metric == 'Berat' ? r.weight : r.height).toList();
    final labels = records.map((r) => r.month).toList();

    return ListView(
      padding: pagePaddingWithBottomNav,
      children: [
        NeumoSegmented<String>(
          options: const [('Berat', 'Berat'), ('Tinggi', 'Tinggi')],
          value: metric,
          onChanged: onMetric,
        ),
        const SizedBox(height: 16),
        NeumoCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Pertumbuhan $metric', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.lightInk)),
              const SizedBox(height: 16),
              LineChart(
                data: values,
                unit: metric == 'Berat' ? 'kg' : 'cm',
                color: metric == 'Berat' ? AppColors.primary : AppColors.secondary,
              ),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        NeumoCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Per Bandingan Bulan', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.lightInk)),
              const SizedBox(height: 16),
              BarChart(
                data: values,
                labels: labels,
                color: metric == 'Berat' ? AppColors.primary : AppColors.secondary,
              ),
            ]),
          ),
        ),
      ],
    );
  }
}