import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tokens.dart';

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
          track: Tint.cream.withValues(alpha: 0.09),
          strokeWidth: strokeWidth,
        ),
        child: Center(
          child: Padding(
            // Keeps the numbers clear of the stroke on large text.
            padding: EdgeInsets.all(strokeWidth * 2),
            child: FittedBox(fit: BoxFit.scaleDown, child: child),
          ),
        ),
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
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // A thin track, so the lit arc reads as the thing that matters.
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      stroke
        ..color = track
        ..strokeWidth = strokeWidth * 0.45,
    );

    final sweep = math.pi * 2 * fraction.clamp(0.0, 1.0);
    if (sweep <= 0) return;
    // Starts at the top and the lit part shrinks towards it.
    const start = -math.pi / 2;
    // A faint halo under the arc, like light on the night sky.
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth * 1.6
        ..color = color.withValues(alpha: 0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeWidth * 0.8),
    );
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      stroke
        ..color = color
        ..strokeWidth = strokeWidth,
    );
    // A small bright bead where time is running out from.
    final head = start + sweep;
    final r = rect.width / 2;
    canvas.drawCircle(
      rect.center + Offset(math.cos(head) * r, math.sin(head) * r),
      strokeWidth * 0.22,
      Paint()..color = Tint.cream.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(RingPainter old) =>
      old.fraction != fraction ||
      old.color != color ||
      old.track != track ||
      old.strokeWidth != strokeWidth;
}
