import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neumoi_d/core/theme/app_theme.dart';
import 'package:neumoi_d/features/profile/screens/privacy_screen.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('privacy toggles switches, shows snackbar and delete dialog', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: buildLightTheme(), home: const PrivacyScreen()));
    await tester.pumpAndSettle();

    // Three switches present and initially set
    expect(find.byType(Switch), findsNWidgets(3));
    expect(find.text('Bagikan hasil dengan dokter'), findsOneWidget);
    expect(find.text('Analitik penggunaan'), findsOneWidget);
    expect(find.text('Pengingat kesehatan'), findsOneWidget);

    // Toggle the analytics switch (initially off -> on)
    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches[1].value, isFalse);
    await tester.tap(find.byType(Switch).at(1));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch).at(1)).value, isTrue);

    // Unduh data saya -> snackbar
    await tester.tap(find.text('Unduh data saya'));
    await tester.pump();
    expect(find.text('Permintaan unduh data dikirim.'), findsOneWidget);
    await tester.pumpAndSettle();

    // Hapus akun dan data -> confirm dialog -> Batal keeps dialog closed
    await tester.tap(find.text('Hapus akun dan data'));
    await tester.pumpAndSettle();
    expect(find.text('Hapus akun dan data?'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('Hapus akun dan data?'), findsNothing);
  });
}