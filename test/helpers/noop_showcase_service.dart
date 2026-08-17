import 'package:flutter/material.dart';
import 'package:neumoi_d/core/services/showcase_service.dart';
import 'package:neumoi_d/data/mock/mock_repositories.dart';
import 'package:showcaseview/showcaseview.dart';

/// A [ShowcaseService] that never shows any showcase and never triggers
/// showcase animations. Used in widget tests so the showcase overlay does not
/// interfere with pumpAndSettle or block interactions.
class NoopShowcaseService extends ShowcaseService {
  NoopShowcaseService() : super(MockSettingsRepository());

  @override
  Future<bool> shouldShow(String screen) async => false;

  @override
  Future<bool> isDone(String screen) async => true;

  @override
  void startShowCase(List<GlobalKey> keys) {}

  @override
  void registerGlobal({OnShowcaseStepComplete? onStepComplete, OnShowcaseSkip? onSkip}) {
    // Register a disabled ShowcaseView so `Showcase` widgets can be built
    // (they require a registered scope) without actually running any tour.
    ShowcaseView.register(enableShowcase: false);
  }
}

