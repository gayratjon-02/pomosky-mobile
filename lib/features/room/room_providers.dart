import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/config.dart';
import '../../data/room_api.dart';
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

/// Whether the room exists; the room screen shows "not found" for a 404
/// instead of retrying a connection that can never succeed.
final roomLookupProvider = FutureProvider.autoDispose
    .family<RoomLookup, String>((ref, roomId) => lookupRoom(roomId));

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

/// The session's state. It starts from the current state and follows every
/// change, with no gap in which a message could be lost.
class RoomStateNotifier extends AutoDisposeFamilyNotifier<RoomState, String> {
  @override
  RoomState build(String roomId) {
    final session = ref.watch(roomSessionProvider(roomId));
    final sub = session.states.listen((next) => state = next);
    ref.onDispose(sub.cancel);
    return session.state;
  }
}

final roomStateProvider = NotifierProvider.autoDispose
    .family<RoomStateNotifier, RoomState, String>(RoomStateNotifier.new);

/// Fires several times a second so countdowns repaint.
final tickProvider = StreamProvider.autoDispose<int>(
  (ref) => Stream.periodic(const Duration(milliseconds: 250), (i) => i),
);
