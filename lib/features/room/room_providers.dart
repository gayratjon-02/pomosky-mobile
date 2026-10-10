import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/config.dart';
import '../../data/host_tokens.dart';
import '../../data/protocol/client_messages.dart';
import '../../data/places_api.dart';
import '../../data/room_api.dart';
import '../../data/screen_awake.dart';
import '../../data/settings.dart';
import '../../data/signal_player.dart';
import '../../data/weather_api.dart';
import '../../data/ws/room_socket.dart';
import '../../data/ws/room_transport.dart';
import '../../domain/phase_end.dart';
import '../../domain/timer_view.dart';
import 'place_picker.dart';
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

/// The phone's clock in milliseconds; tests override it.
final nowMsProvider = Provider<int Function()>(
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
    nowMs: ref.watch(nowMsProvider),
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

/// Searches places for the host's city sheet. Tests override it.
final placeSearchProvider = Provider<PlaceSearch>((ref) => searchPlaces);

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

/// The saved settings. The app overrides it with the preferences-backed one.
final appSettingsProvider = Provider<AppSettings>((ref) => MemorySettings());

class SoundEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(appSettingsProvider).soundEnabled;

  Future<void> toggle() async {
    state = !state;
    await ref.read(appSettingsProvider).setSoundEnabled(state);
  }
}

/// Whether the end-of-phase signal plays a sound.
final soundEnabledProvider = NotifierProvider<SoundEnabledNotifier, bool>(
  SoundEnabledNotifier.new,
);

/// Rings and vibrates at the end of a phase. Silent unless the app overrides it.
final signalPlayerProvider = Provider<SignalPlayer>(
  (ref) => SilentSignalPlayer(),
);

/// Remembers which phase already rang, per open room.
final phaseEndWatcherProvider = Provider.autoDispose
    .family<PhaseEndWatcher, String>((ref, roomId) {
      final player = ref.watch(signalPlayerProvider);
      ref.onDispose(
        player.stop,
      ); // leaving the room silences a ring in progress
      return PhaseEndWatcher();
    });

/// Keeps the screen awake. Silent unless the app overrides it.
final screenAwakeProvider = Provider<ScreenAwake>((ref) => NoScreenAwake());

/// Keeps the screen on while a phase is running in this room, and lets it
/// sleep again when the phase stops or the room is left.
final screenAwakeSyncProvider = Provider.autoDispose.family<void, String>((
  ref,
  roomId,
) {
  final awake = ref.watch(screenAwakeProvider);
  void apply(RoomState state) {
    final running =
        state.timer.phase == Phase.focus || state.timer.phase == Phase.break_;
    awake.set(running);
  }

  ref.listen(roomStateProvider(roomId), (_, next) => apply(next));
  ref.onDispose(() => awake.set(false));
});

/// How long the app must have been in the background before it reconnects on
/// return. A quick app switch keeps the live connection.
const backgroundReconnectAfter = Duration(seconds: 3);

/// Reconnects the room when the app returns from the background: a socket can
/// die while the phone sleeps without anyone being told.
final lifecycleReconnectProvider = Provider.autoDispose.family<void, String>((
  ref,
  roomId,
) {
  final session = ref.watch(roomSessionProvider(roomId));
  final now = ref.watch(nowMsProvider);
  int? leftAt;
  final listener = AppLifecycleListener(
    onHide: () => leftAt ??= now(),
    onResume: () {
      final left = leftAt;
      leftAt = null;
      if (left != null &&
          now() - left >= backgroundReconnectAfter.inMilliseconds) {
        session.reconnect();
      }
    },
  );
  ref.onDispose(listener.dispose);
});

/// Fires several times a second so countdowns repaint.
final tickProvider = StreamProvider.autoDispose<int>(
  (ref) => Stream.periodic(const Duration(milliseconds: 250), (i) => i),
);
