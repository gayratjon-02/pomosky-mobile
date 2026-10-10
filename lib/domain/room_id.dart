/// Room ids are 8 characters of lowercase base32 (a-z, 2-7), like the server's
/// `room.ID.Valid`.
final _idPattern = RegExp(r'^[a-z2-7]{8}$');

bool isValidRoomId(String id) => _idPattern.hasMatch(id);

/// Pulls a room id out of what a person pastes or types: a bare code, a
/// `/r/{id}` link (with or without `/host`, a query or a fragment), or text
/// with stray spaces and capitals. Returns null when nothing valid is found.
String? parseRoomId(String input) {
  final text = input.trim().toLowerCase();
  if (isValidRoomId(text)) return text;

  final uri = Uri.tryParse(text);
  final segments = uri?.pathSegments ?? const <String>[];
  final at = segments.indexOf('r');
  if (at >= 0 && at + 1 < segments.length) {
    final id = segments[at + 1];
    if (isValidRoomId(id)) return id;
  }
  return null;
}
