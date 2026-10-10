import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/data/host_tokens.dart';
import 'package:pomosky_mobile/data/protocol/server_messages.dart';
import 'package:pomosky_mobile/data/ws/room_transport.dart';
import 'package:pomosky_mobile/features/room/room_providers.dart';

class _Transport implements RoomTransport {
  var reconnects = 0;
  @override
  Stream<ServerMessage> get messages => const Stream.empty();
  @override
  Stream<SocketStatus> get status => const Stream.empty();
  @override
  SocketStatus get currentStatus => SocketStatus.connected;
  @override
  void connect() {}
  @override
  void reconnect() => reconnects++;
  @override
  bool send(String frame) => false;
  @override
  Future<void> close() async {}
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  test('reconnects after a long stay in the background only', () async {
    final t = _Transport();
    var now = 0;
    final c = ProviderContainer(
      overrides: [
        hostTokenStoreProvider.overrideWithValue(MemoryHostTokenStore()),
        roomTransportFactoryProvider.overrideWithValue((_, _) => t),
        nowMsProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(c.dispose);
    await c.read(hostTokenProvider('abcd2345').future);
    c.listen(lifecycleReconnectProvider('abcd2345'), (_, _) {});

    final b = binding;
    // A quick app switch keeps the connection.
    b.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    b.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    now = 1000;
    b.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    b.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    b.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(t.reconnects, 0);

    // A long stay reconnects once.
    b.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    b.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    now = 60000;
    b.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    b.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(t.reconnects, 1);

    // Resuming again without leaving does nothing.
    b.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(t.reconnects, 1);
  });
}
