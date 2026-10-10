import 'dart:math' as math;
import 'dart:ui';

import '../sky_frame.dart';
import '../sky_palette.dart';

class _Puff {
  const _Puff(this.x, this.y, this.r, this.shade);

  // Offsets inside a cloud, in units of the cloud's size.
  final double x;
  final double y;
  final double r;
  final double shade; // 0 lit top .. 1 shaded underside
}

class _Cloud {
  const _Cloud(this.x, this.y, this.size, this.speed, this.puffs);

  final double x; // 0..1 of the width, at time zero
  final double y; // 0..1 of the horizon height
  final double size; // fraction of the width
  final double speed; // relative drift speed
  final List<_Puff> puffs;
}

/// Soft clouds made of overlapping blurred puffs. How many there are and how
/// dark they look follow the cloud cover; they drift with the wind. Their
/// layout is fixed, so only the drift changes between frames.
class Clouds {
  Clouds({int seed = 11, int count = 14}) {
    final rnd = math.Random(seed);
    _clouds = List.generate(count, (_) {
      final puffs = List.generate(7, (i) {
        final t = i / 6 - 0.5;
        return _Puff(
          t * 1.1 + (rnd.nextDouble() - 0.5) * 0.2,
          (rnd.nextDouble() - 0.5) * 0.12 - (0.5 - t.abs()) * 0.12,
          0.14 + (0.5 - t.abs()) * 0.22 + rnd.nextDouble() * 0.06,
          rnd.nextDouble(),
        );
      });
      return _Cloud(
        rnd.nextDouble(),
        0.08 + rnd.nextDouble() * 0.62,
        0.28 + rnd.nextDouble() * 0.3,
        0.6 + rnd.nextDouble() * 0.8,
        puffs,
      );
    });
  }

  late final List<_Cloud> _clouds;

  void paint(Canvas canvas, SkyFrame f) {
    final cover = (f.inputs.cloudCoverPct / 100).clamp(0.0, 1.0);
    if (cover < 0.02) return;
    final e = f.inputs.sunElevationDeg;
    final lit = cloudLit(e);
    final shade = cloudShade(e, f.overcast);
    final wind = (0.4 + f.inputs.windSpeedKmh / 25).clamp(0.4, 3.0);
    final w = f.size.width;

    // Fewer clouds when the cover is light, all of them when it is overcast.
    final visible = (_clouds.length * (0.15 + 0.85 * cover)).ceil();
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    for (var i = 0; i < visible; i++) {
      final c = _clouds[i];
      final size = w * c.size * (0.8 + 0.5 * cover);
      // Drifts to the right and wraps around with room for the cloud's width.
      final span = w + size * 2;
      final x =
          ((c.x * span + f.timeMs * 0.004 * wind * c.speed) % span) - size;
      final y = f.horizonY * c.y;
      for (final p in c.puffs) {
        final color = mix(
          lit,
          shade,
          (p.shade * 0.6 + 0.4 * f.overcast).clamp(0.0, 1.0),
        );
        paint.color = color.withValues(
          alpha: (0.55 + 0.4 * cover).clamp(0.0, 0.95),
        );
        canvas.drawCircle(
          Offset(x + p.x * size, y + p.y * size),
          p.r * size,
          paint,
        );
      }
    }
  }
}
