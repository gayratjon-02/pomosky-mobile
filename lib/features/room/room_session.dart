import 'dart:async';
import 'dart:collection';

import '../../core/clock_sync.dart';
import '../../data/protocol/client_messages.dart';
import '../../data/protocol/server_messages.dart';
import '../../data/ws/room_transport.dart';
import 'room_state.dart';

/// One visit to a room: turns server messages into [RoomState], keeps the
/// connection alive with pings and estimates the server clock from the replies.
class RoomSession {
  RoomSession({required RoomTransport transport, required int Function() nowMs})
    : _transport = transport,
      _nowMs = nowMs;

  /// Pings right after connecting give the clock offset a few samples fast;
  /// after that one ping every [pingEvery] also keeps idle connections open.
  static const _warmUp = [
    Duration.zero,
    Duration(milliseconds: 400),
    Duration(seconds: 1),
    Duration(seconds: 2),
  ];
  static const pingEvery = Duration(seconds: 25);

  final RoomTransport _transport;
  final int Function() _nowMs;
  final ClockSync _clock = ClockSync();
  final Queue<int> _pingSentAt = Queue();
  final _states = StreamController<RoomState>.broadcast();
  final List<StreamSubscription<dynamic>> _subs = [];
  final List<Timer> _timers = [];
  Timer? _heartbeat;

  RoomState _state = const RoomState();
  RoomState get state => _state;
  Stream<RoomState> get states => _states.stream;

  /// The server's current time, as far as we can tell.
  int serverNowMs() => _clock.serverNow(_nowMs());

  void start() {
    _subs
      ..add(_transport.messages.listen(_onMessage))
      ..add(_transport.status.listen(_onStatus));
    _transport.connect();
  }

  /// Reconnects now, e.g. when the app comes back from the background.
  void reconnect() => _transport.reconnect();

  void _onStatus(SocketStatus s) {
    _emit(_state.copyWith(connection: s));
    _cancelPings();
    if (s == SocketStatus.connected) _startPings();
  }

  void _startPings() {
    for (final d in _warmUp) {
      _timers.add(Timer(d, _ping));
    }
    _heartbeat = Timer.periodic(pingEvery, (_) => _ping());
  }

  void _cancelPings() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _heartbeat?.cancel();
    _heartbeat = null;
    _pingSentAt.clear();
  }

  void _ping() {
    final sentAt = _nowMs();
    if (_transport.send(ClientMessages.ping())) _pingSentAt.add(sentAt);
  }

  void _onMessage(ServerMessage m) {
    switch (m) {
      case StateMessage():
        _emit(
          _state.copyWith(
            timer: m.timer,
            viewers: m.viewers,
            reactions: m.reactions,
            city: m.city,
            location: m.location,
            joined: true,
            clearError: true,
          ),
        );
      case PeopleMessage():
        _emit(_state.copyWith(people: m.people, morePeople: m.more));
      case HostOkMessage():
        _emit(_state.copyWith(isHost: true, clearError: true));
      case ReactionTickMessage():
        _emit(
          _state.copyWith(reactions: {..._state.reactions, m.kind: m.count}),
        );
      case PongMessage():
        if (_pingSentAt.isNotEmpty) {
          _clock.add(
            estimateOffset(
              serverNowMs: m.serverNowMs,
              sentAtMs: _pingSentAt.removeFirst(),
              receivedAtMs: _nowMs(),
            ),
          );
        }
      case ErrorMessage():
        _emit(_state.copyWith(error: m));
      case UnknownMessage():
        break;
    }
  }

  void _emit(RoomState next) {
    _state = next;
    if (!_states.isClosed) _states.add(next);
  }

  // Commands. Only the host's are accepted by the server; the rest answer
  // with `forbidden`, which shows up in [RoomState.error].

  void startTimer({
    required bool focus,
    required int durationMs,
    required String label,
  }) => _transport.send(
    ClientMessages.timerStart(
      focus: focus,
      durationMs: durationMs,
      label: label,
    ),
  );

  void pause() => _transport.send(ClientMessages.timerPause());

  void resume() => _transport.send(ClientMessages.timerResume());

  void reset() => _transport.send(ClientMessages.timerReset());

  void react(String kind) => _transport.send(ClientMessages.reaction(kind));

  void setLocation({
    required String city,
    required double lat,
    required double lon,
    required String tz,
  }) => _transport.send(
    ClientMessages.locationSet(city: city, lat: lat, lon: lon, tz: tz),
  );

  Future<void> dispose() async {
    _cancelPings();
    for (final s in _subs) {
      await s.cancel();
    }
    await _transport.close();
    await _states.close();
  }
}
