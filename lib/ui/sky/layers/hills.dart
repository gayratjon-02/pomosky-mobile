import 'dart:math' as math;
import 'dart:ui';

import '../sky_frame.dart';
import '../sky_palette.dart';

class _Wave {
  const _Wave(this.freq, this.phase, this.weight);

  final double freq;
  final double phase;
  final double weight;
}

class _Ridge {
  const _Ridge(this.base, this.amp, this.waves);

  final double base; // baseline, as a fraction of the canvas height
  final double amp; // height of the hills, as a fraction of the canvas height
  final List<_Wave> waves;

  double at(double u) {
    var total = 0.0;
    var weight = 0.0;
    for (final w in waves) {
      total += math.sin(u * math.pi * 2 * w.freq + w.phase) * w.weight;
      weight += w.weight;
    }
    return 0.5 + 0.5 * total / weight; // 0..1
  }
}

/// Layered hills along the horizon. Their colour follows the sky and gets
/// darker towards the front. The shapes are fixed, so the horizon never moves.
class Hills {
  Hills({int seed = 3}) {
    final rnd = math.Random(seed);
    _Ridge ridge(double base, double amp) => _Ridge(base, amp, [
      _Wave(1.1 + rnd.nextDouble() * 0.8, rnd.nextDouble() * 6.28, 1),
      _Wave(2.7 + rnd.nextDouble() * 1.4, rnd.nextDouble() * 6.28, 0.55),
      _Wave(6.2 + rnd.nextDouble() * 3, rnd.nextDouble() * 6.28, 0.22),
    ]);
    _ridges = [ridge(0.0, 0.07), ridge(0.02, 0.06), ridge(0.045, 0.05)];
  }

  late final List<_Ridge> _ridges;

  void paint(Canvas canvas, SkyFrame f) {
    final w = f.size.width;
    final h = f.size.height;
    final e = f.inputs.sunElevationDeg;
    final step = math.max(6.0, (w / 140).roundToDouble());
    final skyBottom = skyGradient(e, f.overcast).bottom;

    for (var i = 0; i < _ridges.length; i++) {
      final ridge = _ridges[i];
      final depth = i / (_ridges.length - 1);
      // Hills pick up a little of the sky's colour, less so in the front.
      final tinted = mix(horizonColor(e, depth), skyBottom, 0.22 * (1 - depth));
      final baseY = f.horizonY + ridge.base * h;

      final path = Path()..moveTo(0, h);
      for (var x = 0.0; x <= w + step; x += step) {
        path.lineTo(x, baseY - ridge.amp * h * ridge.at(x / w));
      }
      path
        ..lineTo(w, h)
        ..close();

      final top = baseY - ridge.amp * h;
      canvas.drawPath(
        path,
        Paint()
          ..shader = Gradient.linear(Offset(0, top), Offset(0, h), [
            tinted,
            mix(tinted, const Color(0xFF02030A), 0.55),
          ]),
      );
    }
  }
}
