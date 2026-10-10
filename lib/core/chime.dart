import 'dart:math' as math;
import 'dart:typed_data';

/// Synthesises the end-of-phase signal as a 16-bit mono WAV file, so the app
/// ships no audio asset. It is a bright two-note bell (G5 then C6 with a soft
/// overtone) repeated every two seconds, [repeats] times: about six seconds,
/// hard to miss. Mirrors the website's `chime()`.
Uint8List synthesizeChime({
  int sampleRate = 22050,
  int repeats = 3,
  double repeatEvery = 2.0,
}) {
  final total = (repeats * repeatEvery * sampleRate).round();
  final samples = Float64List(total);

  void note(
    double freq,
    double at,
    double dur,
    double gain, {
    bool triangle = false,
  }) {
    final start = (at * sampleRate).round();
    final length = (dur * sampleRate).round();
    for (var i = 0; i < length && start + i < total; i++) {
      final t = i / sampleRate;
      // A quick attack and an exponential decay, like a struck bell.
      final attack = math.min(1.0, t / 0.012);
      final decay = math.exp(-t * 4.2 / dur);
      final phase = 2 * math.pi * freq * t;
      final wave = triangle
          ? (2 / math.pi) * math.asin(math.sin(phase))
          : math.sin(phase);
      samples[start + i] += wave * gain * attack * decay;
    }
  }

  for (var r = 0; r < repeats; r++) {
    final at = r * repeatEvery;
    note(784, at, 1.4, 0.3);
    note(1046.5, at + 0.25, 1.5, 0.3);
    note(1568, at + 0.25, 0.9, 0.08, triangle: true);
  }

  final pcm = ByteData(total * 2);
  for (var i = 0; i < total; i++) {
    final v = (samples[i].clamp(-1.0, 1.0) * 32767).round();
    pcm.setInt16(i * 2, v, Endian.little);
  }
  return _wav(pcm.buffer.asUint8List(), sampleRate);
}

Uint8List _wav(Uint8List pcm, int sampleRate) {
  final header = ByteData(44);
  void ascii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      header.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  header.setUint32(4, 36 + pcm.length, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  header.setUint32(16, 16, Endian.little); // PCM chunk size
  header.setUint16(20, 1, Endian.little); // PCM
  header.setUint16(22, 1, Endian.little); // mono
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, sampleRate * 2, Endian.little); // byte rate
  header.setUint16(32, 2, Endian.little); // block align
  header.setUint16(34, 16, Endian.little); // bits per sample
  ascii(36, 'data');
  header.setUint32(40, pcm.length, Endian.little);

  final out = Uint8List(44 + pcm.length)
    ..setRange(0, 44, header.buffer.asUint8List())
    ..setRange(44, 44 + pcm.length, pcm);
  return out;
}
