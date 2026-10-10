import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/core/chime.dart';

String _tag(Uint8List b, int at) => String.fromCharCodes(b.sublist(at, at + 4));

void main() {
  final wav = synthesizeChime();
  final data = ByteData.sublistView(wav);

  test('is a valid 16-bit mono PCM wav', () {
    expect(_tag(wav, 0), 'RIFF');
    expect(_tag(wav, 8), 'WAVE');
    expect(_tag(wav, 12), 'fmt ');
    expect(data.getUint16(20, Endian.little), 1); // PCM
    expect(data.getUint16(22, Endian.little), 1); // mono
    expect(data.getUint32(24, Endian.little), 22050);
    expect(data.getUint16(34, Endian.little), 16);
    expect(_tag(wav, 36), 'data');
    // The declared sizes match the actual bytes.
    expect(data.getUint32(40, Endian.little), wav.length - 44);
    expect(data.getUint32(4, Endian.little), wav.length - 8);
  });

  test('lasts about six seconds', () {
    final seconds = (wav.length - 44) / 2 / 22050;
    expect(seconds, closeTo(6, 0.01));
  });

  test('is audible but never clips', () {
    var peak = 0;
    for (var i = 44; i < wav.length; i += 2) {
      final v = data.getInt16(i, Endian.little).abs();
      if (v > peak) peak = v;
    }
    expect(peak, greaterThan(32767 * 0.2));
    expect(
      peak,
      lessThan(32767),
    ); // the sum of the notes stays below full scale
  });

  test('each repeat starts loud and the tail of the file decays', () {
    int at(double second) =>
        data.getInt16(44 + (second * 22050).round() * 2, Endian.little).abs();
    int windowPeak(double from, double to) {
      var p = 0;
      for (var s = (from * 22050).round(); s < (to * 22050).round(); s++) {
        final v = data.getInt16(44 + s * 2, Endian.little).abs();
        if (v > p) p = v;
      }
      return p;
    }

    expect(at(0), lessThan(2000)); // starts from silence (attack)
    expect(windowPeak(0.0, 0.5), greaterThan(windowPeak(1.7, 1.95)));
    expect(windowPeak(2.0, 2.5), greaterThan(windowPeak(3.7, 3.95)));
  });

  test('can be shortened for a single ring', () {
    final one = synthesizeChime(repeats: 1);
    expect((one.length - 44) / 2 / 22050, closeTo(2, 0.01));
  });
}
