import 'dart:math' as math;
import 'dart:ui';

import '../sky_frame.dart';

/// Flashes of lightning during a thunderstorm. A flash is a double pulse that
/// starts at a pseudo-random moment derived from the time, so no state is kept.
void paintLightning(Canvas canvas, SkyFrame f) {
  if (!f.inputs.thunder) return;
  // One slot every ~6 seconds; each slot has a flash at a fixed odd offset.
  const slotMs = 6000.0;
  final slot = (f.timeMs / slotMs).floor();
  final start = _hash(slot) * (slotMs - 1200);
  final t = f.timeMs - slot * slotMs - start;
  if (t < 0 || t > 600) return;

  // Two quick pulses with a decay.
  final pulse = math.max(
    math.exp(-t / 70),
    t > 180 ? 0.7 * math.exp(-(t - 180) / 90) : 0,
  );
  canvas.drawRect(
    Offset.zero & f.size,
    Paint()
      ..color = const Color(
        0xFFDCE6FF,
      ).withValues(alpha: (0.45 * pulse).clamp(0.0, 1.0)),
  );
}

// A small deterministic hash to 0..1.
double _hash(int n) {
  final x = math.sin(n * 12.9898 + 78.233) * 43758.5453;
  return x - x.floorToDouble();
}
