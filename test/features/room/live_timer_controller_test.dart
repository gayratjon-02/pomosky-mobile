import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/domain/timer_view.dart';
import 'package:pomosky_mobile/features/room/live_timer_activity.dart';
import 'package:pomosky_mobile/features/room/live_timer_controller.dart';

class _FakeActivity implements LiveTimerActivity {
  final calls = <String>[];
  final snapshots = <LiveTimerSnapshot>[];
  Object? failWith;

  Future<void> _record(String name, [LiveTimerSnapshot? s]) async {
    calls.add(name);
    if (s != null) snapshots.add(s);
    if (failWith != null) throw failWith!;
  }

  @override
  Future<void> start(LiveTimerSnapshot s) => _record('start', s);
  @override
  Future<void> update(LiveTimerSnapshot s) => _record('update', s);
  @override
  Future<void> end() => _record('end');
}

class _FakeTimer implements Timer {
  _FakeTimer(this.delay, this.run);
  final Duration delay;
  final void Function() run;
  var cancelled = false;
  @override
  void cancel() => cancelled = true;
  @override
  bool get isActive => !cancelled;
  @override
  int get tick => 0;
}

TimerView _running(int startedAt, {Phase phase = Phase.focus}) => TimerView(
  phase: phase,
  startedAtMs: startedAt,
  durationMs: 25 * 60000,
  pausedRemainingMs: 0,
  label: 'write',
);

TimerView _paused(int startedAt, int remaining) => TimerView(
  phase: Phase.paused,
  pausedFrom: Phase.focus,
  startedAtMs: startedAt,
  durationMs: 25 * 60000,
  pausedRemainingMs: remaining,
  label: 'write',
);

void main() {
  late _FakeActivity activity;
  late List<_FakeTimer> timers;
  late LiveTimerController c;

  setUp(() {
    activity = _FakeActivity();
    timers = [];
    c = LiveTimerController(
      activity: activity,
      schedule: (d, run) {
        final t = _FakeTimer(d, run);
        timers.add(t);
        return t;
      },
    );
  });

  void feed(TimerView t, {int server = 1000, int wall = 5000}) =>
      c.onTimer(t, serverNowMs: server, wallNowMs: wall);

  test('starts when a phase runs, with the end on the device clock', () {
    feed(_running(1000));
    expect(activity.calls, ['start']);
    final s = activity.snapshots.single;
    expect(s.phase, Phase.focus);
    expect(s.remainingMs, 25 * 60000);
    expect(s.endsAtMs, 5000 + 25 * 60000);
  });

  test('idle starts nothing', () {
    feed(TimerView.idle);
    expect(activity.calls, isEmpty);
  });

  test('does not start twice for the same startedAtMs', () {
    feed(_running(1000));
    feed(_running(1000), server: 2000, wall: 6000);
    feed(_running(1000), server: 3000, wall: 7000);
    expect(activity.calls, ['start']);
  });

  test('pause and resume update the activity', () {
    feed(_running(1000));
    feed(_paused(1000, 600000), server: 2000, wall: 6000);
    expect(activity.calls, ['start', 'update']);
    expect(activity.snapshots.last.phase, Phase.paused);
    expect(activity.snapshots.last.remainingMs, 600000);
    // Resuming shifts startedAtMs on the server.
    feed(_running(9000), server: 9000, wall: 13000);
    expect(activity.calls, ['start', 'update', 'update']);
    expect(activity.snapshots.last.phase, Phase.focus);
  });

  test('a phase change from focus to break updates', () {
    feed(_running(1000));
    feed(_running(2000, phase: Phase.break_), server: 2000, wall: 6000);
    expect(activity.calls, ['start', 'update']);
    expect(activity.snapshots.last.phase, Phase.break_);
  });

  test('reset ends the activity', () {
    feed(_running(1000));
    feed(TimerView.idle);
    expect(activity.calls, ['start', 'end']);
  });

  test('ends after the phase plus grace and does not restart it', () {
    feed(_running(1000));
    expect(timers.last.delay, const Duration(minutes: 25, seconds: 5));
    timers.last.run();
    expect(activity.calls, ['start', 'end']);
    // The server still reports the finished phase.
    feed(_running(1000), server: 1000 + 25 * 60000 + 9000);
    expect(activity.calls, ['start', 'end']);
    // A new phase starts again.
    feed(_running(2000000), server: 2000000);
    expect(activity.calls, ['start', 'end', 'start']);
  });

  test('a phase that is already over is not started', () {
    feed(_running(1000), server: 1000 + 25 * 60000 + 1);
    expect(activity.calls, isEmpty);
  });

  test('leaving ends the activity and ignores later states', () {
    feed(_running(1000));
    c.leave();
    feed(_running(5000));
    expect(activity.calls, ['start', 'end']);
  });

  test('leaving without an activity does nothing', () {
    c.leave();
    expect(activity.calls, isEmpty);
  });

  test('clock jitter under a second does not update', () {
    feed(_running(1000));
    feed(_running(1000), server: 1500, wall: 5600);
    expect(activity.calls, ['start']);
  });

  test('a failing platform never throws', () async {
    activity.failWith = StateError('disabled');
    feed(_running(1000));
    c.leave();
    await Future<void>.delayed(Duration.zero);
    expect(activity.calls, ['start', 'end']);
  });
}
