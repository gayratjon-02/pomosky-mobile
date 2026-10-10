import 'dart:math' as math;
import 'dart:ui';

import '../sky_frame.dart';

class _Flake {
  const _Flake(this.x, this.y, this.r, this.speed, this.sway, this.phase);

  final double x;
  final double y;
  final double r;
  final double speed;
  final double sway;
  final double phase;
}

/// Snowflakes that drift down and sway. The count follows the snowfall rate.
class Snow {
  Snow({int seed = 9, int count = 180}) {
    final rnd = math.Random(seed);
    _flakes = List.generate(
      count,
      (_) => _Flake(
        rnd.nextDouble(),
        rnd.nextDouble(),
        1.2 + rnd.nextDouble() * 2.4,
        0.5 + rnd.nextDouble() * 0.8,
        0.01 + rnd.nextDouble() * 0.025,
        rnd.nextDouble() * math.pi * 2,
      ),
    );
  }

  late final List<_Flake> _flakes;

  void paint(Canvas canvas, SkyFrame f) {
    final rate = f.inputs.snowfallCmh;
    if (rate <= 0.02) return;
    final shown = (_flakes.length * (0.2 + 0.8 * (rate / 2).clamp(0.0, 1.0)))
        .round();
    final w = f.size.width;
    final h = f.size.height;
    final drift =
        (f.inputs.windSpeedKmh / 40).clamp(0.0, 1.0) *
        (f.inputs.windDirDeg > 180 ? -1 : 1);

    final paint = Paint()..color = const Color(0xCCFFFFFF);
    for (var i = 0; i < shown; i++) {
      final s = _flakes[i];
      final t = f.timeMs * 0.0001 * s.speed;
      final fall = (s.y + t) % 1.0;
      final x =
          s.x * w +
          math.sin(f.timeMs * 0.001 * s.speed + s.phase) * s.sway * w +
          drift * fall * w * 0.2;
      canvas.drawCircle(Offset(x % w, fall * h), s.r, paint);
    }
  }
}
