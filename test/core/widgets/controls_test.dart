import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neumoi_d/core/theme/app_colors.dart';
import 'package:neumoi_d/core/theme/app_theme.dart';
import 'package:neumoi_d/core/widgets/neumo_button.dart';
import 'package:neumoi_d/core/widgets/neumo_chip.dart';
import 'package:neumoi_d/core/widgets/neumo_field.dart';
import 'package:neumoi_d/core/widgets/neumo_progress.dart';
import 'package:neumoi_d/core/widgets/neumo_ring.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('NeumoButton renders label and fires onPressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(
        body: NeumoButton(label: 'Mulai Skrining', onPressed: () => tapped = true),
      ),
    ));
    expect(find.text('Mulai Skrining'), findsOneWidget);
    await tester.tap(find.byType(NeumoButton));
    expect(tapped, isTrue);
  });

  testWidgets('NeumoChip renders children', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(body: NeumoChip(tone: NeumoTone.danger, child: const Text('Tinggi'))),
    ));
    expect(find.text('Tinggi'), findsOneWidget);
  });

  testWidgets('NeumoField emits onChanged', (tester) async {
    String? value;
    await tester.pumpWidget(MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(
        body: NeumoField(label: 'Nama', onChanged: (v) => value = v),
      ),
    ));
    await tester.enterText(find.byType(TextField), 'Arya');
    expect(value, 'Arya');
  });

  testWidgets('NeumoRing shows percentage label', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(
        body: NeumoRing(value: 87, size: 92, stroke: 8, color: AppColors.danger, label: const Text('87%'), sublabel: 'keyakinan AI'),
      ),
    ));
    expect(find.text('87%'), findsOneWidget);
    expect(find.text('keyakinan AI'), findsOneWidget);
  });

  testWidgets('NeumoProgress renders track and fill', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(body: NeumoProgress(value: 40, color: AppColors.primary)),
    ));
    expect(find.byType(NeumoProgress), findsOneWidget);
  });
}
