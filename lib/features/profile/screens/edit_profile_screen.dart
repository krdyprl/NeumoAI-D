import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/neumo_button.dart';
import '../../../core/widgets/neumo_field.dart';
import '../../../core/widgets/neumo_top_bar.dart';
import '../../../data/mock/mock_data.dart';
import '../../../models/profile.dart';
import '../../../state/app_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).valueOrNull ?? MockData.profile;
    _name = TextEditingController(text: profile.name);
    _email = TextEditingController(text: profile.email);
    _phone = TextEditingController(text: profile.phone);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final profile = ref.read(profileProvider).valueOrNull ?? MockData.profile;
    final updated = Profile(
      name: _name.text.trim().isEmpty ? profile.name : _name.text.trim(),
      email: _email.text.trim().isEmpty ? profile.email : _email.text.trim(),
      phone: _phone.text.trim().isEmpty ? profile.phone : _phone.text.trim(),
      emoji: profile.emoji,
      role: profile.role,
    );
    await ref.read(profileProvider.notifier).updateProfile(updated);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).valueOrNull ?? MockData.profile;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const NeumoTopBar(title: 'Edit Profil'),
          Expanded(
            child: ListView(
              padding: pagePadding,
              children: [
                Center(
                  child: Column(children: [
                    Container(
                      width: 96,
                      height: 96,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0x291D7AFC), Color(0x293ECF8E)],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                      ),
                      child: Text(profile.emoji, style: const TextStyle(fontSize: 52)),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fitur ubah foto segera hadir.'))),
                      child: const Text('Ubah Foto', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                NeumoField(label: 'NAMA', controller: _name),
                const SizedBox(height: 16),
                NeumoField(label: 'EMAIL', controller: _email, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                NeumoField(label: 'NOMOR HP', controller: _phone, keyboardType: TextInputType.phone),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: NeumoButton(expand: true, size: NeumoSize.lg, label: 'Simpan Perubahan', onPressed: _save),
          ),
        ]),
      ),
    );
  }
}