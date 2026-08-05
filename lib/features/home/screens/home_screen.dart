import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/neumo_card.dart';
import '../../../core/widgets/neumo_chip.dart';
import '../../../core/widgets/neumo_notif_bell.dart';
import '../../../core/widgets/neumo_ring.dart';
import '../../../core/widgets/neumo_sync_status.dart';
import '../../../models/child.dart';
import '../../../models/enums.dart';
import '../../../models/screening.dart';
import '../../../state/app_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final children = ref.watch(childrenProvider).valueOrNull ?? const <Child>[];
    final screenings = ref.watch(screeningsProvider).valueOrNull ?? const <Screening>[];
    final notifications = ref.watch(notificationsProvider).valueOrNull ?? const [];
    final pendingSync = ref.watch(pendingSyncProvider).valueOrNull ?? 0;
    final currentId = ref.watch(currentChildIdProvider).valueOrNull ?? '';
    final unread = notifications.where((n) => !n.read).length;

    final child = children.where((c) => c.id == currentId).firstOrNull ?? children.firstOrNull;
    final latest = screenings.where((s) => s.childId == child?.id).firstOrNull ?? screenings.firstOrNull;
    final risk = latest?.riskLevel ?? RiskLevel.low;

    final (riskColor, riskLabel, riskDesc) = switch (risk) {
      RiskLevel.low => (AppColors.secondary, 'Rendah', 'Kesehatan pernapasan dalam kondisi baik. Lanjutkan pola sehat.'),
      RiskLevel.medium => (AppColors.accent, 'Sedang', 'Ada tanda pneumonia yang perlu diwaspadai. Pantau gejala lebih dekat.'),
      RiskLevel.high => (AppColors.danger, 'Tinggi', 'Segera bawa anak ke fasilitas kesehatan terdekat untuk pemeriksaan pneumonia.'),
    };

    final ink = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkInk
        : AppColors.lightInk;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${greeting(DateTime.now())} 👋',
                        style: const TextStyle(fontSize: 13, color: AppColors.lightMuted)),
                    const SizedBox(height: 2),
                    Text(profile?.name ?? 'Pengguna',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: ink)),
                  ],
                ),
              ),
              NeumoSyncStatus(pending: pendingSync),
              const SizedBox(width: 10),
              NeumoNotifBell(unread: unread, onTap: () => context.go('/notifications')),
            ],
          ),
          const SizedBox(height: 16),
          _ChildSelector(children: children, currentId: currentId),
          const SizedBox(height: 16),
          _HealthStatusCard(
            child: child,
            latest: latest,
            riskColor: riskColor,
            riskLabel: riskLabel,
            riskDesc: riskDesc,
          ),
          const SizedBox(height: 16),
          _QuickActions(),
          const SizedBox(height: 16),
          _LatestRecommendation(childName: child?.name.split(' ').first ?? 'si kecil'),
          const SizedBox(height: 20),
          _HealthCenters(),
          if (pendingSync > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.lightAccentSoft,
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                const Text('✓', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('$pendingSync perubahan akan diunggah saat koneksi kembali.',
                      style: const TextStyle(fontSize: 12, color: AppColors.accentDeep)),
                ),
                const Text('Offline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accentDeep)),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChildSelector extends ConsumerWidget {
  const _ChildSelector({required this.children, required this.currentId});

  final List<Child> children;
  final String currentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 64,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final c in children)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => ref.read(currentChildIdProvider.notifier).select(c.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: c.id == currentId
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : (dark ? AppColors.darkSurface : AppColors.lightSurface),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: c.id == currentId ? AppColors.primary : AppColors.lightBorder),
                  ),
                  child: Row(children: [
                    Text(c.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name.split(' ').first,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        Text(c.gender == Gender.male ? 'Laki-laki' : 'Perempuan',
                            style: const TextStyle(fontSize: 11, color: AppColors.lightMuted)),
                      ],
                    ),
                  ]),
                ),
              ),
            ),
          GestureDetector(
            onTap: () => context.go('/child-form'),
            child: Container(
              width: 110,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: const Text('+ Tambah',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.lightMuted)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthStatusCard extends StatelessWidget {
  const _HealthStatusCard({
    required this.child,
    required this.latest,
    required this.riskColor,
    required this.riskLabel,
    required this.riskDesc,
  });

  final Child? child;
  final Screening? latest;
  final Color riskColor;
  final String riskLabel;
  final String riskDesc;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkInk
        : AppColors.lightInk;
    final confidence = latest?.confidence ?? 20;
    return NeumoCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Status Kesehatan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ink)),
                  const SizedBox(height: 2),
                  Text('${child?.name.split(' ').first ?? ''} · pemantauan terakhir hari ini',
                      style: const TextStyle(fontSize: 12, color: AppColors.lightMuted)),
                ]),
                NeumoChip(tone: _toneFor(riskColor), child: Text('Risiko $riskLabel')),
              ],
            ),
            const SizedBox(height: 16),
            Row(children: [
              NeumoRing(
                value: confidence.toDouble(),
                color: riskColor,
                label: Text('$confidence%'),
                sublabel: 'keyakinan AI',
                size: 92,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(latest == null
                          ? 'Belum ada skrining'
                          : (latest!.riskLevel == RiskLevel.low
                              ? 'Tidak terindikasi ${latest!.disease}'
                              : 'Terindikasi ${latest!.disease}'),
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ink)),
                  const SizedBox(height: 4),
                  Text(riskDesc, style: const TextStyle(fontSize: 13, color: AppColors.lightMuted)),
                ]),
              ),
            ]),
            if (latest != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkSurface2
                      : AppColors.lightSurface2,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  const Text('🕒', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Text(formatIdDate(DateTime.parse(latest!.date)),
                      style: const TextStyle(fontSize: 12.5, color: AppColors.lightMuted)),
                  const SizedBox(width: 6),
                  const Text('·', style: TextStyle(color: AppColors.lightFaint)),
                  const SizedBox(width: 6),
                  Text('${latest!.audioDuration} detik audio',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.lightMuted)),
                  const Spacer(),
                  const Text('Terbaru',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

NeumoTone _toneFor(Color color) {
  if (color == AppColors.danger) return NeumoTone.danger;
  if (color == AppColors.accent) return NeumoTone.accent;
  return NeumoTone.secondary;
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, VoidCallback)>[
      (Icons.medical_services, 'Mulai Skrining', () => context.go('/symptoms')),
      (Icons.show_chart, 'Riwayat Kesehatan', () => context.go('/history')),
      (Icons.menu_book_outlined, 'Edukasi Napas', () => context.go('/education')),
      (Icons.local_hospital_outlined, 'Faskes Terdekat', () {}),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        for (final (icon, label, onTap) in items)
          _QuickActionTile(icon: icon, label: label, primary: label == 'Mulai Skrining', onTap: onTap),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.icon, required this.label, required this.primary, required this.onTap});

  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: primary
              ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primary, AppColors.primaryDeep])
              : null,
          color: primary ? null : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.lightSurface),
          border: primary ? null : Border.all(color: AppColors.lightBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 26, color: primary ? Colors.white : AppColors.primary),
            const Spacer(),
            Text(label,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: primary ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkInk : AppColors.lightInk))),
          ],
        ),
      ),
    );
  }
}

