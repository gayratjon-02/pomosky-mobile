import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/domain/host_actions.dart';
import 'package:pomosky_mobile/domain/timer_view.dart';

TimerView t(Phase p) => TimerView(
  phase: p,
  startedAtMs: 0,
  durationMs: 60000,
  pausedRemainingMs: 1000,
  label: '',
);

void main() {
  test('idle can only start', () {
    final a = hostActionsFor(TimerView.idle, 0);
    expect(
      [a.canStart, a.canPause, a.canResume, a.canReset],
      [true, false, false, false],
    );
  });

  test('a running phase can pause or reset, not start', () {
    final a = hostActionsFor(t(Phase.focus), 30000);
    expect(
      [a.canStart, a.canPause, a.canResume, a.canReset],
      [false, true, false, true],
    );
  });

  test('a phase that reached its end can start the next one', () {
    final a = hostActionsFor(t(Phase.break_), 0);
    expect(
      [a.canStart, a.canPause, a.canResume, a.canReset],
      [true, false, false, true],
    );
  });

  test('a paused phase can resume or reset', () {
    final a = hostActionsFor(t(Phase.paused), 1000);
    expect(
      [a.canStart, a.canPause, a.canResume, a.canReset],
      [false, false, true, true],
    );
  });
}
