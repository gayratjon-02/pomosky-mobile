import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pomosky_mobile/data/host_tokens.dart';
import 'package:pomosky_mobile/data/protocol/server_messages.dart';
import 'package:pomosky_mobile/data/room_api.dart';
import 'package:pomosky_mobile/data/settings.dart';
import 'package:pomosky_mobile/data/signal_player.dart';
import 'package:pomosky_mobile/data/ws/room_transport.dart';
import 'package:pomosky_mobile/domain/timer_view.dart';
import 'package:pomosky_mobile/features/room/room_providers.dart';
import 'package:pomosky_mobile/features/room/room_screen.dart';

class _Transport implements RoomTransport {
  final msgs = StreamController<ServerMessage>.broadcast(sync: true);
  final stat = StreamController<SocketStatus>.broadcast(sync: true);

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
  bool send(String frame) => false;
  @override
  Future<void> close() async {}
}

class _Player implements SignalPlayer {
  final rings = <bool>[];
  var stops = 0;

  @override
  Future<void> ring({required bool sound}) async => rings.add(sound);
  @override
  Future<void> stop() async => stops++;
}

class _Harness {
  final transport = _Transport();
  final player = _Player();
  final ticks = StreamController<int>.broadcast();
  var now = 1000000;
  final settings = MemorySettings();

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hostTokenStoreProvider.overrideWithValue(MemoryHostTokenStore()),
          roomTransportFactoryProvider.overrideWithValue((_, _) => transport),
          roomLookupProvider.overrideWith((ref, id) => RoomLookup.found),
          nowMsProvider.overrideWithValue(() => now),
          signalPlayerProvider.overrideWithValue(player),
          appSettingsProvider.overrideWithValue(settings),
          tickProvider.overrideWith((ref) => ticks.stream),
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
  }

  void phase({required int startedAt, int duration = 60000}) {
    transport.msgs.add(
      StateMessage(
        roomId: 'abcd2345',
        timer: TimerView(
          phase: Phase.focus,
          startedAtMs: startedAt,
          durationMs: duration,
          pausedRemainingMs: 0,
          label: '',
        ),
        viewers: 1,
        reactions: const {},
        city: '',
        serverNowMs: now,
      ),
    );
  }

  Future<void> tick(WidgetTester tester) async {
    ticks.add(0);
    await tester.pump();
  }
}

void main() {
  testWidgets('rings once, with sound, when the phase ends', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    h.phase(startedAt: h.now - 30000); // 30 s left
    await tester.pump();

    await h.tick(tester);
    expect(h.player.rings, isEmpty);

    h.now += 31000; // the phase is over
    await h.tick(tester);
    await h.tick(tester);
    expect(h.player.rings, [true]);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect(h.player.stops, greaterThan(0)); // leaving silences it
  });

  testWidgets('stays silent for a phase that ended long ago', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    h.phase(startedAt: h.now - 600000); // ended 9 minutes ago
    await tester.pump();
    await h.tick(tester);
    await h.tick(tester);
    expect(h.player.rings, isEmpty);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('muted: still vibrates, but asks for no sound', (tester) async {
    final h = _Harness()..settings.soundEnabled = false;
    await h.pump(tester);
    h.phase(startedAt: h.now - 59000);
    await tester.pump();
    h.now += 2000;
    await h.tick(tester);
    expect(h.player.rings, [false]);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('the sound button toggles and remembers the choice', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    expect(find.byIcon(Icons.volume_up_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.volume_up_outlined));
    await tester.pump();
    expect(find.byIcon(Icons.volume_off_outlined), findsOneWidget);
    expect(h.settings.soundEnabled, isFalse);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('the next phase rings again', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    h.phase(startedAt: h.now - 59000);
    await tester.pump();
    h.now += 2000;
    await h.tick(tester);
    expect(h.player.rings.length, 1);

    h.phase(startedAt: h.now, duration: 10000);
    await tester.pump();
    await h.tick(tester);
    expect(h.player.rings.length, 1);
    h.now += 11000;
    await h.tick(tester);
    expect(h.player.rings.length, 2);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
