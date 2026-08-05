import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neumoi_d/core/theme/app_theme.dart';
import 'package:neumoi_d/core/widgets/neumo_bottom_nav.dart';
import 'package:neumoi_d/core/widgets/neumo_notif_bell.dart';
import 'package:neumoi_d/core/widgets/neumo_sync_status.dart';
import 'package:neumoi_d/core/widgets/neumo_top_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('NeumoTopBar shows title and back pops navigation', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildLightTheme(),
      home: Builder(builder: (context) {
        return const Scaffold(body: NeumoTopBar(title: 'Riwayat'));
      }),
    ));
    expect(find.text('Riwayat'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
  });

  testWidgets('NeumoBottomNav renders four tabs and reports selection', (tester) async {
    var selected = -1;
    await tester.pumpWidget(MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(
        body: NeumoBottomNav(
          tabs: const [
            (Icons.home_outlined, 'Beranda'),
            (Icons.bar_chart_outlined, 'Riwayat'),
            (Icons.menu_book_outlined, 'Edukasi'),
            (Icons.person_outline, 'Profil'),
          ],
          currentIndex: 0,
          onSelect: (i) => selected = i,
        ),
      ),
    ));
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
    await tester.tap(find.text('Riwayat'));
    expect(selected, 1);
  });

  testWidgets('NeumoSyncStatus switches label by pending count', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(body: NeumoSyncStatus(pending: 0)),
    ));
    expect(find.text('Tersinkronisasi'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(body: NeumoSyncStatus(pending: 2)),
    ));
    expect(find.text('Menyinkronkan (2)'), findsOneWidget);
  });

  testWidgets('NeumoNotifBell hides badge when unread is zero', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(body: NeumoNotifBell(unread: 0, onTap: () {})),
    ));
    expect(find.text('0'), findsNothing);
    await tester.pumpWidget(MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(body: NeumoNotifBell(unread: 3, onTap: () {})),
    ));
    expect(find.text('3'), findsOneWidget);
  });
}
