import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/config.dart';
import '../../data/host_tokens.dart';
import '../../data/protocol/client_messages.dart';
import '../../data/room_api.dart';
import '../../data/weather_api.dart';
import '../../data/ws/room_socket.dart';
import '../../data/ws/room_transport.dart';
import 'room_session.dart';
import 'room_state.dart';

/// Where host tokens live. Tests override it with a memory store.
final hostTokenStoreProvider = Provider<HostTokenStore>(
  (ref) => SecureHostTokenStore(),
);

/// Creates a room on the server. Tests override it.
final roomCreatorProvider = Provider<Future<CreatedRoom> Function()>(
  (ref) => createRoom,
);

/// The host token of a room, if this phone created it.
final hostTokenProvider = FutureProvider.autoDispose.family<String?, String>(
  (ref, roomId) => ref.watch(hostTokenStoreProvider).read(roomId),
);

/// Builds the connection for a room; a host token adds `host.auth` to every
/// (re)connect. Tests override it with a fake.
final roomTransportFactoryProvider =
    Provider<RoomTransport Function(String roomId, String? hostToken)>(
      (ref) =>
          (roomId, hostToken) => RoomSocket(
            url: roomSocketUrl(roomId),
            origin: originOf(),
            handshake: () => [
              if (hostToken != null) ClientMessages.hostAuth(hostToken),
            ],
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
    transport: ref.watch(roomTransportFactoryProvider)(
      roomId,
      ref.watch(hostTokenProvider(roomId)).value,
    ),
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

/// Fetches the weather; tests override it.
final weatherFetcherProvider = Provider<Future<WeatherData?> Function(String)>(
  (ref) => fetchWeather,
);

/// How often the weather is refreshed. The server caches it for a similar time.
const weatherRefresh = Duration(minutes: 5);

/// The weather at the host's place, or null while it is not known. It loads
/// once the host has set a place and then refreshes every few minutes.
final weatherProvider = StreamProvider.autoDispose.family<WeatherData?, String>(
  (ref, roomId) async* {
    final hasPlace = ref.watch(
      roomStateProvider(roomId).select((s) => s.location != null),
    );
    if (!hasPlace) {
      yield null;
      return;
    }
    final fetch = ref.watch(weatherFetcherProvider);
    while (true) {
      yield await fetch(roomId);
      await Future<void>.delayed(weatherRefresh);
    }
  },
);

/// Fires several times a second so countdowns repaint.
final tickProvider = StreamProvider.autoDispose<int>(
  (ref) => Stream.periodic(const Duration(milliseconds: 250), (i) => i),
);
