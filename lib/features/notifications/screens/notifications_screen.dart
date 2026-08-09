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
    final border = dark ? AppColors.darkBorder : AppColors.lightBorder;
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
                              border: _filter == key ? null : Border.all(color: border),
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
                  Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Center(child: Text('Belum ada notifikasi', style: TextStyle(color: muted))),
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
                              color: n.read ? border : AppColors.primary.withValues(alpha: 0.25)),
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