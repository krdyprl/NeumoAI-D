import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neumoi_d/core/theme/app_theme.dart';
import 'package:neumoi_d/core/utils/password.dart';
import 'package:neumoi_d/data/mock/mock_repositories.dart';
import 'package:neumoi_d/features/auth/screens/forgot_screen.dart';
import 'package:neumoi_d/features/auth/screens/login_screen.dart';
import 'package:neumoi_d/features/auth/screens/register_screen.dart';
import 'package:neumoi_d/models/profile.dart';
import 'package:neumoi_d/state/app_providers.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('login navigates to home on submit', (tester) async {
    final profileRepo = MockProfileRepository();
    await profileRepo.createAccount(
      const Profile(name: 'Ibu Sari', email: 'ibu@sari.com', phone: '', emoji: '👩', role: 'Orang Tua'),
      hashPassword('rahasia123'),
    );
    final settings = MockSettingsRepository();
    await settings.markTourDone(true);

    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(path: '/forgot', builder: (_, __) => const ForgotScreen()),
        GoRoute(path: '/home', builder: (_, __) => const Scaffold(body: Text('beranda'))),
      ],
    );
    final container = ProviderContainer(overrides: [
      profileRepositoryProvider.overrideWithValue(profileRepo),
      settingsRepositoryProvider.overrideWithValue(settings),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router, theme: buildLightTheme()),
    ));

    expect(find.text('Masuk'), findsWidgets);
    await tester.enterText(find.byType(TextField).first, 'ibu@sari.com');
    await tester.enterText(find.byType(TextField).last, 'rahasia123');
    await tester.tap(find.text('Masuk').last);
    await tester.pumpAndSettle();
    expect(find.text('beranda'), findsOneWidget);
  });
}
