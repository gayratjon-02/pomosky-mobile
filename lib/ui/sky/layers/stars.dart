import 'dart:math' as math;
import 'dart:ui';

import '../sky_frame.dart';
import '../sky_palette.dart';

class _Star {
  const _Star(
    this.x,
    this.y,
    this.r,
    this.a,
    this.tint,
    this.twinkle,
    this.phase,
    this.speed,
  );

  // x and y are fractions of the width and of the horizon height.
  final double x;
  final double y;
  final double r;
  final double a;
  final Color tint;
  final bool twinkle;
  final double phase;
  final double speed;
}

const _tints = [Color(0xFFFFFFFF), Color(0xFFCDE1FF), Color(0xFFFFF0D7)];

/// A fixed field of stars (the same every launch); the brightest few twinkle.
class StarField {
  StarField({int seed = 7, int count = 220}) {
    final rnd = math.Random(seed);
    _stars = List.generate(count, (_) {
      final bright = rnd.nextDouble() > 0.93;
      return _Star(
        rnd.nextDouble(),
        rnd.nextDouble(),
        bright ? 1.1 + rnd.nextDouble() * 0.9 : 0.4 + rnd.nextDouble() * 0.7,
        bright ? 0.85 + rnd.nextDouble() * 0.15 : 0.35 + rnd.nextDouble() * 0.5,
        _tints[rnd.nextInt(_tints.length)],
        bright,
        rnd.nextDouble() * math.pi * 2,
        0.8 + rnd.nextDouble() * 1.6,
      );
    });
  }

  late final List<_Star> _stars;

  void paint(Canvas canvas, SkyFrame f) {
    final night = 1 - smoothstep(-16, -4, f.inputs.sunElevationDeg);
    final alpha = (night * (1 - 0.92 * f.overcast)).clamp(0.0, 1.0);
    if (alpha < 0.01) return;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, f.size.width, f.horizonY));
    final paint = Paint()..isAntiAlias = true;
    for (final s in _stars) {
      final flicker = s.twinkle
          ? 0.65 + 0.35 * math.sin(f.timeMs * 0.001 * s.speed + s.phase)
          : 1.0;
      paint.color = s.tint.withValues(
        alpha: (s.a * flicker * alpha).clamp(0.0, 1.0),
      );
      canvas.drawCircle(
        Offset(s.x * f.size.width, s.y * f.horizonY),
        s.r,
        paint,
      );
    }
    canvas.restore();
  }
}
