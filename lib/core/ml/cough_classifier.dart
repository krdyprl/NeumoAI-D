import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../audio/audio_dsp.dart';

/// Result of a cough classification run.
class CoughResult {
  const CoughResult({
    required this.disease,
    required this.confidence,
    required this.isFromModel,
  });

  final String disease;
  final int confidence;
  final bool isFromModel;

  bool get isPneumonia => disease.toLowerCase().contains('pneumonia');
}

/// Arguments passed to the background isolate that runs TFLite inference.
class _IsolateArgs {
  const _IsolateArgs(this.wavBytes, this.modelBytes);
  final Uint8List wavBytes;
  final Uint8List modelBytes;
}

/// Top-level function that runs on the background isolate. Decodes WAV,
/// computes the log-mel spectrogram + resize, creates a TFLite Interpreter
/// from the model bytes, and runs the int8-quantized inference.
Future<CoughResult> _classifyInIsolate(_IsolateArgs args) async {
  final samples = AudioDsp.decodeWav(args.wavBytes);
  final input = AudioDsp.samplesToModelInput(samples);

  final interpreter = Interpreter.fromBuffer(args.modelBytes);
  final inputTensor = interpreter.getInputTensor(0);
  final outputTensor = interpreter.getOutputTensor(0);

  final inputType = inputTensor.type;
  final outputShape = outputTensor.shape;
  final outLen = outputShape.fold<int>(1, (a, b) => a * b);

  final TensorType type = inputType;
  Object inputBuffer;
  if (type == TensorType.int8 || type == TensorType.uint8) {
    final q = inputTensor.params;
    final scale = q.scale;
    final zero = q.zeroPoint;
    final n = input.length;
    final bytes = type == TensorType.uint8 ? Uint8List(n) : Int8List(n);
    for (var i = 0; i < n; i++) {
      final quantized = (input[i] / scale) + zero;
      bytes[i] = quantized.round().clamp(-128, 127);
    }
    inputBuffer = bytes;
  } else {
    inputBuffer = Float32List.fromList(input);
  }

  Object outputBuffer;
  if (outputTensor.type == TensorType.int8 || outputTensor.type == TensorType.uint8) {
    outputBuffer = outputTensor.type == TensorType.uint8
        ? Uint8List(outLen)
        : Int8List(outLen);
  } else {
    outputBuffer = Float32List(outLen);
  }

  interpreter.run(inputBuffer, outputBuffer);
  interpreter.close();

  double raw;
  if (outputTensor.type == TensorType.int8 || outputTensor.type == TensorType.uint8) {
    final q = outputTensor.params;
    final scale = q.scale;
    final zero = q.zeroPoint;
    final first = (outputBuffer as List<num>).isNotEmpty ? outputBuffer[0] : 0;
    raw = (first - zero) * scale;
  } else {
    raw = (outputBuffer as Float32List).isNotEmpty ? outputBuffer[0] : 0.0;
  }

  final pneumoniaProb = raw.clamp(0.0, 1.0);
  final isPneumonia = pneumoniaProb >= 0.5;
  return CoughResult(
    disease: isPneumonia ? 'Pneumonia' : 'Normal',
    confidence: (pneumoniaProb * 100).round().clamp(0, 100),
    isFromModel: true,
  );
}

/// Runs on-device cough classification with a TFLite MobileNetV2 model.
///
/// The model file `assets/models/neumoaid_pneumonia_v1.tflite` is produced by
/// the Kaggle training notebook. Until it exists, [classify] returns a
/// deterministic placeholder result so the rest of the pipeline can be tested.
class CoughClassifier {
  static const String _asset = 'assets/models/neumoaid_pneumonia_v1.tflite';

  /// Classifies decoded WAV samples. Returns [CoughResult].
  ///
  /// The TFLite inference runs on a background isolate (via `Isolate.run`) so
  /// the UI thread is never blocked, even on slow emulators. If the isolate
  /// or inference fails, a placeholder result is returned.
  ///
  /// Falls back to a placeholder (disease=Pneumonia, confidence=87) when the
  /// model is not yet bundled. Set [forceModel] to true to raise if the model
  /// is missing.
  Future<CoughResult> classify(
    List<int> wavBytes, {
    bool forceModel = false,
  }) async {
    Uint8List modelBytes;
    try {
      final data = await rootBundle.load(_asset);
      modelBytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } catch (_) {
      if (forceModel) {
        throw StateError('TFLite model not bundled: $_asset');
      }
      return const CoughResult(disease: 'Pneumonia', confidence: 87, isFromModel: false);
    }

    try {
      return await compute(_classifyInIsolate, _IsolateArgs(Uint8List.fromList(wavBytes), modelBytes))
          .timeout(const Duration(seconds: 20), onTimeout: () {
        return const CoughResult(disease: 'Pneumonia', confidence: 87, isFromModel: false);
      });
    } catch (e) {
      debugPrint('CoughClassifier error: $e');
      return const CoughResult(disease: 'Pneumonia', confidence: 87, isFromModel: false);
    }
  }

  Future<void> dispose() async {}
}

/// Reads a file into a byte list.
Future<Uint8List> readFileBytes(File file) async => file.readAsBytes();
