import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/data/room_api.dart';

Future<HttpServer> _serve(int Function(String path) status) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((req) {
    req.response.statusCode = status(req.uri.path);
    req.response.close();
  });
  return server;
}

void main() {
  test('maps the status of GET /r/{id}', () async {
    final server = await _serve(
      (path) => switch (path) {
        '/r/live2345' => 200,
        '/r/gone2345' => 404,
        _ => 500,
      },
    );
    addTearDown(() => server.close(force: true));
    final base = 'http://127.0.0.1:${server.port}';

    expect(await lookupRoom('live2345', base: base), RoomLookup.found);
    expect(await lookupRoom('gone2345', base: base), RoomLookup.notFound);
    expect(await lookupRoom('boom2345', base: base), RoomLookup.unknown);
  });

  test('an unreachable server is unknown, not not-found', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final base = 'http://127.0.0.1:${server.port}';
    await server.close(force: true);
    expect(await lookupRoom('abcd2345', base: base), RoomLookup.unknown);
  });
}
