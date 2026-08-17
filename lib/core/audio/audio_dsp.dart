import 'dart:math' as math;

/// On-device audio DSP pipeline mirroring the backend preprocessing:
///   raw PCM (WAV) -> 16 kHz -> log-mel spectrogram -> resize 224x224x3
///
/// Implemented in pure Dart (no native deps) so it runs fully offline.
class AudioDsp {
  AudioDsp._();

  static const int targetSr = 16000;
  static const int nFft = 400;
  static const int hopLength = 160;
  static const int nMels = 128;
  static const int imageSize = 224;

  /// Reads a WAV file's mono samples as normalized float list (-1..1).
  /// Supports PCM16 (and PCM8/PCM32 heuristically). Throws on unsupported data.
  static List<double> decodeWav(List<int> bytes) {
    if (bytes.length < 44) throw FormatException('Not a WAV file');
    // "RIFF" / "WAVE"
    if (String.fromCharCodes(bytes.sublist(0, 4)) != 'RIFF') {
      throw FormatException('Missing RIFF header');
    }
    final numChannels = _le16(bytes, 22);
    final bitsPerSample = _le16(bytes, 34);

    // Find "data" chunk robustly.
    var offset = 12;
    var dataStart = -1;
    var dataLen = 0;
    while (offset + 8 <= bytes.length) {
      final id = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final size = _le32(bytes, offset + 4);
      if (id == 'data') {
        dataStart = offset + 8;
        dataLen = size;
        break;
      }
      offset += 8 + size + (size.isOdd ? 1 : 0);
    }
    if (dataStart < 0) throw FormatException('No data chunk');
    final end = math.min(bytes.length, dataStart + dataLen);

    final out = <double>[];
    if (bitsPerSample == 16) {
      for (var i = dataStart; i + 1 < end; i += 2 * numChannels) {
        final s = _le16(bytes, i);
        out.add(s / 32768.0);
      }
    } else if (bitsPerSample == 32) {
      for (var i = dataStart; i + 3 < end; i += 4 * numChannels) {
        final s = _le32(bytes, i);
        out.add(s / 2147483648.0);
      }
    } else if (bitsPerSample == 8) {
      for (var i = dataStart; i < end; i += numChannels) {
        final s = bytes[i] - 128;
        out.add(s / 128.0);
      }
    } else {
      throw FormatException('Unsupported bits per sample: $bitsPerSample');
    }
    return out;
  }

  static int _le16(List<int> b, int i) => b[i] | (b[i + 1] << 8);
  static int _le32(List<int> b, int i) =>
      b[i] | (b[i + 1] << 8) | (b[i + 2] << 16) | (b[i + 3] << 24);

