import '../../domain/timer_view.dart';

/// The host's rounded place (about 1 km), absent until the host sets one.
class LocationView {
  const LocationView({required this.lat, required this.lon, required this.tz});

  final double lat;
  final double lon;
  final String tz;

  factory LocationView.fromJson(Map<String, dynamic> json) => LocationView(
    lat: (json['lat'] as num).toDouble(),
    lon: (json['lon'] as num).toDouble(),
    tz: json['tz'] as String? ?? 'UTC',
  );
}

class PersonView {
  const PersonView({required this.name, this.avatarUrl});

  final String name;
  final String? avatarUrl;

  factory PersonView.fromJson(Map<String, dynamic> json) => PersonView(
    name: json['name'] as String? ?? '',
    avatarUrl: json['avatarUrl'] as String?,
  );
}

/// A message the server sends. Unknown types decode to [UnknownMessage] so a
/// newer server never crashes an older app.
sealed class ServerMessage {
  const ServerMessage();

  factory ServerMessage.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? '';
    final data = (json['data'] as Map<String, dynamic>?) ?? const {};
    return switch (type) {
      'state' => StateMessage.fromData(data),
      'people' => PeopleMessage.fromData(data),
      'host.ok' => const HostOkMessage(),
      'reaction.tick' => ReactionTickMessage(
        kind: data['kind'] as String? ?? '',
        count: (data['count'] as num?)?.toInt() ?? 0,
      ),
      'pong' => PongMessage((data['serverNowMs'] as num?)?.toInt() ?? 0),
      'error' => ErrorMessage(
        code: data['code'] as String? ?? '',
        message: data['message'] as String? ?? '',
      ),
      _ => UnknownMessage(type),
    };
  }
}

class StateMessage extends ServerMessage {
  const StateMessage({
    required this.roomId,
    required this.timer,
    required this.viewers,
    required this.reactions,
    required this.city,
    this.location,
    required this.serverNowMs,
  });

  final String roomId;
  final TimerView timer;
  final int viewers;
  final Map<String, int> reactions;
  final String city;
  final LocationView? location;
  final int serverNowMs;

  factory StateMessage.fromData(Map<String, dynamic> data) => StateMessage(
    roomId: data['roomId'] as String? ?? '',
    timer: data['timer'] == null
        ? TimerView.idle
        : TimerView.fromJson(data['timer'] as Map<String, dynamic>),
    viewers: (data['viewers'] as num?)?.toInt() ?? 0,
    reactions: {
      for (final e
          in ((data['reactions'] as Map<String, dynamic>?) ?? const {}).entries)
        e.key: (e.value as num).toInt(),
    },
    city: data['city'] as String? ?? '',
    location: data['location'] == null
        ? null
        : LocationView.fromJson(data['location'] as Map<String, dynamic>),
    serverNowMs: (data['serverNowMs'] as num?)?.toInt() ?? 0,
  );
}

class PeopleMessage extends ServerMessage {
  const PeopleMessage({required this.people, required this.more});

  final List<PersonView> people;
  final int more;

  factory PeopleMessage.fromData(Map<String, dynamic> data) => PeopleMessage(
    people: [
      for (final p in (data['people'] as List<dynamic>? ?? const []))
        PersonView.fromJson(p as Map<String, dynamic>),
    ],
    more: (data['more'] as num?)?.toInt() ?? 0,
  );
}

class HostOkMessage extends ServerMessage {
  const HostOkMessage();
}

class ReactionTickMessage extends ServerMessage {
  const ReactionTickMessage({required this.kind, required this.count});

  final String kind;
  final int count;
}

class PongMessage extends ServerMessage {
  const PongMessage(this.serverNowMs);

  final int serverNowMs;
}

class ErrorMessage extends ServerMessage {
  const ErrorMessage({required this.code, required this.message});

  final String code;
  final String message;
}

class UnknownMessage extends ServerMessage {
  const UnknownMessage(this.type);

  final String type;
}
