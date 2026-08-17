import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/neumo_avatar.dart';
import '../../../core/widgets/neumo_button.dart';
import '../../../core/widgets/neumo_card.dart';
import '../../../core/widgets/neumo_empty_state.dart';
import '../../../core/widgets/neumo_top_bar.dart';
import '../../../models/enums.dart';
import '../../../state/app_providers.dart';

class ChildrenScreen extends ConsumerWidget {
  const ChildrenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(childrenProvider).valueOrNull ?? const [];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const NeumoTopBar(title: 'Anak Saya'),
            Expanded(
              child: children.isEmpty
                  ? const NeumoEmptyState(
                      icon: '👶', title: 'Belum ada anak', desc: 'Tambahkan anak untuk mulai memantau kesehatan.',)
                  : ListView.separated(
                      padding: pagePadding,
                      itemCount: children.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final c = children[i];
                        final done = c.vaccinations.where((v) => v.done).length;
                        return NeumoCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(children: [
                              NeumoAvatar(emoji: c.emoji, size: 52),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(c.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text('${c.gender == Gender.male ? 'Laki-laki' : 'Perempuan'} · ${c.weight} kg · ${c.height} cm',
                                      style: const TextStyle(fontSize: 12, color: AppColors.lightMuted)),
                                  const SizedBox(height: 4),
                                  Text('Vaksinasi $done/${c.vaccinations.length}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                                ]),
                              ),
                              IconButton(
                                onPressed: () async {
                                  await ref.read(childrenProvider.notifier).remove(c.id);
                                },
                                icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: NeumoButton(
                expand: true,
                size: NeumoSize.lg,
                label: 'Tambah Anak',
                icon: Icons.add,
                onPressed: () => context.push('/child-form'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
