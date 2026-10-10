import 'package:flutter/services.dart';

import '../../domain/timer_view.dart';
import '../../features/room/live_timer_activity.dart';

/// Talks to the Swift side (ActivityKit) over a method channel. Every call
/// swallows platform errors: Live Activities may be disabled by the user or
/// unavailable on the device.
class IosLiveTimerActivity implements LiveTimerActivity {
  IosLiveTimerActivity({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'app.pomosky/live_activity';

  final MethodChannel _channel;

  @override
  Future<void> start(LiveTimerSnapshot snapshot) => _invoke('start', snapshot);

  @override
  Future<void> update(LiveTimerSnapshot snapshot) =>
      _invoke('update', snapshot);

  @override
  Future<void> end() => _invoke('end', null);

  Future<void> _invoke(String method, LiveTimerSnapshot? s) async {
    try {
      await _channel.invokeMethod<void>(method, s == null ? null : _args(s));
    } on PlatformException {
      // Disabled or unsupported: nothing to show, nothing to report.
    } on MissingPluginException {
      // Not running on iOS.
    }
  }

  static Map<String, Object> _args(LiveTimerSnapshot s) => {
    'phase': s.phase == Phase.break_ ? 'break' : s.phase.name,
    'label': s.label,
    'durationMs': s.durationMs,
    'endsAtMs': s.endsAtMs,
    'remainingMs': s.remainingMs,
  };
}
