import 'dart:ui';

import '../sky_frame.dart';
import '../sky_palette.dart';

/// The vertical sky gradient for the sun's elevation and the cloud cover.
void paintBackground(Canvas canvas, SkyFrame f) {
  final g = skyGradient(f.inputs.sunElevationDeg, f.overcast);
  final shader = Gradient.linear(
    Offset.zero,
    Offset(0, f.horizonY),
    [g.top, g.mid, g.bottom],
    const [0, 0.55, 1],
  );
  // The gradient ends at the horizon; the last colour continues below it so
  // the hills never reveal a gap.
  canvas.drawRect(
    Offset.zero & f.size,
    Paint()
      ..shader = shader
      ..isAntiAlias = false,
  );
}
