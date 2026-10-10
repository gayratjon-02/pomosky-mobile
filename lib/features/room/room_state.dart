import '../../data/protocol/server_messages.dart';
import '../../data/ws/room_transport.dart';
import '../../domain/timer_view.dart';

/// Everything the room screens show. Remaining time is not stored: screens
/// compute it from [timer] and the session's server clock.
class RoomState {
  const RoomState({
    this.connection = SocketStatus.connecting,
    this.timer = TimerView.idle,
    this.viewers = 0,
    this.reactions = const {},
    this.city = '',
    this.location,
    this.people = const [],
    this.morePeople = 0,
    this.isHost = false,
    this.error,
    this.joined = false,
    this.clockEpoch = 0,
    this.hostRejected = false,
  });

  final SocketStatus connection;
  final TimerView timer;
  final int viewers;
  final Map<String, int> reactions;
  final String city;
  final LocationView? location;
  final List<PersonView> people;
  final int morePeople;
  final bool isHost;

  /// The last error the server reported; cleared by the next state message.
  final ErrorMessage? error;

  /// True once the first `state` arrived.
  final bool joined;

  /// Counts the times the estimate of the server clock moved noticeably, so
  /// things derived from it (the lock screen countdown) can be recomputed.
  final int clockEpoch;

  /// True when the server refused a host command from a connection that is
  /// not the host: the stored host token is no longer valid.
  final bool hostRejected;

  RoomState copyWith({
    SocketStatus? connection,
    TimerView? timer,
    int? viewers,
    Map<String, int>? reactions,
    String? city,
    LocationView? location,
    List<PersonView>? people,
    int? morePeople,
    bool? isHost,
    ErrorMessage? error,
    bool clearError = false,
    bool? joined,
    int? clockEpoch,
    bool? hostRejected,
  }) => RoomState(
    connection: connection ?? this.connection,
    timer: timer ?? this.timer,
    viewers: viewers ?? this.viewers,
    reactions: reactions ?? this.reactions,
    city: city ?? this.city,
    location: location ?? this.location,
    people: people ?? this.people,
    morePeople: morePeople ?? this.morePeople,
    isHost: isHost ?? this.isHost,
    error: clearError ? null : (error ?? this.error),
    joined: joined ?? this.joined,
    clockEpoch: clockEpoch ?? this.clockEpoch,
    hostRejected: hostRejected ?? this.hostRejected,
  );
}
