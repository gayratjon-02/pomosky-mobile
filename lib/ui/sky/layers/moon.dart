import 'dart:math' as math;
import 'dart:ui';

import '../sky_frame.dart';
import '../sky_inputs.dart';
import '../sky_palette.dart';

/// The moon with its real phase. The lit part is a half disc on one side plus
/// or minus half of an ellipse (the terminator). Waxing moons are lit on the
/// right.
void paintMoon(Canvas canvas, SkyFrame f) {
  final i = f.inputs;
  final visible = smoothstep(-6, 3, i.moonElevationDeg);
  // Faint in daylight, bright at night, hidden behind thick clouds.
  final dim = 1 - 0.85 * smoothstep(-8, 12, i.sunElevationDeg);
  final alpha = (visible * dim * (1 - 0.9 * f.overcast)).clamp(0.0, 1.0);
  if (alpha < 0.01) return;

  final c = skyPoint(f.size, f.horizonY, i.moonAzimuthDeg, i.moonElevationDeg);
  final r = math.min(f.size.width, f.size.height) * 0.03;
  final waxing = i.moonPhase < 0.5;
  final k = i.moonFraction.clamp(0.0, 1.0);

  canvas.drawCircle(
    c,
    r * 7,
    Paint()
      ..shader = Gradient.radial(
        c,
        r * 7,
        [
          const Color(
            0xFFBECDFF,
          ).withValues(alpha: 0.28 * alpha * (0.4 + 0.6 * k)),
          const Color(0xFFBECDFF).withValues(alpha: 0),
        ],
        const [0.8 / 7, 1],
      ),
  );

  // The dark side stays faintly visible (earthshine).
  canvas.drawCircle(
    c,
    r,
    Paint()..color = const Color(0xFF586490).withValues(alpha: 0.5 * alpha),
  );

  canvas.save();
  canvas.translate(c.dx, c.dy);
  if (!waxing) canvas.scale(-1, 1);
  final terminator = r * (1 - 2 * k).abs();
  final limb = Rect.fromCircle(center: Offset.zero, radius: r);
  final edge = Rect.fromCenter(
    center: Offset.zero,
    width: terminator * 2,
    height: r * 2,
  );

  final lit = Path()..arcTo(limb, -math.pi / 2, math.pi, true); // right half
  if (k < 0.5) {
    // Crescent: come back along the terminator ellipse.
    lit.arcTo(edge, math.pi / 2, -math.pi, false);
  } else {
    // Gibbous: bulge past the middle.
    lit.arcTo(edge, math.pi / 2, math.pi, false);
  }
  lit.close();

  canvas.drawPath(
    lit,
    Paint()
      ..shader = Gradient.linear(Offset(-r, -r), Offset(r, r), [
        const Color(0xFFFAFAFF).withValues(alpha: alpha),
        const Color(0xFFD6DEF4).withValues(alpha: alpha),
      ]),
  );
  canvas.restore();
}
