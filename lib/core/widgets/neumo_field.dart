import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NeumoField extends StatelessWidget {
  const NeumoField({
    super.key,
    this.label,
    this.value,
    this.onChanged,
    this.placeholder,
    this.keyboardType = TextInputType.text,
    this.icon,
    this.hint,
    this.obscure = false,
  });

  final String? label;
  final String? value;
  final ValueChanged<String>? onChanged;
  final String? placeholder;
  final TextInputType keyboardType;
  final IconData? icon;
  final String? hint;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.darkInk : AppColors.lightInk;
    final surface = dark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = dark ? AppColors.darkBorder : AppColors.lightBorder;
    final faint = dark ? AppColors.darkFaint : AppColors.lightFaint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: value == null ? null : TextEditingController(text: value),
          onChanged: onChanged,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: TextStyle(color: textColor, fontSize: 15),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: faint),
            prefixIcon: icon == null ? null : Icon(icon, color: faint, size: 20),
            filled: true,
            fillColor: surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.primary, width: 1.6),
            ),
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 4),
          Text(hint!, style: TextStyle(fontSize: 12, color: dark ? AppColors.darkMuted : AppColors.lightMuted)),
        ],
      ],
    );
  }
}
