import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/domain/phase_notification.dart';
import 'package:pomosky_mobile/domain/timer_view.dart';

TimerView t(
  Phase p, {
  String label = '',
  int started = 0,
  int duration = 60000,
}) => TimerView(
  phase: p,
  startedAtMs: started,
  durationMs: duration,
  pausedRemainingMs: 20000,
  label: label,
);

final now = DateTime.utc(2026, 10, 11, 12);

void main() {
  test('a running focus phase is announced at its end, with its label', () {
    final plan = planPhaseNotification(
      t(Phase.focus, label: 'Flutter app'),
      serverNowMs: 15000,
      now: now,
    )!;
    expect(plan.at, now.add(const Duration(seconds: 45)));
    expect(plan.title, 'Focus session finished');
    expect(plan.body, 'Flutter app. Time for a break.');
  });

  test('without a label the text is plain', () {
    final plan = planPhaseNotification(
      t(Phase.focus),
      serverNowMs: 0,
      now: now,
    )!;
    expect(plan.body, 'Time for a break.');
  });

  test('a break ends with an invitation to focus again', () {
    final plan = planPhaseNotification(
      t(Phase.break_),
      serverNowMs: 0,
      now: now,
    )!;
    expect(plan.title, 'Break is over');
    expect(plan.body, 'Ready for the next focus session?');
  });

  test('nothing to announce when idle, paused or already over', () {
    expect(
      planPhaseNotification(TimerView.idle, serverNowMs: 0, now: now),
      isNull,
    );
    expect(
      planPhaseNotification(t(Phase.paused), serverNowMs: 0, now: now),
      isNull,
    );
    expect(
      planPhaseNotification(t(Phase.focus), serverNowMs: 60000, now: now),
      isNull,
    );
    expect(
      planPhaseNotification(t(Phase.focus), serverNowMs: 99999, now: now),
      isNull,
    );
  });
}
