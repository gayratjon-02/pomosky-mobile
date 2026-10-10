import 'timer_view.dart';

/// Which timer commands the host can use right now. The server accepts `start`
/// only when the timer is idle or the running phase has reached its end;
/// `pause` needs a running phase, `resume` a paused one.
class HostActions {
  const HostActions({
    required this.canStart,
    required this.canPause,
    required this.canResume,
    required this.canReset,
  });

  final bool canStart;
  final bool canPause;
  final bool canResume;
  final bool canReset;
}

HostActions hostActionsFor(TimerView timer, int remainingMs) {
  final running = timer.phase == Phase.focus || timer.phase == Phase.break_;
  final ended = running && remainingMs <= 0;
  return HostActions(
    canStart: timer.phase == Phase.idle || ended,
    canPause: running && !ended,
    canResume: timer.phase == Phase.paused,
    canReset: timer.phase != Phase.idle,
  );
}
