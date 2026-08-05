import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neumo_button.dart';
import '../../../core/widgets/neumo_card.dart';
import '../../../core/widgets/neumo_segmented.dart';
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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
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
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.6,
                  children: [
                    for (final s in symptoms)
                      InkWell(
                        onTap: () => _toggle(s.id),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _selected.contains(s.id) ? AppColors.lightPrimarySoft : (dark ? AppColors.darkSurface : AppColors.lightSurface),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: _selected.contains(s.id) ? AppColors.primary : AppColors.lightBorder,
                                width: _selected.contains(s.id) ? 2 : 1),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s.icon, style: const TextStyle(fontSize: 22)),
                            const Spacer(),
                            Text(s.label,
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.bold,
                                    color: _selected.contains(s.id) ? AppColors.primary : ink)),
                            Text(s.desc, style: const TextStyle(fontSize: 11, color: AppColors.lightMuted)),
                          ]),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Durasi Batuk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.lightInk)),
                const SizedBox(height: 10),
                NeumoSegmented<String>(
                  options: _durations.map((d) => (d, d)).toList(),
                  value: _duration,
                  onChanged: (v) => setState(() => _duration = v),
                ),
                const SizedBox(height: 20),
                const Text('Pola Pernapasan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.lightInk)),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.1,
                  children: [
                    for (final (key, label, icon, desc) in _breathingOptions)
                      InkWell(
                        onTap: () => setState(() => _breathing = key),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: _breathing == key ? AppColors.primary : AppColors.lightBorder,
                                width: _breathing == key ? 2 : 1),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(icon, style: const TextStyle(fontSize: 20)),
                            const SizedBox(height: 4),
                            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.lightMuted)),
                          ]),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: NeumoButton(expand: true, size: NeumoSize.lg, label: 'Lanjut Rekam Suara →', onPressed: () => context.go('/record')),
          ),
        ]),
      ),
    );
  }
}
