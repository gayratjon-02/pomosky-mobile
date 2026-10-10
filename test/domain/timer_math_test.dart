import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/domain/timer_math.dart';
import 'package:pomosky_mobile/domain/timer_view.dart';

TimerView running(Phase phase, {int started = 1000, int duration = 60000}) =>
    TimerView(
      phase: phase,
      startedAtMs: started,
      durationMs: duration,
      pausedRemainingMs: 0,
      label: '',
    );

void main() {
  group('remainingMs', () {
    final cases = <String, (TimerView, int, int)>{
      'idle is zero': (TimerView.idle, 5000, 0),
      'focus counts down': (running(Phase.focus), 31000, 30000),
      'break counts down': (running(Phase.break_), 1000, 60000),
      'ended never goes negative': (running(Phase.focus), 99000, 0),
      'paused uses the stored remainder': (
        const TimerView(
          phase: Phase.paused,
          pausedFrom: Phase.focus,
          startedAtMs: 1000,
          durationMs: 60000,
          pausedRemainingMs: 42000,
          label: '',
        ),
        99999,
        42000,
      ),
    };
    cases.forEach((name, c) {
      test(name, () => expect(remainingMs(c.$1, c.$2), c.$3));
    });
  });

  group('formatMMSS', () {
    final cases = <int, String>{
      0: '00:00',
      -5: '00:00',
      1: '00:01',
      999: '00:01',
      1000: '00:01',
      1001: '00:02',
      60000: '01:00',
      1500000: '25:00',
      3599000: '59:59',
    };
    cases.forEach((ms, want) {
      test('$ms ms -> $want', () => expect(formatMMSS(ms), want));
    });
  });

  group('remainingFraction', () {
    test('starts full and shrinks', () {
      final t = running(Phase.focus, started: 0, duration: 60000);
      expect(remainingFraction(t, 0), 1);
      expect(remainingFraction(t, 15000), 0.75);
      expect(remainingFraction(t, 60000), 0);
      expect(remainingFraction(t, 90000), 0);
    });

    test('a clock slightly behind the server never exceeds 1', () {
      final t = running(Phase.focus, started: 1000, duration: 60000);
      expect(remainingFraction(t, 900), 1);
    });

    test('paused uses the stored remainder', () {
      const t = TimerView(
        phase: Phase.paused,
        pausedFrom: Phase.focus,
        startedAtMs: 0,
        durationMs: 100000,
        pausedRemainingMs: 25000,
        label: '',
      );
      expect(remainingFraction(t, 999999), 0.25);
    });

    test('idle has nothing left', () {
      expect(remainingFraction(TimerView.idle, 5), 0);
    });
  });
}
