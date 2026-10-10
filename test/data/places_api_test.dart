import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/data/places_api.dart';

Future<HttpServer> _serve(
  int status,
  String body, {
  List<String>? queries,
}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((req) {
    queries?.add(req.uri.queryParameters['q'] ?? '');
    req.response
      ..statusCode = status
      ..write(body)
      ..close();
  });
  return server;
}

const _body = '''{"places":[
  {"name":"Seoul","region":"Seoul","country":"South Korea","lat":37.56,"lon":126.97,"tz":"Asia/Seoul"},
  {"name":"Busan","region":"","country":"South Korea","lat":35.1,"lon":129.04,"tz":"Asia/Seoul"}]}''';

void main() {
  test('decodes the results and builds readable labels', () async {
    final queries = <String>[];
    final server = await _serve(200, _body, queries: queries);
    addTearDown(() => server.close(force: true));
    final places = await searchPlaces(
      ' seo ',
      base: 'http://127.0.0.1:${server.port}',
    );

    expect(queries, ['seo']);
    expect(places.length, 2);
    expect(places.first.tz, 'Asia/Seoul');
    expect(places.first.label, 'Seoul, South Korea'); // no repeated Seoul
    expect(places.last.label, 'Busan, South Korea'); // no empty region
  });

  test('a short query never reaches the server', () async {
    final queries = <String>[];
    final server = await _serve(200, _body, queries: queries);
    addTearDown(() => server.close(force: true));
    final base = 'http://127.0.0.1:${server.port}';
    expect(await searchPlaces('s', base: base), isEmpty);
    expect(await searchPlaces('  ', base: base), isEmpty);
    expect(queries, isEmpty);
  });

  test('rate limiting and failures give clear messages', () async {
    for (final entry in {429: 'too fast', 502: 'not available'}.entries) {
      final server = await _serve(entry.key, '{}');
      addTearDown(() => server.close(force: true));
      expect(
        searchPlaces('seoul', base: 'http://127.0.0.1:${server.port}'),
        throwsA(
          isA<PlaceSearchException>().having(
            (e) => e.message.toLowerCase(),
            'message',
            contains(entry.value),
          ),
        ),
      );
    }
  });

  test('an unreachable server is reported', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final base = 'http://127.0.0.1:${server.port}';
    await server.close(force: true);
    expect(
      searchPlaces('seoul', base: base),
      throwsA(isA<PlaceSearchException>()),
    );
  });
}
