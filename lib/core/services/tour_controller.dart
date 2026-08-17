import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/app_providers.dart';
import '../navigation/app_router.dart';

/// A single showcase step belonging to a tour route.
class TourStep {
  TourStep(this.key, this.title, this.description);

  final GlobalKey key;
  final String title;
  final String description;
}

/// Manages the global multi-screen guided tour.
///
/// The tour visits routes in order, showing every [TourStep] registered for
/// the current route. The "Lanjut" tooltip button advances within the route;
/// once the last step of a route is completed, the tour navigates to the next
/// route automatically. The tour starts the first time after login and
/// finishes by returning to Home.
class TourController extends AsyncNotifier<void> {
  /// Ordered list of routes visited during the tour.
  static const List<String> tourRoutes = [
    '/home',
    '/symptoms',
    '/history',
    '/education',
    '/profile',
  ];

  final Map<String, List<TourStep>> _stepsByRoute = {};
  bool _running = false;
  int _index = 0;

  bool get isRunning => _running;

  /// The route whose tour is currently active.
  String get activeRoute {
    if (_index < 0 || _index >= tourRoutes.length) return '/home';
    return tourRoutes[_index];
  }

  @override
  Future<void> build() async {}

  /// Registers the steps belonging to [route]. Called by each screen in its
  /// post-frame callback. If the tour is currently running on [route], the
  /// showcase is started immediately.
  void registerSteps(String route, List<TourStep> steps) {
    _stepsByRoute[route] = steps;
    if (_running && activeRoute == route) {
      _runRouteSteps(route);
    }
  }

  /// Starts the tour from the first route (Home). No-op if already running or
  /// the tour was completed.
  Future<void> start() async {
    if (_running) return;
    final settings = ref.read(settingsRepositoryProvider);
    if (await settings.isTourDone()) return;
    _running = true;
    _index = 0;
    _goTo(activeRoute);
  }

  /// Called when a showcase step completes. When the last step of the current
  /// route is completed, the tour advances to the next route or finishes.
  void onStepComplete(int index, GlobalKey key) {
    if (!_running) return;
    final steps = _stepsByRoute[activeRoute] ?? const <TourStep>[];
    final visibleSteps = steps
        .where((s) => s.key.currentContext != null)
        .toList();
    if (visibleSteps.isEmpty) {
      _advance();
      return;
    }
    final visibleIndex = visibleSteps.indexWhere((s) => s.key == key);
    if (visibleIndex < 0) return;
    if (visibleIndex < visibleSteps.length - 1) return;
    _advance();
  }

  /// Jumps directly to the tour route at [index]. Used for tests and for
  /// jumping to a specific screen during the tour.
  void goToRoute(int index) {
    if (index < 0 || index >= tourRoutes.length) return;
    _index = index;
    if (_running) {
      _goTo(activeRoute);
    }
  }

  /// Stops the tour (skip). Does NOT mark as completed, so it can be retriggered.
  void skip() {
    _running = false;
  }

  /// Finishes the tour: navigates to Home and marks the tour as done.
  Future<void> finish() async {
    _running = false;
    final router = ref.read(routerProvider);
    router.go('/home');
    await ref.read(settingsRepositoryProvider).markTourDone(true);
  }

  /// Resets the tour so it can be shown again.
  Future<void> reset() async {
    _running = false;
    _index = 0;
    await ref.read(settingsRepositoryProvider).markTourDone(false);
  }

  void _goTo(String route) {
    // Always navigate; the destination screen's post-frame callback will
    // call `registerSteps`, which then triggers `_runRouteSteps` with the
    // screen's current (fresh) GlobalKeys. Triggering here would use stale
    // keys from a previous instance of the same route.
    ref.read(routerProvider).go(route);
  }

  void _runRouteSteps(String route) {
    final steps = _stepsByRoute[route] ?? const <TourStep>[];
    if (steps.isEmpty) return;
    final visibleKeys = steps
        .map((s) => s.key)
        .where((k) => k.currentContext != null)
        .toList();
    if (visibleKeys.isEmpty) {
      // Targets may not be mounted yet (post-frame race). Retry shortly.
      if (_running) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (_running) _runRouteSteps(route);
        });
      } else {
        _advance();
      }
      return;
    }
    final firstKey = visibleKeys.first;
    final context = firstKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      ).then((_) {
        _startShowCaseAfterScroll(visibleKeys);
      });
    } else {
      _startShowCaseAfterScroll(visibleKeys);
    }
  }

  void _startShowCaseAfterScroll(List<GlobalKey> keys) {
    if (!_running) return;
    final service = ref.read(showcaseServiceProvider);
    service.startShowCase(keys);
  }

  /// Advances the tour to the next route regardless of which step triggered
  /// the advancement. Called when the current route has no visible steps to
  /// showcase.
  void _advance() {
    if (!_running) return;
    if (_index >= tourRoutes.length - 1) {
      finish();
    } else {
      _index++;
      _goTo(activeRoute);
    }
  }
}

final tourControllerProvider =
    AsyncNotifierProvider<TourController, void>(TourController.new);
