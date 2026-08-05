import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

ThemeData buildLightTheme() => _baseTheme(Brightness.light);

ThemeData buildDarkTheme() => _baseTheme(Brightness.dark);

ThemeData _baseTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: brightness,
  ).copyWith(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    error: AppColors.danger,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
  );

  final ink = dark ? AppColors.darkInk : AppColors.lightInk;
  final bg = dark ? AppColors.darkBg : AppColors.lightBg;

  return base.copyWith(
    scaffoldBackgroundColor: bg,
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: ink,
      displayColor: ink,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: ink,
      elevation: 0,
    ),
    dividerTheme: DividerThemeData(color: dark ? AppColors.darkBorder : AppColors.lightBorder),
    splashFactory: InkSparkle.splashFactory,
  );
}