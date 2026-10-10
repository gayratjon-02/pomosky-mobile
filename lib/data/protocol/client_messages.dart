import 'dart:convert';

/// Builds the JSON frames the app sends. Field names match the server's
/// `docs/ws-protocol.md`.
String _frame(String type, [Map<String, dynamic>? data]) =>
    jsonEncode({'type': type, 'data': ?data});

abstract final class ClientMessages {
  static String join(String nickname) => _frame('join', {'nickname': nickname});

  static String hostAuth(String token) => _frame('host.auth', {'token': token});

  static String timerStart({
    required bool focus,
    required int durationMs,
    required String label,
  }) => _frame('timer.start', {
    'phase': focus ? 'focus' : 'break',
    'durationMs': durationMs,
    'label': label,
  });

  static String timerPause() => _frame('timer.pause');

  static String timerResume() => _frame('timer.resume');

  static String timerReset() => _frame('timer.reset');

  static String reaction(String kind) => _frame('reaction', {'kind': kind});

  static String locationSet({
    required String city,
    required double lat,
    required double lon,
    required String tz,
  }) =>
      _frame('location.set', {'city': city, 'lat': lat, 'lon': lon, 'tz': tz});

  static String ping() => _frame('ping');
}