class _LatestRecommendation extends StatelessWidget {
  const _LatestRecommendation({required this.childName});

  final String childName;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/result?screeningId=s1'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0B1B33), Color(0xFF13294D)]),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            const Text('REKOMENDASI AI TERBARU',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70, letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 12),
          Text('Rekomendasi dr. Rina untuk $childName',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 6),
          const Text('Segera bawa ke puskesmas untuk pemeriksaan lanjutan. Jangan beri obat batuk sebelum diperiksa dokter.',
              style: TextStyle(fontSize: 13.5, color: Colors.white70, height: 1.5)),
          const SizedBox(height: 14),
          const Row(children: [
              Text('Lihat hasil lengkap', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
              SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 18, color: Colors.white),
          ]),
        ]),
      ),
    );
  }
}

class _HealthCenters extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final centers = ref.watch(centersProvider).valueOrNull ?? const [];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Fasilitas Kesehatan Terdekat',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      for (final hc in centers) ...[
        NeumoCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Text(hc.open ? '🏥' : '❌', style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(hc.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(hc.address, style: const TextStyle(fontSize: 12, color: AppColors.lightMuted)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Text('⭐ ${hc.rating.toStringAsFixed(1)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.lightFaint)),
                    const Spacer(),
                    Text('${hc.distance} · Arah →',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 10),
      ],
    ]);
  }
}
