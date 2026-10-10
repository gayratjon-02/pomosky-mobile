import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/domain/phase_end.dart';
import 'package:pomosky_mobile/domain/timer_view.dart';

TimerView phase(Phase p, {int started = 1000, int duration = 60000}) =>
    TimerView(
      phase: p,
      startedAtMs: started,
      durationMs: duration,
      pausedRemainingMs: 0,
      label: '',
    );

void main() {
  test('rings once when a running phase reaches zero', () {
    final w = PhaseEndWatcher();
    final t = phase(Phase.focus);
    expect(w.shouldSignal(t, 30000), isFalse);
    expect(w.shouldSignal(t, 60999), isFalse); // 1 ms before the end
    expect(w.shouldSignal(t, 61000), isTrue);
    expect(w.shouldSignal(t, 61250), isFalse);
    expect(w.shouldSignal(t, 90000), isFalse);
  });

  test('a break rings too, and the next phase rings again', () {
    final w = PhaseEndWatcher();
    expect(w.shouldSignal(phase(Phase.focus), 61000), isTrue);
    final next = phase(Phase.break_, started: 70000, duration: 30000);
    expect(w.shouldSignal(next, 80000), isFalse);
    expect(w.shouldSignal(next, 100000), isTrue);
  });

  test('a phase that ended long ago stays silent, and only once', () {
    final w = PhaseEndWatcher();
    final t = phase(Phase.focus);
    expect(w.shouldSignal(t, 61000 + 60000), isFalse);
    // Still silent on the next ticks, even though it is now "within" nothing.
    expect(w.shouldSignal(t, 61000 + 60500), isFalse);
  });

  test('a short delay after the end still rings (a late tick or a resume)', () {
    final w = PhaseEndWatcher();
    expect(w.shouldSignal(phase(Phase.focus), 61000 + 8000), isTrue);
  });

  test('idle, paused and empty timers never ring', () {
    final w = PhaseEndWatcher();
    expect(w.shouldSignal(TimerView.idle, 99999), isFalse);
    expect(w.shouldSignal(phase(Phase.paused), 99999), isFalse);
    expect(w.shouldSignal(phase(Phase.focus, duration: 0), 99999), isFalse);
  });

  test('a paused phase that is resumed later rings at its new end', () {
    final w = PhaseEndWatcher();
    // Same startedAtMs would wrongly be silenced: the server restarts the
    // clock on resume, so startedAtMs changes.
    final resumed = phase(Phase.focus, started: 40000, duration: 30000);
    expect(w.shouldSignal(resumed, 70000), isTrue);
  });
}