  /// Linear resample to [targetSr].
  static List<double> resample(List<double> samples, int fromSr, int toSr) {
    if (fromSr == toSr) return samples;
    final ratio = toSr / fromSr;
    final n = (samples.length * ratio).round();
    final out = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      final pos = i / ratio;
      final i0 = pos.floor();
      final i1 = math.min(i0 + 1, samples.length - 1);
      final frac = pos - i0;
      out[i] = samples[i0] * (1 - frac) + samples[i1] * frac;
    }
    return out;
  }

  static List<double> normalize(List<double> samples) {
    var peak = 0.0;
    for (final s in samples) {
      final a = s.abs();
      if (a > peak) peak = a;
    }
    if (peak <= 0) return samples;
    final inv = 1.0 / peak;
    return [for (final s in samples) s * inv];
  }

  // ---------------------------------------------------------------- mel fbank
  static List<List<double>> _melFilterbank() {
    final nFreq = nFft ~/ 2 + 1;
    final fMax = targetSr / 2.0;
    final fMin = 0.0;
    double hzToMel(double hz) => 2595.0 * math.log(1.0 + hz / 700.0) / math.ln10;
    final melMin = hzToMel(fMin);
    final melMax = hzToMel(fMax);
    final melPoints = List.generate(nMels + 2, (m) {
      final t = m / (nMels + 1);
      return melMin + t * (melMax - melMin);
    });
    final hzPoints = [for (final m in melPoints) 700.0 * (math.pow(10, m / 2595.0) - 1.0)];
    final bins = [for (final hz in hzPoints) (hz * (nFft + 1) / targetSr).floor()];

    final fbank = List.generate(nMels, (_) => List<double>.filled(nFreq, 0));
    for (var m = 1; m <= nMels; m++) {
      final fMinus = bins[m - 1].clamp(0, nFreq - 1);
      final fMid = bins[m].clamp(0, nFreq - 1);
      final fPlus = bins[m + 1].clamp(0, nFreq - 1);
      for (var k = fMinus; k < fMid; k++) {
        fbank[m - 1][k] = (k - fMinus) / (fMid - fMinus);
      }
      for (var k = fMid; k < fPlus; k++) {
        fbank[m - 1][k] = (fPlus - k) / (fPlus - fMid);
      }
      final denom = hzPoints[m + 1] - hzPoints[m - 1];
      final enorm = 2.0 / (denom == 0 ? 1e-10 : denom);
      for (var k = 0; k < nFreq; k++) {
        fbank[m - 1][k] *= enorm;
      }
    }
    return fbank;
  }

  // ------------------------------------------------------------------ STFT
  static void _radix2Fft(List<double> re, List<double> im) {
    final n = re.length;
    if (n < 2) return;
    // bit-reversal
    var j = 0;
    for (var i = 0; i < n - 1; i++) {
      if (i < j) {
        final tr = re[i]; re[i] = re[j]; re[j] = tr;
        final ti = im[i]; im[i] = im[j]; im[j] = ti;
      }
      var m = n >> 1;
      while (j >= m) {
        j -= m;
        m >>= 1;
      }
      j += m;
    }
    for (var len = 2; len <= n; len <<= 1) {
      final ang = -2 * math.pi / len;
      final wRe = math.cos(ang);
      final wIm = math.sin(ang);
      for (var i = 0; i < n; i += len) {
        var curRe = 1.0, curIm = 0.0;
        for (var k = 0; k < len ~/ 2; k++) {
          final aRe = re[i + k];
          final aIm = im[i + k];
          final bRe = re[i + k + len ~/ 2] * curRe - im[i + k + len ~/ 2] * curIm;
          final bIm = re[i + k + len ~/ 2] * curIm + im[i + k + len ~/ 2] * curRe;
          re[i + k] = aRe + bRe;
          im[i + k] = aIm + bIm;
          re[i + k + len ~/ 2] = aRe - bRe;
          im[i + k + len ~/ 2] = aIm - bIm;
          final nRe = curRe * wRe - curIm * wIm;
          curIm = curRe * wIm + curIm * wRe;
          curRe = nRe;
        }
      }
    }
  }

  static List<List<double>> _stftPower(List<double> samples) {
    final window = List<double>.generate(nFft, (i) {
      return 0.5 - 0.5 * math.cos(2 * math.pi * i / (nFft - 1));
    });
    final frames = <List<double>>[];
    var start = 0;
    while (start + nFft <= samples.length) {
      frames.add(samples.sublist(start, start + nFft));
      start += hopLength;
    }
    if (frames.isEmpty) {
      // Pad to one frame.
      frames.add(List<double>.filled(nFft, 0));
    }
    final nFreq = nFft ~/ 2 + 1;
    final power = List.generate(frames.length, (_) => List<double>.filled(nFreq, 0));
    for (var f = 0; f < frames.length; f++) {
      final re = List<double>.generate(nFft, (i) => frames[f][i] * window[i]);
      final im = List<double>.filled(nFft, 0);
      _radix2Fft(re, im);
      for (var k = 0; k < nFreq; k++) {
        power[f][k] = re[k] * re[k] + im[k] * im[k];
      }
    }
    return power;
  }

  static List<List<double>> _logMel(List<List<double>> power, List<List<double>> fbank) {
    final nFrames = power.length;
    final out = List.generate(nMels, (_) => List<double>.filled(nFrames, 0));
    for (var f = 0; f < nFrames; f++) {
      for (var m = 0; m < nMels; m++) {
        var acc = 0.0;
        final row = fbank[m];
        final frame = power[f];
        for (var k = 0; k < row.length; k++) {
          acc += row[k] * frame[k];
        }
        out[m][f] = math.log(acc + 1e-10);
      }
    }
    return out;
  }

  static List<List<double>> _resizeSquare(List<List<double>> spec, int size) {
    final rows = spec.length;
    final cols = spec.isEmpty ? 0 : spec[0].length;
    final out = List.generate(size, (i) => List<double>.filled(size, 0));
    for (var i = 0; i < size; i++) {
      final sy = (rows <= 1) ? 0 : (i * (rows - 1) / (size - 1)).round();
      final sy0 = sy.clamp(0, rows - 1);
      for (var j = 0; j < size; j++) {
        final sx = (cols <= 1) ? 0 : (j * (cols - 1) / (size - 1)).round();
        final sx0 = sx.clamp(0, cols - 1);
        out[i][j] = spec[sy0][sx0];
      }
    }
    return out;
  }

  /// Returns the RGB input tensor for MobileNetV2: a flat list of length
  /// 224*224*3 with values in [0,1] (channel duplicated from the log-mel).
  static List<double> samplesToModelInput(List<double> samples) {
    final s16 = normalize(resample(samples, targetSr, targetSr));
    final power = _stftPower(s16);
    final fbank = _melFilterbank();
    final logMel = _logMel(power, fbank);
    final square = _resizeSquare(logMel, imageSize);

    var vmin = double.infinity, vmax = -double.infinity;
    for (final row in square) {
      for (final v in row) {
        if (v < vmin) vmin = v;
        if (v > vmax) vmax = v;
      }
    }
    final range = (vmax - vmin) == 0 ? 1e-9 : (vmax - vmin);
    final norm = List<double>.filled(imageSize * imageSize * 3, 0);
    var idx = 0;
    for (var i = 0; i < imageSize; i++) {
      for (var j = 0; j < imageSize; j++) {
        final v = (square[i][j] - vmin) / range;
        norm[idx] = v;
        norm[idx + 1] = v;
        norm[idx + 2] = v;
        idx += 3;
      }
    }
    return norm;
  }

  /// Downsampled (40x40) log-mel grid for the Flutter spectrogram widget.
  static List<List<double>> spectrogramGrid(List<double> samples) {
    final s16 = normalize(resample(samples, targetSr, targetSr));
    final power = _stftPower(s16);
    final fbank = _melFilterbank();
    final logMel = _logMel(power, fbank);
    return _resizeSquare(logMel, 40);
  }
}
