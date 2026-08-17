import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/tour_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/neumo_button.dart';
import '../../../core/widgets/neumo_segmented.dart';
import '../../../core/widgets/neumo_showcase.dart';
import '../../../core/widgets/neumo_top_bar.dart';
import '../../../data/mock/mock_data.dart';
import '../../../state/app_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final GlobalKey _profileCardKey = GlobalKey();
  final GlobalKey _menuKey = GlobalKey();
  final GlobalKey _themeKey = GlobalKey();
  final GlobalKey _logoutKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tourControllerProvider.notifier).registerSteps('/profile', [
        TourStep(_profileCardKey, 'Profil Saya',
            'Lihat informasi akun, kelola anak, dan atur tema aplikasi. Dari sini akses semua pengaturan.'),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? AppColors.darkInk : AppColors.lightInk;
    final muted = dark ? AppColors.darkMuted : AppColors.lightMuted;
    final border = dark ? AppColors.darkBorder : AppColors.lightBorder;
    final surface2 = dark ? AppColors.darkSurface2 : AppColors.lightSurface2;
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
        child: Column(children: [
          const NeumoTopBar(title: 'Profil Saya'),
          Expanded(
            child: ListView(
              padding: pagePaddingWithBottomNav,
              children: [
                // Profile card
                NeumoShowcase(
                  key: _profileCardKey,
                  title: 'Profil Saya',
                  description: 'Informasi akun lengkap termasuk nama, email, dan status sinkronisasi data.',
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, Color(0xFF4A8FFC)],
                      ),
                    ),
                    child: Row(children: [
                      Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(22)),
                        child: Text(profile.emoji,
                            style: const TextStyle(fontSize: 34)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(profile.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                              Text(profile.email,
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.white70)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(999)),
                                child: Text(
                                    pendingSync == 0
                                        ? 'Semua data tersinkronisasi'
                                        : 'Sinkronisasi tertunda ($pendingSync)',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white)),
                              ),
                            ]),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/edit-profile'),
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.edit_outlined,
                              size: 18, color: Colors.white),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),
                // Menu
                NeumoShowcase(
                  key: _menuKey,
                  title: 'Menu Pengaturan',
                  description: 'Akses Kelola Anak, Notifikasi, Privasi & Keamanan, dan Pengaturan.',
                  child: Container(
                    decoration: BoxDecoration(
                      color: dark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: border),
                    ),
                    child: Column(children: [
                      for (final (emoji, label, sub, route) in menuRows)
                        InkWell(
                          onTap: () => context.push(route),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            child: Row(children: [
                              Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: surface2,
                                    borderRadius: BorderRadius.circular(12)),
                                child: Text(emoji,
                                    style: const TextStyle(fontSize: 20)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(label,
                                          style: TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.bold,
                                              color: ink)),
                                      Text(sub,
                                          style: TextStyle(
                                              fontSize: 12, color: muted)),
                                    ]),
                              ),
                              Icon(Icons.chevron_right,
                                  size: 20,
                                  color: dark
                                      ? AppColors.darkFaint
                                      : AppColors.lightFaint),
                            ]),
                          ),
                        ),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),
                // Theme
                NeumoShowcase(
                  key: _themeKey,
                  title: 'Tema Aplikasi',
                  description: 'Pilih tampilan Terang, Gelap, atau otomatis mengikuti sistem.',
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: dark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tampilan',
                              style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: ink)),
                          const SizedBox(height: 12),
                          NeumoSegmented<String>(
                            options: const [
                              ('light', '☀️ Terang'),
                              ('dark', '🌙 Gelap'),
                              ('system', '🔄 Auto'),
                            ],
                            value: themeKey,
                            onChanged: (v) =>
                                ref.read(themeKeyProvider.notifier).setThemeKey(v),
                          ),
                          const SizedBox(height: 8),
                          Text(
                              'Mode gelap otomatis mengikuti sistem saat memilih "Auto".',
                              style: TextStyle(
                                  fontSize: 12, color: muted)),
                        ]),
                  ),
                ),
                const SizedBox(height: 24),
                // Logout
                NeumoShowcase(
                  key: _logoutKey,
                  title: 'Keluar',
                  description: 'Keluar dari akun dan kembali ke layar masuk.',
                  child: NeumoButton(
                    variant: NeumoVariant.danger,
                    expand: true,
                    size: NeumoSize.lg,
                    label: 'Keluar',
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                      'NeumoAI-D v1.0.0 · Made with 💙 di Indonesia',
                      style: TextStyle(
                          fontSize: 12,
                          color: dark
                              ? AppColors.darkFaint
                              : AppColors.lightFaint)),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
