import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A ring that empties clockwise as time runs out. [fraction] is 1 when the
/// phase starts and 0 when it ends.
class TimerRing extends StatelessWidget {
  const TimerRing({
    super.key,
    required this.fraction,
    required this.color,
    required this.child,
    this.size = 280,
    this.strokeWidth = 10,
  });

  final double fraction;
  final Color color;
  final Widget child;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: RingPainter(
          fraction: fraction,
          color: color,
          track: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
          strokeWidth: strokeWidth,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class RingPainter extends CustomPainter {
  const RingPainter({
    required this.fraction,
    required this.color,
    required this.track,
    required this.strokeWidth,
  });

  final double fraction;
  final Color color;
  final Color track;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - strokeWidth) / 2,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    final sweep = math.pi * 2 * fraction.clamp(0.0, 1.0);
    if (sweep > 0) {
      // Starts at the top and the lit part shrinks towards it.
      canvas.drawArc(rect, -math.pi / 2, sweep, false, paint..color = color);
    }
  }

  @override
  bool shouldRepaint(RingPainter old) =>
      old.fraction != fraction ||
      old.color != color ||
      old.track != track ||
      old.strokeWidth != strokeWidth;
}
