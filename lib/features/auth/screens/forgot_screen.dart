import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neumo_button.dart';
import '../../../core/widgets/neumo_field.dart';

class ForgotScreen extends StatefulWidget {
  const ForgotScreen({super.key});

  @override
  State<ForgotScreen> createState() => _ForgotScreenState();
}

class _ForgotScreenState extends State<ForgotScreen> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _send() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tautan reset telah dikirim ke email Anda.')),
    );
    Navigator.of(context).pop();
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
              Text('Lupa kata sandi', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: ink)),
              const SizedBox(height: 6),
              const Text('Masukkan email terdaftar untuk menerima tautan reset.', style: TextStyle(fontSize: 14, color: AppColors.lightMuted)),
              const SizedBox(height: 28),
              NeumoField(label: 'Email', controller: _email, placeholder: 'nama@email.com', keyboardType: TextInputType.emailAddress, icon: Icons.mail_outline),
              const SizedBox(height: 28),
              NeumoButton(expand: true, size: NeumoSize.lg, label: 'Kirim Tautan Reset', onPressed: _send),
            ],
          ),
        ),
      ),
    );
  }
}
