import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neumoi_d/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  test('light theme uses light background', () {
    final theme = buildLightTheme();
    expect(theme.scaffoldBackgroundColor, const Color(0xFFF7FAFC));
    expect(theme.colorScheme.primary, const Color(0xFF1D7AFC));
    expect(theme.brightness, Brightness.light);
  });

  test('dark theme uses dark background', () {
    final theme = buildDarkTheme();
    expect(theme.scaffoldBackgroundColor, const Color(0xFF070C18));
    expect(theme.brightness, Brightness.dark);
  });
}