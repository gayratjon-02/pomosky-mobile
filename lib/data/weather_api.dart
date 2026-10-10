import 'dart:convert';
import 'dart:io';

import 'config.dart';

/// The host's place weather, as `GET /api/weather?room={id}` returns it.
class WeatherData {
  const WeatherData({
    required this.cloudCoverPct,
    required this.precipitationMmh,
    required this.snowfallCmh,
    required this.windSpeedKmh,
    required this.windDirDeg,
    required this.fogDensity,
    required this.thunder,
    required this.temperatureC,
    required this.observedAtMs,
  });

  final double cloudCoverPct;
  final double precipitationMmh;
  final double snowfallCmh;
  final double windSpeedKmh;
  final double windDirDeg;
  final double fogDensity;
  final bool thunder;
  final double temperatureC;

  /// When the reading was taken (it can be ~15 minutes old).
  final int observedAtMs;

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    double n(String key) => (json[key] as num?)?.toDouble() ?? 0;
    return WeatherData(
      cloudCoverPct: n('cloudCoverPct'),
      precipitationMmh: n('precipitationMmh'),
      snowfallCmh: n('snowfallCmh'),
      windSpeedKmh: n('windSpeedKmh'),
      windDirDeg: n('windDirDeg'),
      fogDensity: n('fogDensity'),
      thunder: json['thunder'] as bool? ?? false,
      temperatureC: n('temperatureC'),
      observedAtMs: (json['observedAtMs'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Fetches the weather of a room. Returns null while the host has not set a
/// place (404) or when the weather is unavailable (502, no network): the sky
/// then simply stays clear.
Future<WeatherData?> fetchWeather(
  String roomId, {
  String base = baseUrl,
  Duration timeout = const Duration(seconds: 8),
}) async {
  final client = HttpClient()..connectionTimeout = timeout;
  try {
    final uri = Uri.parse(
      base,
    ).replace(path: '/api/weather', queryParameters: {'room': roomId});
    final request = await client.getUrl(uri).timeout(timeout);
    final response = await request.close().timeout(timeout);
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      return null;
    }
    final body = await response.transform(utf8.decoder).join().timeout(timeout);
    return WeatherData.fromJson(jsonDecode(body) as Map<String, dynamic>);
  } catch (_) {
    return null;
  } finally {
    client.close(force: true);
  }
}
