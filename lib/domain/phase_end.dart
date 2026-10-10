import 'timer_view.dart';

/// Decides when the end-of-phase signal should ring. It fires once per phase,
/// right when a running phase reaches zero. A phase that ended long ago (the
/// phone joined late, or came back from the background much later) stays
/// silent, so the signal never sounds for something already over.
class PhaseEndWatcher {
  PhaseEndWatcher({this.grace = const Duration(seconds: 10)});

  /// How long after the end the signal may still ring.
  final Duration grace;

  int? _signalledFor;

  /// Call it on every tick with the server's time. Returns true exactly once
  /// per phase, on the tick that sees the end.
  bool shouldSignal(TimerView timer, int serverNowMs) {
    final running = timer.phase == Phase.focus || timer.phase == Phase.break_;
    if (!running || timer.durationMs <= 0) return false;
    final endsAt = timer.startedAtMs + timer.durationMs;
    if (serverNowMs < endsAt) return false;
    if (_signalledFor == timer.startedAtMs) return false;

    _signalledFor = timer.startedAtMs;
    return serverNowMs - endsAt <= grace.inMilliseconds;
  }
}
