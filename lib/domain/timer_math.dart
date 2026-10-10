import 'timer_view.dart';

/// Remaining time at the given server time (ms). Mirrors `room.Timer.Remaining`
/// in the Go backend.
int remainingMs(TimerView t, int serverNowMs) {
  switch (t.phase) {
    case Phase.paused:
      return t.pausedRemainingMs;
    case Phase.focus:
    case Phase.break_:
      final left = t.startedAtMs + t.durationMs - serverNowMs;
      return left < 0 ? 0 : left;
    case Phase.idle:
      return 0;
  }
}

/// Formats milliseconds as MM:SS, rounded up to the next second.
String formatMMSS(int ms) {
  final total = ((ms < 0 ? 0 : ms) / 1000).ceil();
  final m = total ~/ 60;
  final s = total % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
