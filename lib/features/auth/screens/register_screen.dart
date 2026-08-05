import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neumo_button.dart';
import '../../../core/widgets/neumo_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Akun berhasil dibuat. Silakan masuk.')),
    );
    context.go('/login');
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
              NeumoButton(expand: true, size: NeumoSize.lg, label: 'Daftar', onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
