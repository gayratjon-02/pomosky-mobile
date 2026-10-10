import 'dart:math' as math;
import 'dart:ui';

import '../sky_frame.dart';
import '../sky_inputs.dart';
import '../sky_palette.dart';

/// The sun disc with a soft bloom. It grows, reddens and fades near the
/// horizon and is veiled by clouds.
void paintSun(Canvas canvas, SkyFrame f) {
  final e = f.inputs.sunElevationDeg;
  final visible = smoothstep(-8, 1, e);
  if (visible < 0.01) return;

  final c = skyPoint(f.size, f.horizonY, f.inputs.sunAzimuthDeg, e);
  final base = math.min(f.size.width, f.size.height) * 0.04;
  final r = base * (1 + 0.4 * (1 - smoothstep(0, 25, e)));
  final color = sunColor(e);
  final clear = (1 - f.overcast * 0.85).clamp(0.0, 1.0);
  final a = visible * clear;

  final screen = Paint()..blendMode = BlendMode.screen;

  final bloomR = r * 16;
  screen.shader = Gradient.radial(
    c,
    bloomR,
    [
      color.withValues(alpha: 0.55 * a),
      color.withValues(alpha: 0.22 * a),
      color.withValues(alpha: 0),
    ],
    const [0, 0.25, 1],
  );
  canvas.drawCircle(c, bloomR, screen);

  screen.shader = Gradient.radial(
    c,
    r * 3.2,
    [color.withValues(alpha: 0.8 * a), color.withValues(alpha: 0)],
    const [0.6 / 3.2, 1],
  );
  canvas.drawCircle(c, r * 3.2, screen);

  final disc = Paint()
    ..shader = Gradient.radial(
      c,
      r,
      [
        const Color(0xFFFFFFFF).withValues(alpha: a),
        color.withValues(alpha: a),
        color.withValues(alpha: 0.9 * a),
      ],
      const [0, 0.7, 1],
    );
  canvas.drawCircle(c, r, disc);
}
