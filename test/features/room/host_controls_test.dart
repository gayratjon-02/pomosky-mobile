import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/domain/host_actions.dart';
import 'package:pomosky_mobile/features/room/host_controls.dart';

const _idle = HostActions(
  canStart: true,
  canPause: false,
  canResume: false,
  canReset: false,
);
const _running = HostActions(
  canStart: false,
  canPause: true,
  canResume: false,
  canReset: true,
);
const _paused = HostActions(
  canStart: false,
  canPause: false,
  canResume: true,
  canReset: true,
);

Widget _app(
  HostActions a, {
  void Function(bool, int, String)? onStart,
  VoidCallback? onPause,
  VoidCallback? onResume,
  VoidCallback? onReset,
}) => MaterialApp(
  home: Scaffold(
    body: HostControls(
      actions: a,
      onStart: onStart ?? (_, _, _) {},
      onPause: onPause ?? () {},
      onResume: onResume ?? () {},
      onReset: onReset ?? () {},
    ),
  ),
);

void main() {
  testWidgets('starts a focus phase with the chosen length and label', (
    tester,
  ) async {
    (bool, int, String)? started;
    await tester.pumpWidget(
      _app(_idle, onStart: (f, d, l) => started = (f, d, l)),
    );

    await tester.tap(find.text('45'));
    await tester.enterText(find.byType(TextField), '  Flutter app ');
    await tester.pump();
    await tester.tap(find.textContaining('Start focus'));

    expect(started, (true, 45 * 60 * 1000, 'Flutter app'));
  });

  testWidgets('starts a break with its own length', (tester) async {
    (bool, int, String)? started;
    await tester.pumpWidget(
      _app(_idle, onStart: (f, d, l) => started = (f, d, l)),
    );
    await tester.tap(find.text('10'));
    await tester.pump();
    await tester.tap(find.text('Start break'));
    expect(started, (false, 10 * 60 * 1000, ''));
  });

  testWidgets('a running phase offers pause and reset', (tester) async {
    var paused = 0;
    var reset = 0;
    await tester.pumpWidget(
      _app(_running, onPause: () => paused++, onReset: () => reset++),
    );
    expect(find.text('Resume'), findsNothing);
    expect(find.textContaining('Start focus'), findsNothing);
    await tester.tap(find.text('Pause'));
    await tester.tap(find.text('Reset'));
    expect([paused, reset], [1, 1]);
  });

  testWidgets('a paused phase offers resume', (tester) async {
    var resumed = 0;
    await tester.pumpWidget(_app(_paused, onResume: () => resumed++));
    expect(find.text('Pause'), findsNothing);
    await tester.tap(find.text('Resume'));
    expect(resumed, 1);
  });
}
