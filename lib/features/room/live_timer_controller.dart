import 'dart:async';

import '../../domain/timer_math.dart';
import '../../domain/timer_view.dart';
import 'live_timer_activity.dart';

/// Schedules [run] after [delay]; replaced in tests.
typedef Scheduler = Timer Function(Duration delay, void Function() run);

/// Decides when the out-of-app countdown starts, updates and ends, from the
/// room's timer. Pure Dart: the platform side sits behind [LiveTimerActivity].
class LiveTimerController {
  LiveTimerController({
    required LiveTimerActivity activity,
    this.grace = const Duration(seconds: 5),
    Scheduler? schedule,
  }) : _activity = activity,
       _schedule = schedule ?? Timer.new;

  final LiveTimerActivity _activity;

  /// How long a finished phase stays visible before the activity ends.
  final Duration grace;
  final Scheduler _schedule;

  bool _active = false;

  // The phase whose activity is shown or was shown last. Once it ended, the
  // same phase is not started again (the server keeps reporting it).
  int? _phaseKey;
  bool _phaseDone = false;
  LiveTimerSnapshot? _last;
  Timer? _endTimer;
  var _disposed = false;

  /// Feeds the current timer. [serverNowMs] is the server clock, [wallNowMs]
  /// the device clock at the same instant.
  void onTimer(TimerView timer, {required int serverNowMs, int? wallNowMs}) {
    if (_disposed) return;
    final wallNow = wallNowMs ?? DateTime.now().millisecondsSinceEpoch;
    if (timer.phase == Phase.idle) {
      _finish();
      _phaseKey = null;
      _phaseDone = false;
      return;
    }
    final left = remainingMs(timer, serverNowMs);
    final paused = timer.phase == Phase.paused;
    final key = timer.startedAtMs;
    final sameStart = key == _phaseKey;

    if (_phaseDone && sameStart && !paused) return;
    if (!paused && left <= 0) {
      // The phase is over. A phase we never showed is not started now.
      if (_active && _endTimer == null) _scheduleEnd(grace);
      return;
    }

    final snapshot = LiveTimerSnapshot(
      phase: timer.phase,
      label: timer.label,
      durationMs: timer.durationMs,
      endsAtMs: wallNow + left,
      remainingMs: left,
    );
    _phaseKey = key;
    _phaseDone = false;
    _endTimer?.cancel();
    _endTimer = null;
    if (!paused) _scheduleEnd(Duration(milliseconds: left) + grace);

    if (!_active) {
      _active = true;
      _last = snapshot;
      _fire(() => _activity.start(snapshot));
    } else if (_changed(_last!, snapshot, paused)) {
      _last = snapshot;
      _fire(() => _activity.update(snapshot));
    }
  }

  // Skips updates that only reflect clock jitter: the end moved by under a
  // second while running.
  bool _changed(LiveTimerSnapshot a, LiveTimerSnapshot b, bool paused) {
    if (a.phase != b.phase || a.label != b.label) return true;
    if (a.durationMs != b.durationMs) return true;
    if (paused) return a.remainingMs != b.remainingMs;
    return (a.endsAtMs - b.endsAtMs).abs() >= 1000;
  }

  /// The user left the room: end the activity.
  void leave() {
    _disposed = true;
    _finish();
  }

  void _scheduleEnd(Duration after) {
    _endTimer?.cancel();
    _endTimer = _schedule(after, () {
      _phaseDone = true;
      _finish();
    });
  }

  void _finish() {
    _endTimer?.cancel();
    _endTimer = null;
    if (!_active) return;
    _active = false;
    _last = null;
    _fire(_activity.end);
  }

  void _fire(Future<void> Function() call) {
    // Implementations should not throw; a failure must never reach the UI.
    unawaited(call().catchError((Object _) {}));
  }
}
