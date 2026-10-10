import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/ui/timer_ring.dart';

void main() {
  testWidgets('shows its child inside the ring', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TimerRing(
          fraction: 0.5,
          color: Colors.orange,
          child: Text('12:34'),
        ),
      ),
    );
    expect(find.text('12:34'), findsOneWidget);
  });

  test('repaints only when something visible changes', () {
    const a = RingPainter(
      fraction: 0.5,
      color: Colors.orange,
      track: Colors.grey,
      strokeWidth: 10,
    );
    const same = RingPainter(
      fraction: 0.5,
      color: Colors.orange,
      track: Colors.grey,
      strokeWidth: 10,
    );
    const moved = RingPainter(
      fraction: 0.4,
      color: Colors.orange,
      track: Colors.grey,
      strokeWidth: 10,
    );
    expect(a.shouldRepaint(same), isFalse);
    expect(a.shouldRepaint(moved), isTrue);
  });
}
