import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'layers/background.dart';
import 'layers/hills.dart';
import 'layers/moon.dart';
import 'layers/stars.dart';
import 'layers/sun.dart';
import 'sky_frame.dart';
import 'sky_inputs.dart';

/// Draws the whole sky. [time] is repainted on every tick; the layers are
/// created once and reused.
class SkyPainter extends CustomPainter {
  SkyPainter({
    required this.inputs,
    required this.time,
    required this.stars,
    required this.hills,
  }) : super(repaint: time);

  final SkyInputs inputs;
  final ValueListenable<double> time;
  final StarField stars;
  final Hills hills;

  @override
  void paint(Canvas canvas, Size size) {
    final f = SkyFrame(size: size, inputs: inputs, timeMs: time.value);
    paintBackground(canvas, f);
    stars.paint(canvas, f);
    paintMoon(canvas, f);
    paintSun(canvas, f);
    hills.paint(canvas, f);
  }

  @override
  bool shouldRepaint(SkyPainter old) => old.inputs != inputs;
}
