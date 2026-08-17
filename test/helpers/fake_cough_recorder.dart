import 'package:neumoi_d/core/audio/cough_recorder.dart';

/// A [CoughRecorder] that never touches platform channels, for widget tests.
class FakeCoughRecorder extends CoughRecorder {
  bool supported = true;

  @override
  Future<bool> get isSupported async => supported;

  @override
  Future<void> start({int sampleRate = 16000}) async {}

  @override
  Future<String?> stop() async => null;

  @override
  Future<void> cancel() async {}
}
