import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/data/protocol/server_messages.dart';
import 'package:pomosky_mobile/data/ws/room_transport.dart';
import 'package:pomosky_mobile/domain/timer_view.dart';
import 'package:pomosky_mobile/features/room/room_session.dart';

class FakeTransport implements RoomTransport {
  final _messages = StreamController<ServerMessage>.broadcast(sync: true);
  final _status = StreamController<SocketStatus>.broadcast(sync: true);
  final sent = <String>[];
  var connectCalls = 0;
  var open = false;

  @override
  Stream<ServerMessage> get messages => _messages.stream;
  @override
  Stream<SocketStatus> get status => _status.stream;
  @override
  SocketStatus get currentStatus =>
      open ? SocketStatus.connected : SocketStatus.connecting;
  @override
  void connect() => connectCalls++;
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

  void setStatus(SocketStatus s) {
    open = s == SocketStatus.connected;
    _status.add(s);
  }

  void receive(ServerMessage m) => _messages.add(m);
}

const _timer = TimerView(
  phase: Phase.focus,
  startedAtMs: 1000,
  durationMs: 1500000,
  pausedRemainingMs: 0,
  label: 'Go',
);

StateMessage _state({int viewers = 2}) => StateMessage(
  roomId: 'r',
  timer: _timer,
  viewers: viewers,
  reactions: const {'clap': 1},
  city: 'Seoul',
  serverNowMs: 5000,
);

void main() {
  test('state and people messages fill the room state', () {
    final t = FakeTransport();
    final s = RoomSession(transport: t, nowMs: () => 0)..start();
    expect(t.connectCalls, 1);

    t.setStatus(SocketStatus.connected);
    t.receive(_state());
    t.receive(const PeopleMessage(people: [PersonView(name: 'Ayla')], more: 3));

    expect(s.state.joined, isTrue);
    expect(s.state.timer.phase, Phase.focus);
    expect(s.state.viewers, 2);
    expect(s.state.city, 'Seoul');
    expect(s.state.people.single.name, 'Ayla');
    expect(s.state.morePeople, 3);
    expect(s.state.connection, SocketStatus.connected);
  });

  test('host.ok marks the host and reaction.tick updates one counter', () {
    final t = FakeTransport();
    final s = RoomSession(transport: t, nowMs: () => 0)..start();
    t.receive(_state());
    t.receive(const HostOkMessage());
    t.receive(const ReactionTickMessage(kind: 'fire', count: 4));

    expect(s.state.isHost, isTrue);
    expect(s.state.reactions, {'clap': 1, 'fire': 4});
  });

  test('an error is kept until the next state clears it', () {
    final t = FakeTransport();
    final s = RoomSession(transport: t, nowMs: () => 0)..start();
    t.receive(const ErrorMessage(code: 'forbidden', message: 'host only'));
    expect(s.state.error?.code, 'forbidden');
    t.receive(_state());
    expect(s.state.error, isNull);
  });

  test('pings warm up, then repeat, and stop when the link drops', () {
    fakeAsync((async) {
      final t = FakeTransport();
      RoomSession(transport: t, nowMs: () => 0).start();

      t.setStatus(SocketStatus.connected);
      async.elapse(const Duration(milliseconds: 1));
      expect(t.sent.length, 1);
      async.elapse(const Duration(seconds: 3));
      expect(t.sent.length, 4);
      async.elapse(RoomSession.pingEvery);
      expect(t.sent.length, 5);

      t.setStatus(SocketStatus.reconnecting);
      async.elapse(const Duration(minutes: 2));
      expect(t.sent.length, 5);
    });
  });

  test('pong replies set the server clock', () {
    fakeAsync((async) {
      var now = 1000;
      final t = FakeTransport();
      final s = RoomSession(transport: t, nowMs: () => now)..start();

      t.setStatus(SocketStatus.connected);
      async.elapse(const Duration(milliseconds: 1));
      // The ping left at local 1000; the reply came back at 1100 and carries
      // server time 5050, so the offset is 4000.
      now = 1100;
      t.receive(const PongMessage(5050));
      now = 2000;
      expect(s.serverNowMs(), 6000);
    });
  });

  test('commands send nothing while disconnected', () {
    final t = FakeTransport();
    final s = RoomSession(transport: t, nowMs: () => 0)..start();
    s.pause();
    expect(t.sent, isEmpty);
    t.setStatus(SocketStatus.connected);
    s.pause();
    s.startTimer(focus: true, durationMs: 60000, label: 'x');
    expect(t.sent.length, 2);
    expect(t.sent.first, contains('timer.pause'));
    expect(t.sent.last, contains('"durationMs":60000'));
  });

  test('the first state seeds the server clock before any pong', () {
    final t = FakeTransport();
    // The phone's clock is 40 s ahead of the server's.
    final s = RoomSession(transport: t, nowMs: () => 45000)..start();
    t.receive(_state()); // serverNowMs is 5000
    expect(s.serverNowMs(), 5000);
  });

  test('a real pong replaces the seed and bumps the clock epoch', () {
    fakeAsync((async) {
      var now = 45000;
      final t = FakeTransport();
      final s = RoomSession(transport: t, nowMs: () => now)..start();
      t.setStatus(SocketStatus.connected);
      t.receive(_state());
      final seededEpoch = s.state.clockEpoch;

      async.elapse(const Duration(milliseconds: 1));
      now = 45100; // reply after 100 ms; the server stamped 5080
      t.receive(const PongMessage(5080));
      expect(s.serverNowMs(), closeTo(5080 + 50, 5)); // not the old seed
      // Seed and measurement differ only by the latency, so no new epoch.
      expect(s.state.clockEpoch, seededEpoch);
    });
  });

  test('a big jump of the clock offset is announced', () {
    fakeAsync((async) {
      var now = 1000;
      final t = FakeTransport();
      final s = RoomSession(transport: t, nowMs: () => now)..start();
      t.setStatus(SocketStatus.connected);
      async.elapse(const Duration(milliseconds: 1));
      now = 1100;
      t.receive(const PongMessage(9050)); // the server is 8 s ahead
      expect(s.state.clockEpoch, greaterThan(0));
    });
  });
}
