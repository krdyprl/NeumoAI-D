import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neumo_top_bar.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _shareData = true;
  bool _analytics = false;
  bool _reminders = true;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? AppColors.darkInk : AppColors.lightInk;
    final muted = dark ? AppColors.darkMuted : AppColors.lightMuted;
    final border = dark ? AppColors.darkBorder : AppColors.lightBorder;
    final surface2 = dark ? AppColors.darkSurface2 : AppColors.lightSurface2;
    final surface = dark ? AppColors.darkSurface : AppColors.lightSurface;

    Widget row(
      String icon,
      String title,
      String desc,
      bool value,
      ValueChanged<bool> onChanged,
    ) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: surface2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(icon, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: ink,
                    ),
                  ),
                  Text(
                    desc,
                    style: TextStyle(fontSize: 12, color: muted, height: 1.4),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppColors.primary,
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const NeumoTopBar(title: 'Privasi & Keamanan'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🛡️', style: TextStyle(fontSize: 26)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Data kesehatan Anda dan anak terenkripsi end-to-end. Hasil skrining hanya dapat diakses oleh Anda dan tenaga medis yang Anda pilih.',
                            style: TextStyle(
                              fontSize: 13,
                              color: muted,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      children: [
                        row(
                          '🩺',
                          'Bagikan hasil dengan dokter',
                          'Izinkan akses hasil skrining untuk konsultasi medis',
                          _shareData,
                          (v) => setState(() => _shareData = v),
                        ),
                        row(
                          '📊',
                          'Analitik penggunaan',
                          'Bantu kami meningkatkan akurasi AI secara anonim',
                          _analytics,
                          (v) => setState(() => _analytics = v),
                        ),
                        row(
                          '🔔',
                          'Pengingat kesehatan',
                          'Vaksinasi, skrining rutin, dan saran kesehatan',
                          _reminders,
                          (v) => setState(() => _reminders = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Pribadi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed:
                              () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Permintaan unduh data dikirim.',
                                  ),
                                ),
                              ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Unduh data saya',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed:
                              () => showDialog<void>(
                                context: context,
                                builder:
                                    (ctx) => AlertDialog(
                                      title: const Text('Hapus akun dan data?'),
                                      content: const Text(
                                        'Seluruh data anak dan riwayat skrining akan dihapus permanen.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(ctx).pop(),
                                          child: const Text('Batal'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(ctx).pop();
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Akun tidak dapat dihapus dalam mode demo.',
                                                ),
                                              ),
                                            );
                                          },
                                          child: const Text(
                                            'Hapus',
                                            style: TextStyle(
                                              color: AppColors.danger,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                              ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Hapus akun dan data',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
