import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neumo_button.dart';
import '../../../core/widgets/neumo_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() => context.go('/home');

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? AppColors.darkInk : AppColors.lightInk;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.coronavirus, color: AppColors.primary, size: 48),
              const SizedBox(height: 20),
              Text('Selamat datang kembali', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: ink)),
              const SizedBox(height: 6),
              const Text('Masuk untuk memantau kesehatan si kecil.', style: TextStyle(fontSize: 14, color: AppColors.lightMuted)),
              const SizedBox(height: 32),
              NeumoField(label: 'Email', controller: _email, placeholder: 'nama@email.com', keyboardType: TextInputType.emailAddress, icon: Icons.mail_outline),
              const SizedBox(height: 16),
              NeumoField(label: 'Kata sandi', controller: _password, placeholder: '••••••••', obscure: true, icon: Icons.lock_outline),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/forgot'),
                  child: const Text('Lupa kata sandi?', style: TextStyle(fontSize: 13, color: AppColors.primary)),
                ),
              ),
              const SizedBox(height: 8),
              NeumoButton(expand: true, size: NeumoSize.lg, label: 'Masuk', onPressed: _submit),
              const SizedBox(height: 24),
              const Row(children: [
                Expanded(child: Divider()),
                Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('atau', style: TextStyle(fontSize: 12, color: AppColors.lightMuted))),
                Expanded(child: Divider()),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.g_mobiledata, color: Color(0xFF4285F4)),
                  label: const Text('Masuk dengan Google', style: TextStyle(fontSize: 15, color: AppColors.lightInk)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: const BorderSide(color: AppColors.lightBorder),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Belum punya akun?', style: TextStyle(fontSize: 13, color: AppColors.lightMuted)),
                  TextButton(
                    onPressed: () => context.push('/register'),
                    child: const Text('Daftar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
