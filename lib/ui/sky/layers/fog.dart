import 'dart:ui';

import '../sky_frame.dart';
import '../sky_palette.dart';

/// A pale veil that thickens towards the ground. The strength is the fog
/// density from the weather.
void paintFog(Canvas canvas, SkyFrame f) {
  final density = f.inputs.fogDensity.clamp(0.0, 1.0);
  if (density < 0.02) return;
  final base = cloudLit(f.inputs.sunElevationDeg);
  final dim = mix(base, const Color(0xFF8A94AA), 0.4);
  final shader = Gradient.linear(
    Offset(0, f.size.height * 0.15),
    Offset(0, f.size.height),
    [
      dim.withValues(alpha: 0.1 * density),
      dim.withValues(alpha: 0.7 * density),
    ],
  );
  canvas.drawRect(Offset.zero & f.size, Paint()..shader = shader);
}
