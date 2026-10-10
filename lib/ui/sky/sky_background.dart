import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'layers/hills.dart';
import 'layers/stars.dart';
import 'sky_inputs.dart';
import 'sky_painter.dart';

/// A live sky behind [child]. It animates only while the app is visible and
/// stands still when the system asks for reduced motion.
class SkyBackground extends StatefulWidget {
  const SkyBackground({super.key, required this.inputs, required this.child});

  final SkyInputs inputs;
  final Widget child;

  @override
  State<SkyBackground> createState() => _SkyBackgroundState();
}

class _SkyBackgroundState extends State<SkyBackground> {
  final _time = ValueNotifier<double>(0);
  final _stars = StarField();
  final _hills = Hills();
  Ticker? _ticker;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _ticker ??= Ticker(
      (elapsed) => _time.value = elapsed.inMilliseconds.toDouble(),
    );
    // TickerMode is off while the route is hidden, which also stops the ticker.
    _ticker!.muted = !TickerMode.valuesOf(context).enabled || _reduceMotion;
    if (!_ticker!.isActive) _ticker!.start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: SkyPainter(
              inputs: widget.inputs,
              time: _time,
              stars: _stars,
              hills: _hills,
            ),
            size: Size.infinite,
          ),
        ),
        widget.child,
      ],
    );
  }
}
