import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/tour_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/neumo_button.dart';
import '../../../core/widgets/neumo_card.dart';
import '../../../core/widgets/neumo_segmented.dart';
import '../../../core/widgets/neumo_showcase.dart';
import '../../../core/widgets/neumo_top_bar.dart';
import '../../../models/enums.dart';
import '../../../state/app_providers.dart';
import '../data/symptoms.dart';

class SymptomsScreen extends ConsumerStatefulWidget {
  const SymptomsScreen({super.key});

  @override
  ConsumerState<SymptomsScreen> createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends ConsumerState<SymptomsScreen> {
  final GlobalKey _symptomKey = GlobalKey();
  final GlobalKey _durationKey = GlobalKey();
  final GlobalKey _breathingKey = GlobalKey();
  final GlobalKey _nextKey = GlobalKey();

  final List<String> _selected = ['demam', 'batuk'];
  String _duration = '2-7 hari';
  String _breathing = 'normal';

  static const _durations = ['< 2 hari', '2-7 hari', '> 7 hari'];
  static const _breathingOptions = [
    ('normal', 'Normal', '😌', 'Tanpa bunyi aneh'),
    ('cepat', 'Cepat', '😅💨', 'Lebih dari biasanya'),
    ('mengi', 'Ada mengi', '🔊', "Bunyi 'ngik-ngik'"),
    ('tarikan', 'Tarik napas dalam', '🧏', 'Dinding dada tertarik'),
  ];

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tourControllerProvider.notifier).registerSteps('/symptoms', [
        TourStep(_symptomKey, 'Pilih Gejala',
            'Tandai gejala yang dialami si kecil saat ini. Setelah memilih gejala, lanjut ke rekam suara untuk memulai skrining.'),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentId = ref.watch(currentChildIdProvider).valueOrNull ?? '';
    final children = ref.watch(childrenProvider).valueOrNull ?? const [];
    final active = children.where((c) => c.id == currentId).firstOrNull ?? children.firstOrNull;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? AppColors.darkInk : AppColors.lightInk;

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const NeumoTopBar(title: 'Mulai Skrining'),
          Expanded(
            child: ListView(
              padding: pagePadding,
              children: [
                Row(children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0)
                      const Expanded(
                        child: Divider(height: 1, color: AppColors.lightBorder),
                      ),
                    Expanded(
                      child: Row(children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: i == 0 ? AppColors.primary : AppColors.lightSurface2,
                            shape: BoxShape.circle,
                          ),
                          child: i == 0
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : Text('${i + 1}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.lightFaint)),
                        ),
                        const SizedBox(width: 6),
                        Text(['Gejala', 'Rekam', 'Analisis'][i],
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: i == 0 ? ink : AppColors.lightFaint)),
                      ]),
                    ),
                  ],
                ]),
                const SizedBox(height: 16),
                NeumoCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      Text(active?.emoji ?? '👶', style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(active?.name ?? 'Anak', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        Text('${active?.gender == Gender.male ? 'Laki-laki' : 'Perempuan'} · ${active?.weight ?? 0} kg · ${active?.height ?? 0} cm',
                            style: const TextStyle(fontSize: 12, color: AppColors.lightMuted)),
                      ]),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Pilih Gejala', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ink)),
                const SizedBox(height: 4),
                const Text('Tandai gejala yang dialami si kecil saat ini.', style: TextStyle(fontSize: 13, color: AppColors.lightMuted)),
                const SizedBox(height: 12),
                NeumoShowcase(
                  key: _symptomKey,
                  title: 'Pilih Gejala',
                  description: 'Tandai gejala yang dialami si kecil. Beberapa gejala dapat dipilih.',
                  child: LayoutBuilder(
                    builder: (context, constraints) => Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final s in symptoms)
                          SizedBox(
                            width: (constraints.maxWidth - 10) / 2,
                            child: _SymptomCard(
                              option: s,
                              selected: _selected.contains(s.id),
                              onTap: () => _toggle(s.id),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Durasi Batuk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.lightInk)),
                const SizedBox(height: 10),
                NeumoShowcase(
                  key: _durationKey,
                  title: 'Durasi Batuk',
                  description: 'Pilih berapa lama si kecil mengalami batuk.',
                  child: NeumoSegmented<String>(
                    options: _durations.map((d) => (d, d)).toList(),
                    value: _duration,
                    onChanged: (v) => setState(() => _duration = v),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Pola Pernapasan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.lightInk)),
                const SizedBox(height: 10),
                NeumoShowcase(
                  key: _breathingKey,
                  title: 'Pola Pernapasan',
                  description: 'Pilih pola napas yang terlihat. "Mengi" dan "tarik napas dalam" adalah tanda serius.',
                  child: LayoutBuilder(
                    builder: (context, constraints) => Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final (key, label, icon, desc) in _breathingOptions)
                          SizedBox(
                            width: (constraints.maxWidth - 10) / 2,
                            child: _BreathingCard(
                              optionKey: key,
                              label: label,
                              icon: icon,
                              desc: desc,
                              selected: _breathing == key,
                              onTap: () => setState(() => _breathing = key),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: NeumoShowcase(
              key: _nextKey,
              title: 'Lanjut Rekam Suara',
              description: 'Setelah memilih gejala dan pola napas, rekam bunyi batuk si kecil selama 5 detik.',
              child: NeumoButton(expand: true, size: NeumoSize.lg, label: 'Lanjut Rekam Suara →', onPressed: () => context.push('/record')),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SymptomCard extends StatelessWidget {
  const _SymptomCard({required this.option, required this.selected, required this.onTap});

  final SymptomOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? AppColors.darkInk : AppColors.lightInk;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.lightPrimarySoft : (dark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? AppColors.primary : (dark ? AppColors.darkBorder : AppColors.lightBorder),
              width: selected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(option.icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 8),
            Text(option.label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                    color: selected ? AppColors.primary : ink)),
            const SizedBox(height: 3),
            Text(option.desc, style: const TextStyle(fontSize: 11, color: AppColors.lightMuted, height: 1.3)),
          ],
        ),
      ),
    );
  }
}

class _BreathingCard extends StatelessWidget {
  const _BreathingCard(
      {required this.optionKey, required this.label, required this.icon, required this.desc, required this.selected, required this.onTap});

  final String optionKey;
  final String label;
  final String icon;
  final String desc;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected ? AppColors.lightPrimarySoft : null,
          border: Border.all(
            color: selected ? AppColors.primary : (dark ? AppColors.darkBorder : AppColors.lightBorder),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: selected ? AppColors.primary : (dark ? AppColors.darkInk : AppColors.lightInk))),
            const SizedBox(height: 2),
            Text(desc, style: TextStyle(fontSize: 11, color: dark ? AppColors.darkMuted : AppColors.lightMuted)),
          ],
        ),
      ),
    );
  }
}
