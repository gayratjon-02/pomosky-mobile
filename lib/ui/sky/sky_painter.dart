import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'layers/background.dart';
import 'layers/fog.dart';
import 'layers/lightning.dart';
import 'layers/moon.dart';
import 'layers/sun.dart';
import 'sky_frame.dart';
import 'sky_inputs.dart';
import 'sky_layers.dart';

/// Draws the whole sky. [time] is repainted on every tick; the layers are
/// created once and reused.
class SkyPainter extends CustomPainter {
  SkyPainter({required this.inputs, required this.time, required this.layers})
    : super(repaint: time);

  final SkyInputs inputs;
  final ValueListenable<double> time;
  final SkyLayers layers;

  @override
  void paint(Canvas canvas, Size size) {
    final f = SkyFrame(size: size, inputs: inputs, timeMs: time.value);
    paintBackground(canvas, f);
    layers.stars.paint(canvas, f);
    paintMoon(canvas, f);
    paintSun(canvas, f);
    layers.clouds.paint(canvas, f);
    layers.hills.paint(canvas, f);
    paintFog(canvas, f);
    layers.rain.paint(canvas, f);
    layers.snow.paint(canvas, f);
    paintLightning(canvas, f);
  }

  @override
  bool shouldRepaint(SkyPainter old) => old.inputs != inputs;
}
