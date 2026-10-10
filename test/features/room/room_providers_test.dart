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

  test('a host token the server refuses is forgotten', () async {
    final transport = _Transport();
    final store = MemoryHostTokenStore();
    await store.write('abcd2345', 'stale-token');
    final container = ProviderContainer(
      overrides: [
        hostTokenStoreProvider.overrideWithValue(store),
        roomTransportFactoryProvider.overrideWithValue((_, _) => transport),
      ],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(hostTokenProvider('abcd2345').future),
      'stale-token',
    );
    container.listen(roomStateProvider('abcd2345'), (_, _) {});
    container.listen(hostRejectionProvider('abcd2345'), (_, _) {});

    transport.msgs.add(
      const ErrorMessage(code: 'forbidden', message: 'bad token'),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(await store.read('abcd2345'), isNull);
    expect(await container.read(hostTokenProvider('abcd2345').future), isNull);
  });

  test(
    'weather follows a change of city and survives a failed refresh',
    () async {
      final transport = _Transport();
      final answers = <WeatherData?>[
        _weather(cloud: 10), // first city
        _weather(cloud: 90), // second city
        null, // a failed fetch must not erase it
      ];
      final container = ProviderContainer(
        overrides: [
          hostTokenStoreProvider.overrideWithValue(MemoryHostTokenStore()),
          roomTransportFactoryProvider.overrideWithValue((_, _) => transport),
          weatherFetcherProvider.overrideWithValue(
            (id) async => answers.removeAt(0),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(hostTokenProvider('abcd2345').future);
      container.listen(roomStateProvider('abcd2345'), (_, _) {});
      final sub = container.listen(weatherProvider('abcd2345'), (_, _) {});

      StateMessage at(double lat, double lon) => StateMessage(
        roomId: 'abcd2345',
        timer: _idle,
        viewers: 1,
        reactions: const {},
        city: 'X',
        location: LocationView(lat: lat, lon: lon, tz: 'UTC'),
        serverNowMs: 1,
      );

      transport.msgs.add(at(37.57, 126.98));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(sub.read().value?.cloudCoverPct, 10);

      transport.msgs.add(at(35.1, 129.04)); // another city
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(sub.read().value?.cloudCoverPct, 90);

      // The same place again does not refetch.
      transport.msgs.add(at(35.1, 129.04));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(answers.length, 1);
    },
  );
}

const _idle = TimerView.idle;

WeatherData _weather({required double cloud}) => WeatherData(
  cloudCoverPct: cloud,
  precipitationMmh: 0,
  snowfallCmh: 0,
  windSpeedKmh: 5,
  windDirDeg: 270,
  fogDensity: 0,
  thunder: false,
  temperatureC: 12,
  observedAtMs: 0,
);
