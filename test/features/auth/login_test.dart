import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neumoi_d/core/theme/app_theme.dart';
import 'package:neumoi_d/features/auth/screens/forgot_screen.dart';
import 'package:neumoi_d/features/auth/screens/login_screen.dart';
import 'package:neumoi_d/features/auth/screens/register_screen.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('login navigates to home on submit', (tester) async {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(path: '/forgot', builder: (_, __) => const ForgotScreen()),
        GoRoute(path: '/home', builder: (_, __) => const Scaffold(body: Text('beranda'))),
      ],
    );
    final container = ProviderContainer();
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
