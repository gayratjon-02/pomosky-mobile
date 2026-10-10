import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/data/protocol/server_messages.dart';
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
          roomTransportFactoryProvider.overrideWithValue((id) {
            askedFor = id;
            return transport;
          }),
        ],
      );

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
}

const _idle = TimerView.idle;
