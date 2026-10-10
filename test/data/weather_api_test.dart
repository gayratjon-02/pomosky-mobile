import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/data/weather_api.dart';

const _body = '''{
  "cloudCoverPct": 32, "precipitationMmh": 1.5, "snowfallCmh": 0,
  "windSpeedKmh": 3.6, "windDirDeg": 307, "fogDensity": 0.2, "thunder": true,
  "isDay": false, "temperatureC": 20.3, "code": 1,
  "observedAtMs": 1791626400000, "fetchedAtMs": 1791626500000
}''';

Future<HttpServer> _serve(int status, String body) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((req) {
    req.response
      ..statusCode = status
      ..write(body)
      ..close();
  });
  return server;
}

void main() {
  test('decodes the weather the server sends', () async {
    final server = await _serve(200, _body);
    addTearDown(() => server.close(force: true));
    final w = await fetchWeather(
      'abcd2345',
      base: 'http://127.0.0.1:${server.port}',
    );
    expect(w, isNotNull);
    expect(w!.cloudCoverPct, 32);
    expect(w.precipitationMmh, 1.5);
    expect(w.windDirDeg, 307);
    expect(w.thunder, isTrue);
    expect(w.temperatureC, 20.3);
    expect(w.observedAtMs, 1791626400000);
  });

  test('missing fields fall back to calm weather', () {
    final w = WeatherData.fromJson({});
    expect(w.cloudCoverPct, 0);
    expect(w.thunder, isFalse);
  });

  test(
    'no place yet (404) or upstream failure (502) means no weather',
    () async {
      for (final status in [404, 502]) {
        final server = await _serve(status, '{}');
        addTearDown(() => server.close(force: true));
        expect(
          await fetchWeather(
            'abcd2345',
            base: 'http://127.0.0.1:${server.port}',
          ),
          isNull,
        );
      }
    },
  );

  test('an unreachable server means no weather', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final base = 'http://127.0.0.1:${server.port}';
    await server.close(force: true);
    expect(await fetchWeather('abcd2345', base: base), isNull);
  });
}
