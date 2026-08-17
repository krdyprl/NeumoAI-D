import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/tour_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neumo_button.dart';
import '../../../core/widgets/neumo_field.dart';
import '../../../state/app_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final phone = _phone.text.trim();
    final password = _password.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _show('Lengkapi nama, email, dan kata sandi.');
      return;
    }
    if (!email.contains('@')) {
      _show('Format email tidak valid.');
      return;
    }
    if (password.length < 8) {
      _show('Kata sandi minimal 8 karakter.');
      return;
    }

    setState(() => _submitting = true);
    final error = await ref.read(authProvider.notifier).register(
          name: name,
          email: email,
          phone: phone,
          password: password,
        );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (error != null) {
      _show(error);
      return;
    }

    // First-time tour after successful registration.
    await ref.read(tourControllerProvider.notifier).start();
    if (mounted) context.go('/home');
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? AppColors.darkInk : AppColors.lightInk;
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Buat akun baru', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: ink)),
              const SizedBox(height: 6),
              const Text('Mulai pantau kesehatan anak Anda.', style: TextStyle(fontSize: 14, color: AppColors.lightMuted)),
              const SizedBox(height: 28),
              NeumoField(label: 'Nama lengkap', controller: _name, placeholder: 'Ibu Sari', icon: Icons.person_outline),
              const SizedBox(height: 16),
              NeumoField(label: 'Email', controller: _email, placeholder: 'nama@email.com', keyboardType: TextInputType.emailAddress, icon: Icons.mail_outline),
              const SizedBox(height: 16),
              NeumoField(label: 'No. telepon', controller: _phone, placeholder: '+62 812-...', keyboardType: TextInputType.phone, icon: Icons.phone_outlined),
              const SizedBox(height: 16),
              NeumoField(label: 'Kata sandi', controller: _password, placeholder: 'Minimal 8 karakter', obscure: true, icon: Icons.lock_outline),
              const SizedBox(height: 28),
              NeumoButton(
                expand: true,
                size: NeumoSize.lg,
                label: _submitting ? 'Mendaftar…' : 'Daftar',
                onPressed: _submitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
