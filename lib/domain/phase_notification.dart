import 'timer_math.dart';
import 'timer_view.dart';

/// What to show when a phase ends while the app is in the background.
class PhaseNotificationPlan {
  const PhaseNotificationPlan({
    required this.at,
    required this.title,
    required this.body,
  });

  /// When it should appear, on the phone's clock.
  final DateTime at;
  final String title;
  final String body;
}

/// The notification for the running phase, or null when there is nothing to
/// announce: the timer is idle or paused (a paused phase has no end), or the
/// phase is already over. The wording matches the website's alerts.
PhaseNotificationPlan? planPhaseNotification(
  TimerView timer, {
  required int serverNowMs,
  required DateTime now,
}) {
  final running = timer.phase == Phase.focus || timer.phase == Phase.break_;
  if (!running) return null;
  final left = remainingMs(timer, serverNowMs);
  if (left <= 0) return null;

  final label = timer.label.trim();
  final at = now.add(Duration(milliseconds: left));
  if (timer.phase == Phase.break_) {
    return PhaseNotificationPlan(
      at: at,
      title: 'Break is over',
      body: 'Ready for the next focus session?',
    );
  }
  return PhaseNotificationPlan(
    at: at,
    title: 'Focus session finished',
    body: label.isEmpty ? 'Time for a break.' : '$label. Time for a break.',
  );
}
