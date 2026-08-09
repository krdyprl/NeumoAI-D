import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neumoi_d/core/connectivity/connectivity_service.dart';
import 'package:neumoi_d/core/sync/sync_queue.dart';
import 'package:neumoi_d/core/theme/app_theme.dart';
import 'package:neumoi_d/features/notifications/screens/notifications_screen.dart';
import 'package:neumoi_d/state/app_providers.dart';

class _FakeConnectivity implements ConnectivityService {
  final _controller = StreamController<bool>.broadcast();
  @override
  Stream<bool> get isOnline => _controller.stream;
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('notifications lists, filters, and marks read', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(overrides: [
      connectivityServiceProvider.overrideWithValue(_FakeConnectivity()),
      syncQueueProvider.overrideWithValue(SyncQueue()),
    ]);
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/notifications',
      routes: [
        GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
        GoRoute(path: '/result', builder: (_, __) => const Scaffold(body: Text('result-page'))),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router, theme: buildLightTheme()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Notifikasi'), findsOneWidget);
    expect(find.text('Hasil skrining Arya tersedia'), findsOneWidget);

    // Filter: only medical type
    await tester.tap(find.text('Medis'));
    await tester.pumpAndSettle();
    expect(find.text('Hasil skrining Arya tersedia'), findsNothing);
    expect(find.text('Saran dari dr. Rina'), findsOneWidget);

    // Tap an AI notification -> navigate to result + mark read
    await tester.tap(find.text('Semua'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hasil skrining Arya tersedia'));
    await tester.pumpAndSettle();
    expect(find.text('result-page'), findsOneWidget);

    // markRead actually flipped the flag
    final notifs = await container.read(notificationsProvider.future);
    final n1 = notifs.firstWhere((n) => n.id == 'n1');
    expect(n1.read, isTrue);
  });
}