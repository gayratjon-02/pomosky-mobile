import '../../domain/timer_view.dart';

/// What the lock screen / Dynamic Island shows for the running timer.
class LiveTimerSnapshot {
  const LiveTimerSnapshot({
    required this.phase,
    required this.label,
    required this.durationMs,
    required this.endsAtMs,
    required this.remainingMs,
  });

  /// [Phase.focus], [Phase.break_] or [Phase.paused].
  final Phase phase;
  final String label;
  final int durationMs;

  /// Device wall-clock time (epoch ms) when the phase ends. Meaningful while
  /// running; while paused it is only an estimate of the end if resumed now.
  final int endsAtMs;

  /// Time left when the snapshot was taken; the frozen value while paused.
  final int remainingMs;

  @override
  bool operator ==(Object other) =>
      other is LiveTimerSnapshot &&
      other.phase == phase &&
      other.label == label &&
      other.durationMs == durationMs &&
      other.endsAtMs == endsAtMs &&
      other.remainingMs == remainingMs;

  @override
  int get hashCode =>
      Object.hash(phase, label, durationMs, endsAtMs, remainingMs);
}

/// A countdown shown outside the app. Implementations never throw: where Live
/// Activities are unsupported or disabled the calls do nothing.
abstract interface class LiveTimerActivity {
  Future<void> start(LiveTimerSnapshot snapshot);
  Future<void> update(LiveTimerSnapshot snapshot);
  Future<void> end();
}

/// Used on platforms without Live Activities and in tests.
class NoopLiveTimerActivity implements LiveTimerActivity {
  const NoopLiveTimerActivity();

  @override
  Future<void> start(LiveTimerSnapshot snapshot) async {}
  @override
  Future<void> update(LiveTimerSnapshot snapshot) async {}
  @override
  Future<void> end() async {}
}
