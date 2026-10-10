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

  group('createRoom', () {
    Future<HttpServer> fake({
      bool rateLimited = false,
      bool setsCookie = true,
    }) async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((req) {
        final res = req.response;
        if (req.method == 'GET') {
          if (setsCookie) res.cookies.add(Cookie('pomosky_csrf', 'tok123'));
          res.close();
          return;
        }
        final ok =
            req.headers.value('x-csrf-token') == 'tok123' &&
            (req.headers.value('cookie') ?? '').contains('pomosky_csrf=tok123');
        if (!ok) {
          res.statusCode = 403;
        } else if (rateLimited) {
          res.statusCode = 429;
        } else {
          res.statusCode = 303;
          res.headers.set('location', '/r/abcd2345/host#token=secret-token_1');
        }
        res.close();
      });
      return server;
    }

    test('sends the csrf cookie back and reads the host token', () async {
      final server = await fake();
      addTearDown(() => server.close(force: true));
      final room = await createRoom(base: 'http://127.0.0.1:${server.port}');
      expect(room.id, 'abcd2345');
      expect(room.hostToken, 'secret-token_1');
    });

    test('a rate limited server gives a clear error', () async {
      final server = await fake(rateLimited: true);
      addTearDown(() => server.close(force: true));
      expect(
        createRoom(base: 'http://127.0.0.1:${server.port}'),
        throwsA(
          isA<RoomCreateException>().having(
            (e) => e.message,
            'message',
            contains('Too many'),
          ),
        ),
      );
    });

    test('no csrf cookie means a clear error', () async {
      final server = await fake(setsCookie: false);
      addTearDown(() => server.close(force: true));
      expect(
        createRoom(base: 'http://127.0.0.1:${server.port}'),
        throwsA(isA<RoomCreateException>()),
      );
    });

    test('an unreachable server is reported', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final base = 'http://127.0.0.1:${server.port}';
      await server.close(force: true);
      expect(createRoom(base: base), throwsA(isA<RoomCreateException>()));
    });
  });
}
