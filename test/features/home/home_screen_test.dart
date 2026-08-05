import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neumoi_d/core/connectivity/connectivity_service.dart';
import 'package:neumoi_d/core/sync/sync_queue.dart';
import 'package:neumoi_d/core/theme/app_theme.dart';
import 'package:neumoi_d/features/home/screens/home_screen.dart';
import 'package:neumoi_d/state/app_providers.dart';

class _FakeConnectivity implements ConnectivityService {
  final _controller = StreamController<bool>.broadcast();
  @override
  Stream<bool> get isOnline => _controller.stream;
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('home renders health status and child selector', (tester) async {
    final connectivity = _FakeConnectivity();
    final container = ProviderContainer(overrides: [
      connectivityServiceProvider.overrideWithValue(connectivity),
      syncQueueProvider.overrideWithValue(SyncQueue()),
    ]);
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/home',
      routes: [GoRoute(path: '/home', builder: (_, __) => const HomeScreen())],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router, theme: buildLightTheme()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Ibu Sari'), findsOneWidget);
    expect(find.text('Arya'), findsOneWidget);
    expect(find.text('Status Kesehatan'), findsOneWidget);
    expect(find.text('Mulai Skrining'), findsOneWidget);
    expect(find.text('Rekan AI Terbaru'), findsNothing);
    await connectivity._controller.close();
  });
}
