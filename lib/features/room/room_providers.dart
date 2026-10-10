import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/config.dart';
import '../../data/ws/room_socket.dart';
import '../../data/ws/room_transport.dart';
import 'room_session.dart';
import 'room_state.dart';

/// Builds the connection for a room. Tests override it with a fake.
final roomTransportFactoryProvider = Provider<RoomTransport Function(String)>(
  (ref) =>
      (roomId) => RoomSocket(
        url: roomSocketUrl(roomId),
        origin: originOf(),
        handshake: () => const [],
      ),
);

final _nowMsProvider = Provider<int Function()>(
  (ref) =>
      () => DateTime.now().millisecondsSinceEpoch,
);

/// One live session per open room screen; leaving the screen closes it.
final roomSessionProvider = Provider.autoDispose.family<RoomSession, String>((
  ref,
  roomId,
) {
  final session = RoomSession(
    transport: ref.watch(roomTransportFactoryProvider)(roomId),
    nowMs: ref.watch(_nowMsProvider),
  )..start();
  ref.onDispose(session.dispose);
  return session;
});

final roomStateProvider = StreamProvider.autoDispose.family<RoomState, String>((
  ref,
  roomId,
) async* {
  final session = ref.watch(roomSessionProvider(roomId));
  yield session.state;
  yield* session.states;
});

/// Fires several times a second so countdowns repaint.
final tickProvider = StreamProvider.autoDispose<int>(
  (ref) => Stream.periodic(const Duration(milliseconds: 250), (i) => i),
);
