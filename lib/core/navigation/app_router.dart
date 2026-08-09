import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/forgot_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/children/screens/child_form_screen.dart';
import '../../features/children/screens/children_screen.dart';
import '../../features/education/screens/article_screen.dart';
import '../../features/education/screens/education_screen.dart';
import '../../features/history/screens/history_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/privacy_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/settings_screen.dart';
import '../../features/result/screens/result_screen.dart';
import '../../features/screening/screens/processing_screen.dart';
import '../../features/screening/screens/record_screen.dart';
import '../../features/screening/screens/symptoms_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import 'app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forgot', builder: (_, __) => const ForgotScreen()),
      GoRoute(path: '/symptoms', builder: (_, __) => const SymptomsScreen()),
      GoRoute(path: '/record', builder: (_, __) => const RecordScreen()),
      GoRoute(path: '/processing', builder: (_, __) => const ProcessingScreen()),
      GoRoute(
        path: '/result',
        builder: (_, state) => ResultScreen(
          screeningId: state.uri.queryParameters['screeningId'],
        ),
      ),
      GoRoute(path: '/children', builder: (_, __) => const ChildrenScreen()),
      GoRoute(
        path: '/child-form',
        builder: (_, state) => ChildFormScreen(
          childId: state.uri.queryParameters['childId'],
        ),
      ),
      GoRoute(
        path: '/article',
        builder: (_, state) => ArticleScreen(
          articleId: state.uri.queryParameters['articleId'],
        ),
      ),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/edit-profile', builder: (_, __) => const EditProfileScreen()),
      GoRoute(path: '/privacy', builder: (_, __) => const PrivacyScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, __) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/history', builder: (_, __) => const HistoryScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/education', builder: (_, __) => const EducationScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen())]),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});