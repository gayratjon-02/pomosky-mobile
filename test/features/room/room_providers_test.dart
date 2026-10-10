import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/data/host_tokens.dart';
import 'package:pomosky_mobile/data/protocol/server_messages.dart';
import 'package:pomosky_mobile/data/weather_api.dart';
import 'package:pomosky_mobile/data/ws/room_transport.dart';
import 'package:pomosky_mobile/domain/timer_view.dart';
import 'package:pomosky_mobile/features/room/room_providers.dart';

class _Transport implements RoomTransport {
  final msgs = StreamController<ServerMessage>.broadcast(sync: true);
  final stat = StreamController<SocketStatus>.broadcast(sync: true);
  var connected = false;
  var closed = false;

  @override
  Stream<ServerMessage> get messages => msgs.stream;
  @override
  Stream<SocketStatus> get status => stat.stream;
  @override
  SocketStatus get currentStatus => SocketStatus.connecting;
  @override
  void connect() => connected = true;
  @override
  void reconnect() {}
  @override
  bool send(String frame) => false;
  @override
  Future<void> close() async => closed = true;
}

void main() {
  test(
    'the room state follows the connection and closes with the screen',
    () async {
      final transport = _Transport();
      String? askedFor;
      final container = ProviderContainer(
        overrides: [
          hostTokenStoreProvider.overrideWithValue(MemoryHostTokenStore()),
          roomTransportFactoryProvider.overrideWithValue((id, _) {
            askedFor = id;
            return transport;
          }),
        ],
      );

      await container.read(hostTokenProvider('abcd2345').future);
      final sub = container.listen(roomStateProvider('abcd2345'), (_, _) {});
      await Future<void>.delayed(Duration.zero);
      expect(askedFor, 'abcd2345');
      expect(transport.connected, isTrue);

      transport.msgs.add(
        const StateMessage(
          roomId: 'abcd2345',
          timer: _idle,
          viewers: 4,
          reactions: {},
          city: 'Seoul',
          serverNowMs: 1,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(sub.read().viewers, 4);

      sub.close();
      container.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(transport.closed, isTrue);
    },
  );

  test('weather waits for a place, then loads', () async {
    final transport = _Transport();
    var fetches = 0;
    final container = ProviderContainer(
      overrides: [
        hostTokenStoreProvider.overrideWithValue(MemoryHostTokenStore()),
        roomTransportFactoryProvider.overrideWithValue((_, _) => transport),
        weatherFetcherProvider.overrideWithValue((id) async {
          fetches++;
          return const WeatherData(
            cloudCoverPct: 80,
            precipitationMmh: 0,
            snowfallCmh: 0,
            windSpeedKmh: 5,
            windDirDeg: 270,
            fogDensity: 0,
            thunder: false,
            temperatureC: 12,
            observedAtMs: 0,
          );
        }),
      ],
    );
    addTearDown(container.dispose);

    final sub = container.listen(weatherProvider('abcd2345'), (_, _) {});
    container.listen(roomStateProvider('abcd2345'), (_, _) {});
    await Future<void>.delayed(Duration.zero);
    expect(sub.read().value, isNull);
    expect(fetches, 0);

    transport.msgs.add(
      const StateMessage(
        roomId: 'abcd2345',
        timer: _idle,
        viewers: 1,
        reactions: {},
        city: 'Seoul',
        location: LocationView(lat: 37.57, lon: 126.98, tz: 'Asia/Seoul'),
        serverNowMs: 1,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(fetches, 1);
    expect(sub.read().value?.cloudCoverPct, 80);
  });
}

const _idle = TimerView.idle;
