import 'dart:io';

import '../domain/room_id.dart';
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

class CreatedRoom {
  const CreatedRoom({required this.id, required this.hostToken});

  final String id;

  /// Shown once by the server; the app keeps it in secure storage.
  final String hostToken;
}

class RoomCreateException implements Exception {
  const RoomCreateException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Creates a room. The website's form is protected by a double-submit CSRF
/// cookie, so the app first reads the cookie from a page and sends it back as
/// the `X-CSRF-Token` header. The host token comes back in the fragment of the
/// redirect to `/r/{id}/host#token=...`.
Future<CreatedRoom> createRoom({
  String base = baseUrl,
  Duration timeout = const Duration(seconds: 8),
}) async {
  final client = HttpClient()..connectionTimeout = timeout;
  try {
    final home = await (await client.getUrl(Uri.parse(base)).timeout(timeout))
        .close()
        .timeout(timeout);
    await home.drain<void>();
    final csrf = home.cookies
        .where((c) => c.name == 'pomosky_csrf')
        .map((c) => c.value)
        .firstOrNull;
    if (csrf == null) {
      throw const RoomCreateException('The server did not give a CSRF token');
    }

    final request = await client
        .postUrl(Uri.parse(base).replace(path: '/r/new'))
        .timeout(timeout);
    request.followRedirects = false;
    request.headers
      ..set('X-CSRF-Token', csrf)
      ..set(HttpHeaders.cookieHeader, 'pomosky_csrf=$csrf');
    final response = await request.close().timeout(timeout);
    await response.drain<void>();

    if (response.statusCode == HttpStatus.tooManyRequests) {
      throw const RoomCreateException('Too many rooms, try again in a moment');
    }
    final location = response.headers.value(HttpHeaders.locationHeader);
    final created = location == null ? null : _parseHostLocation(location);
    if (created == null) {
      throw RoomCreateException(
        'Could not create a room (HTTP ${response.statusCode})',
      );
    }
    return created;
  } on RoomCreateException {
    rethrow;
  } catch (_) {
    throw const RoomCreateException('Could not reach the server');
  } finally {
    client.close(force: true);
  }
}

CreatedRoom? _parseHostLocation(String location) {
  final uri = Uri.parse(location);
  final id = parseRoomId(uri.path);
  final token = Uri.splitQueryString(uri.fragment)['token'];
  if (id == null || token == null || token.isEmpty) return null;
  return CreatedRoom(id: id, hostToken: token);
}
