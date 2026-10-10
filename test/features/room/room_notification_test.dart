import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/data/host_tokens.dart';
import 'package:pomosky_mobile/data/phase_notifier.dart';
import 'package:pomosky_mobile/data/protocol/server_messages.dart';
import 'package:pomosky_mobile/data/settings.dart';
import 'package:pomosky_mobile/data/ws/room_transport.dart';
import 'package:pomosky_mobile/domain/timer_view.dart';
import 'package:pomosky_mobile/features/room/room_providers.dart';

class _Transport implements RoomTransport {
  final msgs = StreamController<ServerMessage>.broadcast(sync: true);
  @override
  Stream<ServerMessage> get messages => msgs.stream;
  @override
  Stream<SocketStatus> get status => const Stream.empty();
  @override
  SocketStatus get currentStatus => SocketStatus.connected;
  @override
  void connect() {}
  @override
  void reconnect() {}
  @override
  bool send(String frame) => false;
  @override
  Future<void> close() async {}
}

class _Notifier implements PhaseNotifier {
  final scheduled = <(DateTime, String, String)>[];
  var cancels = 0;
  var asks = 0;

  @override
  Future<bool> requestPermission() async {
    asks++;
    return true;
  }

  @override
  Future<void> schedule({
    required DateTime at,
    required String title,
    required String body,
  }) async => scheduled.add((at, title, body));

  @override
  Future<void> cancel() async => cancels++;
}

StateMessage _state(
  Phase p, {
  int started = 1000000,
  int duration = 60000,
  String label = 'Go',
}) => StateMessage(
  roomId: 'abcd2345',
  timer: TimerView(
    phase: p,
    startedAtMs: started,
    durationMs: duration,
    pausedRemainingMs: 20000,
    label: label,
  ),
  viewers: 1,
  reactions: const {},
  city: '',
  serverNowMs: started,
);

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  late _Transport transport;
  late _Notifier notifier;
  late MemorySettings settings;
  late ProviderContainer container;
  var now = 1000000;

  Future<void> setUpRoom() async {
    transport = _Transport();
    notifier = _Notifier();
    settings = MemorySettings();
    now = 1000000;
    container = ProviderContainer(
      overrides: [
        hostTokenStoreProvider.overrideWithValue(MemoryHostTokenStore()),
        roomTransportFactoryProvider.overrideWithValue((_, _) => transport),
        phaseNotifierProvider.overrideWithValue(notifier),
        appSettingsProvider.overrideWithValue(settings),
        nowMsProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    await container.read(hostTokenProvider('abcd2345').future);
    container.listen(roomStateProvider('abcd2345'), (_, _) {});
    container.listen(phaseNotificationSyncProvider('abcd2345'), (_, _) {});
  }

  Future<void> send(StateMessage m) async {
    transport.msgs.add(m);
    await Future<void>.delayed(Duration.zero);
  }

  void background() {
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  }

  void foreground() {
    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  }

  test(
    'schedules the end of a running phase when the app goes to the background',
    () async {
      await setUpRoom();
      await send(_state(Phase.focus)); // 60 s left, nothing yet
      expect(notifier.scheduled, isEmpty);

      now += 10000; // 50 s left when the user leaves
      background();
      expect(notifier.scheduled.length, 1);
      final (at, title, body) = notifier.scheduled.single;
      expect(at, DateTime.fromMillisecondsSinceEpoch(now + 50000));
      expect(title, 'Focus session finished');
      expect(body, 'Go. Time for a break.');
      foreground();
    },
  );

  test('coming back removes it, so the app rings by itself', () async {
    await setUpRoom();
    await send(_state(Phase.focus));
    background();
    final before = notifier.cancels;
    foreground();
    expect(notifier.cancels, greaterThan(before));
  });

  test(
    'a pause that arrives in the background cancels it, a restart reschedules',
    () async {
      await setUpRoom();
      await send(_state(Phase.focus));
      background();
      expect(notifier.scheduled.length, 1);

      final cancels = notifier.cancels;
      await send(_state(Phase.paused));
      expect(notifier.cancels, greaterThan(cancels));
      expect(notifier.scheduled.length, 1);

      await send(_state(Phase.break_, started: 1000000, duration: 30000));
      expect(notifier.scheduled.length, 2);
      expect(notifier.scheduled.last.$2, 'Break is over');
      foreground();
    },
  );

  test('nothing is scheduled for an idle room', () async {
    await setUpRoom();
    await send(_state(Phase.idle));
    background();
    expect(notifier.scheduled, isEmpty);
    foreground();
  });

  test(
    'permission is asked once, in the foreground, when a phase runs',
    () async {
      await setUpRoom();
      expect(notifier.asks, 0);
      await send(_state(Phase.focus));
      expect(notifier.asks, 1);
      expect(settings.notificationsAsked, isTrue);
      await send(_state(Phase.paused));
      await send(_state(Phase.focus, started: 2000000));
      expect(notifier.asks, 1);
    },
  );

  test('leaving the room removes a pending notification', () async {
    await setUpRoom();
    await send(_state(Phase.focus));
    background();
    final cancels = notifier.cancels;
    container.dispose();
    expect(notifier.cancels, greaterThan(cancels));
  });
}
