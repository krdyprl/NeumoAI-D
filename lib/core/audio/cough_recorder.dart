import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Wraps the `record` package to capture cough audio on-device.
class CoughRecorder {
  final AudioRecorder _recorder = AudioRecorder();

  String? _lastPath;
  bool _recording = false;

  /// Whether a recording session is currently active.
  bool get isRecording => _recording;

  /// Returns true if recording is supported on this platform.
  Future<bool> get isSupported => _recorder.hasPermission();

  /// The path of the last recorded file, or null if none recorded yet.
  String? get lastPath => _lastPath;

  Future<void> start({int sampleRate = 16000}) async {
    final dir = await getTemporaryDirectory();
    _lastPath = '${dir.path}/cough_${DateTime.now().millisecondsSinceEpoch}.wav';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 128000,
      ),
      path: _lastPath!,
    );
    _recording = true;
  }

  /// Stops recording and returns the path to the saved WAV file.
  Future<String?> stop() async {
    final path = await _recorder.stop();
    if (path != null && path.isNotEmpty) {
      _lastPath = path;
    }
    _recording = false;
    return _lastPath;
  }

  Future<void> cancel() async {
    _recording = false;
    if (await _recorder.isRecording()) {
      await _recorder.cancel();
    }
  }

  Future<void> dispose() => _recorder.dispose();
}

/// Convenience: returns the current recording file as a [File] if it exists.
File? recordingFile(String? path) =>
    path != null && path.isNotEmpty ? File(path) : null;
