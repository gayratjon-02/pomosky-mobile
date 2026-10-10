import 'dart:io';

import 'config.dart';

enum RoomLookup { found, notFound, unknown }

/// Asks the server whether a room is live: `GET /r/{id}` answers 404 for a
/// room that does not exist. Any other failure (no network, a 5xx) is
/// [RoomLookup.unknown], so the app still tries the socket and its retries.
Future<RoomLookup> lookupRoom(
  String roomId, {
  String base = baseUrl,
  Duration timeout = const Duration(seconds: 6),
}) async {
  final client = HttpClient()..connectionTimeout = timeout;
  try {
    final request = await client
        .getUrl(Uri.parse(base).replace(path: '/r/$roomId'))
        .timeout(timeout);
    request.followRedirects = false;
    final response = await request.close().timeout(timeout);
    await response.drain<void>();
    return switch (response.statusCode) {
      HttpStatus.notFound => RoomLookup.notFound,
      >= 200 && < 400 => RoomLookup.found,
      _ => RoomLookup.unknown,
    };
  } catch (_) {
    return RoomLookup.unknown;
  } finally {
    client.close(force: true);
  }
}
