import 'dart:math' as math;
import 'dart:ui';

import '../sky_frame.dart';

class _Drop {
  const _Drop(this.x, this.y, this.len, this.speed, this.alpha);

  final double x; // 0..1
  final double y; // 0..1, phase of the fall
  final double len; // fraction of the height
  final double speed;
  final double alpha;
}

/// Rain streaks. The count follows the rainfall rate, the slant follows the
/// wind. Positions come from the time, so a frame needs no stored state.
class Rain {
  Rain({int seed = 5, int count = 260}) {
    final rnd = math.Random(seed);
    _drops = List.generate(
      count,
      (_) => _Drop(
        rnd.nextDouble(),
        rnd.nextDouble(),
        0.025 + rnd.nextDouble() * 0.04,
        0.9 + rnd.nextDouble() * 0.7,
        0.25 + rnd.nextDouble() * 0.4,
      ),
    );
  }

  late final List<_Drop> _drops;

  void paint(Canvas canvas, SkyFrame f) {
    final rate = f.inputs.precipitationMmh;
    if (rate <= 0.02) return;
    final shown = (_drops.length * (0.15 + 0.85 * (rate / 8).clamp(0.0, 1.0)))
        .round();
    final w = f.size.width;
    final h = f.size.height;
    // Wind pushes the drops sideways: up to about 0.4 of their length.
    final slant =
        (f.inputs.windSpeedKmh / 60).clamp(0.0, 0.4) *
        (f.inputs.windDirDeg > 180 ? -1 : 1);

    final paint = Paint()
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < shown; i++) {
      final d = _drops[i];
      final fall = (d.y + f.timeMs * 0.0009 * d.speed) % 1.0;
      final y = fall * (h + d.len * h) - d.len * h;
      final len = d.len * h;
      final x = d.x * w + slant * (fall * h);
      paint.color = const Color(0xFFBFD3F2).withValues(alpha: d.alpha);
      canvas.drawLine(Offset(x, y), Offset(x + slant * len, y + len), paint);
    }
  }
}
