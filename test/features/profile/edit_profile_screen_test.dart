import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neumoi_d/core/connectivity/connectivity_service.dart';
import 'package:neumoi_d/core/sync/sync_queue.dart';
import 'package:neumoi_d/core/theme/app_theme.dart';
import 'package:neumoi_d/data/mock/mock_repositories.dart';
import 'package:neumoi_d/features/profile/screens/edit_profile_screen.dart';
import 'package:neumoi_d/state/app_providers.dart';

class _FakeConnectivity implements ConnectivityService {
  final _controller = StreamController<bool>.broadcast();
  @override
  Stream<bool> get isOnline => _controller.stream;
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('edit profile updates the stored profile', (tester) async {
    final container = ProviderContainer(overrides: [
      profileRepositoryProvider.overrideWithValue(MockProfileRepository()),
      settingsRepositoryProvider.overrideWithValue(MockSettingsRepository()),
      connectivityServiceProvider.overrideWithValue(_FakeConnectivity()),
      syncQueueProvider.overrideWithValue(SyncQueue()),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildLightTheme(), home: const EditProfileScreen()),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Ibu Ratna');
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();

    final profile = await container.read(profileProvider.future);
    expect(profile.name, 'Ibu Ratna');
  });
}