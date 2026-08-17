"""Audio preprocessing matching the on-device DSP pipeline.

Pipeline (per PRD section 4-5):
  raw PCM -> resample to 16 kHz -> log-mel spectrogram -> resize to 224x224x3

Uses soundfile for decoding and scipy/numpy for DSP to keep the dependency
footprint small enough for a 1 vCPU / 1GB RAM / 3GB disk VPS.
"""
from __future__ import annotations

import io
import math

import numpy as np
import scipy.signal as sps
import soundfile as sf

TARGET_SR = 16000
N_FFT = 400
HOP_LENGTH = 160
N_MELS = 128
IMAGE_SIZE = 224


def _mel_filterbank(n_fft: int = N_FFT, sr: int = TARGET_SR,
                    n_mels: int = N_MELS) -> np.ndarray:
    """Slaney-style mel filterbank (normalized), returns (n_mels, n_freq)."""
    n_freq = n_fft // 2 + 1
    f_max = sr / 2.0
    f_min = 0.0
    mel_min = 2595.0 * math.log10(1.0 + f_min / 700.0)
    mel_max = 2595.0 * math.log10(1.0 + f_max / 700.0)
    mel_points = np.linspace(mel_min, mel_max, n_mels + 2)
    hz_points = 700.0 * (10.0 ** (mel_points / 2595.0) - 1.0)
    bins = np.floor((n_fft + 1) * hz_points / sr).astype(int)
    bins = np.clip(bins, 0, n_freq - 1)

    fbank = np.zeros((n_mels, n_freq))
    for m in range(1, n_mels + 1):
        f_m_minus = bins[m - 1]
        f_m = bins[m]
        f_m_plus = bins[m + 1]
        for k in range(f_m_minus, f_m):
            fbank[m - 1, k] = (k - f_m_minus) / (f_m - f_m_minus or 1.0)
        for k in range(f_m, f_m_plus):
            fbank[m - 1, k] = (f_m_plus - k) / (f_m_plus - f_m or 1.0)
    # Slaney normalization: normalize each filter to unit area.
    enorm = 2.0 / (hz_points[2:] - hz_points[:-2] + 1e-10)
    fbank *= enorm[:, None]
    return fbank


_FILTERBANK_CACHE: np.ndarray | None = None


def _get_filterbank() -> np.ndarray:
    global _FILTERBANK_CACHE
    if _FILTERBANK_CACHE is None:
        _FILTERBANK_CACHE = _mel_filterbank()
    return _FILTERBANK_CACHE


def read_audio(data: bytes) -> tuple[np.ndarray, int]:
    """Decode audio bytes to mono float32 samples (range -1..1) + sample rate."""
    try:
        samples, sr = sf.read(io.BytesIO(data), dtype="float32", always_2d=False)
    except Exception:
        raise ValueError("Unsupported or corrupt audio file")
    if samples.ndim > 1:
        samples = samples.mean(axis=1)
    samples = np.asarray(samples, dtype=np.float32)
    if samples.size == 0:
        raise ValueError("Empty audio")
    return samples, int(sr)


def resample_to_16k(samples: np.ndarray, sr: int) -> np.ndarray:
    if sr == TARGET_SR:
        return samples
    n_out = int(round(len(samples) * TARGET_SR / sr))
    return sps.resample_poly(samples, TARGET_SR, sr, axis=0).astype(np.float32)


def normalize(samples: np.ndarray) -> np.ndarray:
    peak = float(np.max(np.abs(samples))) or 1.0
    return (samples / peak).astype(np.float32)


def log_mel_spectrogram(samples: np.ndarray) -> np.ndarray:
    """Return log-mel spectrogram of shape (n_mels, n_frames)."""
    _, _, stft = sps.stft(
        samples, fs=TARGET_SR, nperseg=N_FFT, noverlap=N_FFT - HOP_LENGTH,
        window="hann", boundary=None, padded=False)
    power = np.abs(stft) ** 2.0
    mel = _get_filterbank() @ power
    log_mel = np.log(mel + 1e-10)
    return log_mel


def resize_to_square(spec: np.ndarray, size: int = IMAGE_SIZE) -> np.ndarray:
    """Pad/crop + resample the (mel, time) spectrogram to (size, size)."""
    if spec.ndim != 2:
        raise ValueError("spectrogram must be 2D")
    from scipy.ndimage import zoom
    # Zoom to exactly (size, size).
    zoom_y = size / spec.shape[0]
    zoom_x = size / spec.shape[1]
    resized = zoom(spec, (zoom_y, zoom_x), order=1)
    return np.asarray(resized, dtype=np.float32)


def samples_to_model_input(samples: np.ndarray) -> np.ndarray:
    """Full pipeline: resample -> normalize -> log-mel -> (1,224,224,3) float32."""
    samples = resample_to_16k(samples, TARGET_SR)
    samples = normalize(samples)
    log_mel = log_mel_spectrogram(samples)
    square = resize_to_square(log_mel)
    # Normalize to [0,1].
    vmin, vmax = float(square.min()), float(square.max())
    if vmax - vmin > 1e-9:
        square = (square - vmin) / (vmax - vmin)
    # Duplicate channel 1 -> 3 (MobileNetV2 expects RGB-ish 224x224x3).
    rgb = np.stack([square, square, square], axis=-1)  # (224,224,3)
    return rgb[None, ...].astype(np.float32)


def spectrogram_for_display(samples: np.ndarray) -> list[list[float]]:
    """Downsampled log-mel grid for the Flutter spectrogram widget."""
    log_mel = log_mel_spectrogram(samples)
    small = resize_to_square(log_mel, size=40)
    return [[float(v) for v in row] for row in small]
