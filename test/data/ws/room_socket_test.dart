import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/data/protocol/server_messages.dart';
import 'package:pomosky_mobile/data/ws/room_socket.dart';

/// A throwaway WebSocket server on localhost; no real network is used.
class _TestServer {
  late final HttpServer http;
  final origins = <String?>[];
  final received = <String>[];
  final sockets = <WebSocket>[];

  Future<void> start() async {
    http = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    http.listen((req) async {
      origins.add(req.headers.value('origin'));
      final ws = await WebSocketTransformer.upgrade(req);
      sockets.add(ws);
      ws.listen((d) => received.add(d as String));
    });
  }

  String get url => 'ws://127.0.0.1:${http.port}/ws/room1';

  Future<void> stop() async {
    for (final s in sockets) {
      await s.close();
    }
    await http.close(force: true);
  }
}

Future<T> within<T>(Future<T> f) => f.timeout(const Duration(seconds: 5));

void main() {
  late _TestServer server;
  setUp(() async {
    server = _TestServer();
    await server.start();
  });
  tearDown(() => server.stop());

  test('sends the Origin header and the handshake frames', () async {
    final socket = RoomSocket(
      url: server.url,
      origin: 'https://pomosky.example',
      handshake: () => ['{"type":"join","data":{"nickname":"Ayla"}}'],
    );
    final connected = socket.status.firstWhere(
      (s) => s == SocketStatus.connected,
    );
    socket.connect();
    await within(connected);
    await within(
      Future.doWhile(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return server.received.isEmpty;
      }),
    );

    expect(server.origins.single, 'https://pomosky.example');
    expect(server.received.single, contains('"join"'));
    await socket.close();
  });

  test('decodes incoming frames and skips garbage', () async {
    final socket = RoomSocket(
      url: server.url,
      origin: 'https://pomosky.example',
      handshake: () => const [],
    );
    final got = <ServerMessage>[];
    socket.messages.listen(got.add);
    final connected = socket.status.firstWhere(
      (s) => s == SocketStatus.connected,
    );
    socket.connect();
    await within(connected);
    await within(
      Future.doWhile(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return server.sockets.isEmpty;
      }),
    );

    server.sockets.single
      ..add('not json')
      ..add(
        jsonEncode({
          'type': 'pong',
          'data': {'serverNowMs': 7},
        }),
      );
    await within(
      Future.doWhile(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return got.isEmpty;
      }),
    );

    expect(got.single, isA<PongMessage>());
    expect((got.single as PongMessage).serverNowMs, 7);
    await socket.close();
  });

  test(
    'reconnects and repeats the handshake after the server drops it',
    () async {
      final socket = RoomSocket(
        url: server.url,
        origin: 'https://pomosky.example',
        handshake: () => ['{"type":"join","data":{"nickname":"A"}}'],
      );
      final connected = socket.status.firstWhere(
        (s) => s == SocketStatus.connected,
      );
      socket.connect();
      await within(connected);
      await within(
        Future.doWhile(() async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return server.sockets.isEmpty;
        }),
      );

      final again = socket.status
          .skipWhile((s) => s != SocketStatus.reconnecting)
          .firstWhere((s) => s == SocketStatus.connected);
      await server.sockets.first.close();
      await within(again);
      await within(
        Future.doWhile(() async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return server.received.length < 2;
        }),
      );

      expect(server.received.length, 2);
      await socket.close();
    },
  );

  test('send reports false while there is no connection', () async {
    final socket = RoomSocket(
      url: server.url,
      origin: 'https://pomosky.example',
      handshake: () => const [],
    );
    expect(socket.send('{"type":"ping"}'), isFalse);
    await socket.close();
  });
}
