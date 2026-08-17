import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neumoi_d/core/connectivity/connectivity_service.dart';
import 'package:neumoi_d/core/sync/sync_queue.dart';
import 'package:neumoi_d/core/theme/app_theme.dart';
import 'package:neumoi_d/data/mock/mock_repositories.dart';
import 'package:neumoi_d/features/profile/screens/profile_screen.dart';
import 'package:neumoi_d/state/app_providers.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../helpers/noop_showcase_service.dart';

class _FakeConnectivity implements ConnectivityService {
  final _controller = StreamController<bool>.broadcast();
  @override
  Stream<bool> get isOnline => _controller.stream;
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    ShowcaseView.register(enableShowcase: false);
  });
  tearDown(() => ShowcaseView.get().unregister());

  testWidgets('profile shows user info, menu, and updates theme', (tester) async {
    final container = ProviderContainer(overrides: [
      profileRepositoryProvider.overrideWithValue(MockProfileRepository()),
      childRepositoryProvider.overrideWithValue(MockChildRepository()),
      notificationRepositoryProvider.overrideWithValue(MockNotificationRepository()),
      settingsRepositoryProvider.overrideWithValue(MockSettingsRepository()),
      connectivityServiceProvider.overrideWithValue(_FakeConnectivity()),
      syncQueueProvider.overrideWithValue(SyncQueue()),
      showcaseServiceProvider.overrideWithValue(NoopShowcaseService()),
    ]);
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        GoRoute(path: '/children', builder: (_, __) => const Scaffold(body: Text('children-page'))),
        GoRoute(path: '/notifications', builder: (_, __) => const Scaffold(body: Text('notif-page'))),
        GoRoute(path: '/privacy', builder: (_, __) => const Scaffold(body: Text('privacy-page'))),
        GoRoute(path: '/settings', builder: (_, __) => const Scaffold(body: Text('settings-page'))),
        GoRoute(path: '/login', builder: (_, __) => const Scaffold(body: Text('login-page'))),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router, theme: buildLightTheme()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Demo NeumoAid'), findsOneWidget);
    expect(find.text('Kelola Anak'), findsOneWidget);
    expect(find.text('Privasi & Keamanan'), findsOneWidget);

    // Theme segment -> dark
    await tester.tap(find.text('🌙 Gelap'));
    await tester.pumpAndSettle();
    expect(await container.read(themeKeyProvider.future), 'dark');

    // Menu navigation
    await tester.tap(find.text('Kelola Anak'));
    await tester.pumpAndSettle();
    expect(find.text('children-page'), findsOneWidget);
  });
}