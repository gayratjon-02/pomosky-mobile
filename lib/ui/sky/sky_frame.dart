import 'dart:ui';

import 'sky_inputs.dart';

/// What a layer needs to draw one frame.
class SkyFrame {
  SkyFrame({required this.size, required this.inputs, required this.timeMs})
    : horizonY = size.height * 0.8,
      overcast = inputs.overcast;

  final Size size;
  final SkyInputs inputs;

  /// Animation time in milliseconds.
  final double timeMs;

  /// Where the ground starts, as a canvas y.
  final double horizonY;

  /// 0 clear .. 1 fully overcast.
  final double overcast;
}
