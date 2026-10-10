import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/data/host_tokens.dart';
import 'package:pomosky_mobile/data/protocol/server_messages.dart';
import 'package:pomosky_mobile/data/screen_awake.dart';
import 'package:pomosky_mobile/data/ws/room_transport.dart';
import 'package:pomosky_mobile/domain/timer_view.dart';
import 'package:pomosky_mobile/features/room/room_providers.dart';

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
  bool send(String frame) => false;
  @override
  Future<void> close() async {}
}

class _Awake implements ScreenAwake {
  final calls = <bool>[];
  @override
  Future<void> set(bool on) async => calls.add(on);
}

StateMessage _state(Phase p) => StateMessage(
  roomId: 'abcd2345',
  timer: TimerView(
    phase: p,
    startedAtMs: 1,
    durationMs: 60000,
    pausedRemainingMs: 0,
    label: '',
  ),
  viewers: 1,
  reactions: const {},
  city: '',
  serverNowMs: 1,
);

void main() {
  test('the screen stays on while a phase runs and sleeps otherwise', () async {
    final t = _Transport();
    final awake = _Awake();
    final c = ProviderContainer(
      overrides: [
        hostTokenStoreProvider.overrideWithValue(MemoryHostTokenStore()),
        roomTransportFactoryProvider.overrideWithValue((_, _) => t),
        screenAwakeProvider.overrideWithValue(awake),
      ],
    );
    addTearDown(c.dispose);
    await c.read(hostTokenProvider('abcd2345').future);
    c.listen(roomStateProvider('abcd2345'), (_, _) {});
    c.listen(screenAwakeSyncProvider('abcd2345'), (_, _) {});

    Future<void> send(Phase p) async {
      t.msgs.add(_state(p));
      await Future<void>.delayed(Duration.zero);
    }

    await send(Phase.focus);
    await send(Phase.paused);
    await send(Phase.break_);
    await send(Phase.idle);

    expect(awake.calls, [true, false, true, false]);
  });

  test('leaving the room lets the screen sleep', () async {
    final t = _Transport();
    final awake = _Awake();
    final c = ProviderContainer(
      overrides: [
        hostTokenStoreProvider.overrideWithValue(MemoryHostTokenStore()),
        roomTransportFactoryProvider.overrideWithValue((_, _) => t),
        screenAwakeProvider.overrideWithValue(awake),
      ],
    );
    await c.read(hostTokenProvider('abcd2345').future);
    final room = c.listen(roomStateProvider('abcd2345'), (_, _) {});
    final sync = c.listen(screenAwakeSyncProvider('abcd2345'), (_, _) {});
    t.msgs.add(_state(Phase.focus));
    await Future<void>.delayed(Duration.zero);
    expect(awake.calls.last, isTrue);

    sync.close();
    room.close();
    c.dispose();
    expect(awake.calls.last, isFalse);
  });
}
