import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/neumo_button.dart';
import '../../../core/widgets/neumo_card.dart';
import '../../../core/widgets/neumo_chip.dart';
import '../../../core/widgets/neumo_ring.dart';
import '../../../core/widgets/neumo_top_bar.dart';
import '../../../models/enums.dart';
import '../../../state/app_providers.dart';
import '../widgets/grad_cam.dart';
import '../widgets/shap_chart.dart';
import '../widgets/spectrogram.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key, this.screeningId});

  final String? screeningId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenings = ref.watch(screeningsProvider).valueOrNull ?? const [];
    final children = ref.watch(childrenProvider).valueOrNull ?? const [];
    final currentId = ref.watch(currentChildIdProvider).valueOrNull ?? '';

    final byParam = screenings.where((s) => s.id == screeningId).firstOrNull;
    final forChild = screenings.where((s) => s.childId == currentId).firstOrNull;
    final screening = byParam ?? forChild ?? screenings.firstOrNull;
    final child = children.where((c) => c.id == (screening?.childId ?? currentId)).firstOrNull;

    final risk = screening?.riskLevel ?? RiskLevel.low;
    final (riskColor, riskLabel, advice) = switch (risk) {
      RiskLevel.low => (AppColors.secondary, 'Rendah', 'Pantau gejala dan lakukan skrining ulang bila kondisi berubah.'),
      RiskLevel.medium => (AppColors.accent, 'Sedang', 'Pantau gejala lebih dekat dan segera konsultasikan jika memburuk.'),
      RiskLevel.high => (AppColors.danger, 'Tinggi', 'Segera bawa anak ke fasilitas kesehatan terdekat untuk pemeriksaan lanjutan. Jangan beri obat batuk sebelum diperiksa dokter.'),
    };

    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? AppColors.darkInk : AppColors.lightInk;

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const NeumoTopBar(title: 'Hasil Skrining'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                NeumoCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(child?.name ?? 'Anak', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ink)),
                          NeumoChip(
                            tone: risk == RiskLevel.high
                                ? NeumoTone.danger
                                : risk == RiskLevel.medium
                                    ? NeumoTone.accent
                                    : NeumoTone.secondary,
                            child: Text('Risiko $riskLabel'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Skrining ${formatIdDate(DateTime.tryParse(screening?.date ?? '') ?? DateTime.now())}',
                          style: const TextStyle(fontSize: 12, color: AppColors.lightMuted)),
                      const SizedBox(height: 20),
                      Row(children: [
                        NeumoRing(
                          value: (screening?.confidence ?? 0).toDouble(),
                          color: riskColor,
                          label: Text('${screening?.confidence ?? 0}%'),
                          sublabel: 'keyakinan AI',
                          size: 104,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(screening == null
                                    ? 'Belum ada skrining'
                                    : risk == RiskLevel.low
                                        ? 'Tidak terindikasi ${screening.disease}'
                                        : 'Terindikasi ${screening.disease}',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ink)),
                            const SizedBox(height: 6),
                            Text(advice, style: const TextStyle(fontSize: 13, color: AppColors.lightMuted, height: 1.5)),
                          ]),
                        ),
                      ]),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),
                _Section(title: 'Spektrogram',
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Visualisasi frekuensi suara batuk yang dianalisis AI.',
                          style: TextStyle(fontSize: 13, color: AppColors.lightMuted)),
                      const SizedBox(height: 12),
                      ClipRRect(borderRadius: BorderRadius.circular(16), child: Container(color: AppColors.lightBg, padding: const EdgeInsets.all(4), child: const Spectrogram())),
                    ])),
                const SizedBox(height: 16),
                _Section(title: 'Grad-CAM',
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Peta aktivasi model AI pada suara batuk.',
                          style: TextStyle(fontSize: 13, color: AppColors.lightMuted)),
                      const SizedBox(height: 12),
                      ClipRRect(borderRadius: BorderRadius.circular(16), child: Container(color: AppColors.lightBg, padding: const EdgeInsets.all(4), child: const GradCam())),
                    ])),
                const SizedBox(height: 16),
                _Section(title: 'Faktor yang Memengaruhi',
                    child: SHAPChart(data: const [
                      ('Frekuensi napas cepat', 0.68),
                      ('Suara mengi', 0.44),
                      ('Durasi batuk', 0.21),
                      ('Demam tinggi', -0.12),
                    ])),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: risk == RiskLevel.high ? AppColors.lightDangerSoft : AppColors.lightAccentSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.medical_information_outlined, color: AppColors.danger),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Skrining AI bukan pengganti diagnosis medis profesional. '
                          'Konsultasikan hasil dengan dokter atau tenaga kesehatan.',
                          style: TextStyle(fontSize: 12.5, color: risk == RiskLevel.high ? AppColors.dangerDeep : AppColors.accentDeep, height: 1.5)),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Expanded(
                child: NeumoButton(
                  variant: NeumoVariant.outline,
                  label: 'Riwayat',
                  onPressed: () => context.go('/history'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NeumoButton(
                  variant: NeumoVariant.primary,
                  label: 'Skrining Ulang',
                  onPressed: () => context.go('/symptoms'),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.lightInk)),
      const SizedBox(height: 10),
      child,
    ]);
  }
}
