import 'dart:convert';
import 'dart:io';

import 'config.dart';

/// One result of the place search: where the host's sky is.
class Place {
  const Place({
    required this.name,
    required this.region,
    required this.country,
    required this.lat,
    required this.lon,
    required this.tz,
  });

  final String name;
  final String region;
  final String country;
  final double lat;
  final double lon;
  final String tz;

  factory Place.fromJson(Map<String, dynamic> json) => Place(
    name: json['name'] as String? ?? '',
    region: json['region'] as String? ?? '',
    country: json['country'] as String? ?? '',
    lat: (json['lat'] as num).toDouble(),
    lon: (json['lon'] as num).toDouble(),
    tz: json['tz'] as String? ?? 'UTC',
  );

  /// "Seoul, Seoul, South Korea" without empty or repeated parts.
  String get label {
    final parts = <String>[];
    for (final p in [name, region, country]) {
      if (p.isNotEmpty && !parts.contains(p)) parts.add(p);
    }
    return parts.join(', ');
  }
}

class PlaceSearchException implements Exception {
  const PlaceSearchException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Searches places by name (`GET /api/places?q=`). Queries shorter than two
/// letters return nothing without asking the server. The server limits the
/// rate, so callers should debounce.
Future<List<Place>> searchPlaces(
  String query, {
  String base = baseUrl,
  Duration timeout = const Duration(seconds: 8),
}) async {
  final q = query.trim();
  if (q.runes.length < 2) return const [];
  final client = HttpClient()..connectionTimeout = timeout;
  try {
    final uri = Uri.parse(
      base,
    ).replace(path: '/api/places', queryParameters: {'q': q});
    final request = await client.getUrl(uri).timeout(timeout);
    final response = await request.close().timeout(timeout);
    if (response.statusCode == HttpStatus.tooManyRequests) {
      await response.drain<void>();
      throw const PlaceSearchException('Searching too fast, wait a moment');
    }
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      throw const PlaceSearchException(
        'Place search is not available right now',
      );
    }
    final body = await response.transform(utf8.decoder).join().timeout(timeout);
    final list =
        (jsonDecode(body) as Map<String, dynamic>)['places']
            as List<dynamic>? ??
        const [];
    return [for (final p in list) Place.fromJson(p as Map<String, dynamic>)];
  } on PlaceSearchException {
    rethrow;
  } catch (_) {
    throw const PlaceSearchException('Could not reach the server');
  } finally {
    client.close(force: true);
  }
}
