import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pomosky_mobile/data/host_tokens.dart';
import 'package:pomosky_mobile/data/protocol/server_messages.dart';
import 'package:pomosky_mobile/data/room_api.dart';
import 'package:pomosky_mobile/data/weather_api.dart';
import 'package:pomosky_mobile/data/ws/room_transport.dart';
import 'package:pomosky_mobile/domain/timer_view.dart';
import 'package:pomosky_mobile/features/room/room_providers.dart';
import 'package:pomosky_mobile/features/room/room_screen.dart';

class _Transport implements RoomTransport {
  final msgs = StreamController<ServerMessage>.broadcast(sync: true);
  final stat = StreamController<SocketStatus>.broadcast(sync: true);
  final sent = <String>[];
  var open = false;

  @override
  Stream<ServerMessage> get messages => msgs.stream;
  @override
  Stream<SocketStatus> get status => stat.stream;
  @override
  SocketStatus get currentStatus => SocketStatus.connecting;
  @override
  void connect() {}
  @override
  void reconnect() {}
  @override
  bool send(String frame) {
    if (!open) return false;
    sent.add(frame);
    return true;
  }

  @override
  Future<void> close() async {}

  void connected() {
    open = true;
    stat.add(SocketStatus.connected);
  }
}

Future<_Transport> _pump(WidgetTester tester) async {
  final t = _Transport();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hostTokenStoreProvider.overrideWithValue(MemoryHostTokenStore()),
        roomTransportFactoryProvider.overrideWithValue((_, _) => t),
        roomLookupProvider.overrideWith((ref, id) => RoomLookup.found),
        // No real ticker: its periodic timer would outlive the test.
        tickProvider.overrideWith((ref) => const Stream<int>.empty()),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const RoomScreen(roomId: 'abcd2345'),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump(); // the lookup and the token resolve
  await tester.pump();
  return t;
}

void main() {
  testWidgets('shows a connecting banner, then the room', (tester) async {
    final t = await _pump(tester);
    await tester.pump();
    expect(find.text('Connecting…'), findsOneWidget);
    expect(find.text('Waiting for the host'), findsOneWidget);

    t.connected();
    t.msgs.add(
      StateMessage(
        roomId: 'abcd2345',
        timer: TimerView(
          phase: Phase.paused,
          pausedFrom: Phase.focus,
          startedAtMs: 0,
          durationMs: 1500000,
          pausedRemainingMs: 754000,
          label: 'Go backend',
        ),
        viewers: 3,
        reactions: const {'fire': 2},
        city: 'Seoul',
        serverNowMs: 1,
      ),
    );
    t.msgs.add(
      const PeopleMessage(
        people: [
          PersonView(name: 'Ayla'),
          PersonView(name: 'Bo'),
        ],
        more: 1,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Connecting…'), findsNothing);
    expect(find.text('Seoul'), findsOneWidget);
    expect(find.text('Paused'), findsOneWidget);
    expect(find.text('12:34'), findsOneWidget);
    expect(find.text('Go backend'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Ayla, Bo +1'), findsOneWidget);
    expect(find.text('🔥 2'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('tapping a reaction sends it', (tester) async {
    final t = await _pump(tester);
    t.connected();
    await tester.pump();

    await tester.tap(find.textContaining('👏'));
    await tester.pump();

    expect(
      t.sent.any((f) => f.contains('"reaction"') && f.contains('clap')),
      isTrue,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a room that does not exist shows a message, no socket', (
    tester,
  ) async {
    var connections = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hostTokenStoreProvider.overrideWithValue(MemoryHostTokenStore()),
          roomTransportFactoryProvider.overrideWithValue((_, _) {
            connections++;
            return _Transport();
          }),
          roomLookupProvider.overrideWith((ref, id) => RoomLookup.notFound),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const RoomScreen(roomId: 'abcd2345'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Room not found'), findsOneWidget);
    expect(connections, 0);
  });

  testWidgets('a phone that created the room connects with its host token', (
    tester,
  ) async {
    final store = MemoryHostTokenStore();
    await store.write('abcd2345', 'secret-token');
    String? seenToken;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hostTokenStoreProvider.overrideWithValue(store),
          roomTransportFactoryProvider.overrideWithValue((_, token) {
            seenToken = token;
            return _Transport();
          }),
          roomLookupProvider.overrideWith((ref, id) => RoomLookup.found),
          tickProvider.overrideWith((ref) => const Stream<int>.empty()),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const RoomScreen(roomId: 'abcd2345'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(seenToken, 'secret-token');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('host controls appear only after the server confirms the host', (
    tester,
  ) async {
    final t = await _pump(tester);
    t.connected();
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Start focus'), findsNothing);

    t.msgs.add(const HostOkMessage());
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Start focus'), findsOneWidget);

    await tester.tap(find.textContaining('Start focus'));
    await tester.pump();
    expect(
      t.sent.any((f) => f.contains('timer.start') && f.contains('"focus"')),
      isTrue,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a small phone shows the whole host screen without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320 * 3, 568 * 3); // iPhone SE
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final t = await _pump(tester);
    t.connected();
    t.msgs.add(const HostOkMessage());
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Start focus'), findsOneWidget);
    // Whatever does not fit is reachable by scrolling.
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -400),
    );
    await tester.pump();
    expect(find.text('Start break'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('shows the weather and says how old it is', (tester) async {
    final t = _Transport();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hostTokenStoreProvider.overrideWithValue(MemoryHostTokenStore()),
          roomTransportFactoryProvider.overrideWithValue((_, _) => t),
          roomLookupProvider.overrideWith((ref, id) => RoomLookup.found),
          nowMsProvider.overrideWithValue(() => 10 * 60 * 1000),
          tickProvider.overrideWith((ref) => const Stream<int>.empty()),
          weatherProvider.overrideWith(
            (ref, id) => Stream.value(
              const WeatherData(
                cloudCoverPct: 60,
                precipitationMmh: 0,
                snowfallCmh: 0,
                windSpeedKmh: 5,
                windDirDeg: 270,
                fogDensity: 0,
                thunder: false,
                temperatureC: 17.6,
                observedAtMs: 6 * 60 * 1000, // read 4 minutes ago
              ),
            ),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const RoomScreen(roomId: 'abcd2345'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('18° · Cloudy · updated 4 min ago'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
