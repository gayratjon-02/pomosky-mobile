import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where host tokens are kept. A token is shown only once by the server, so
/// losing it means losing control of the room.
abstract interface class HostTokenStore {
  Future<String?> read(String roomId);
  Future<void> write(String roomId, String token);
  Future<void> delete(String roomId);
}

/// Stores tokens in the system keychain / keystore, never in plain files and
/// never in logs or URLs.
class SecureHostTokenStore implements HostTokenStore {
  SecureHostTokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  String _key(String roomId) => 'host-token.$roomId';

  @override
  Future<String?> read(String roomId) async {
    // A locked keychain (a launch in the background) must not stop the room
    // from opening: without the token this phone is simply a viewer.
    try {
      return await _storage.read(key: _key(roomId));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String roomId, String token) =>
      _storage.write(key: _key(roomId), value: token);

  @override
  Future<void> delete(String roomId) => _storage.delete(key: _key(roomId));
}

/// A store that lives only in memory, for tests.
class MemoryHostTokenStore implements HostTokenStore {
  final Map<String, String> _tokens = {};

  @override
  Future<String?> read(String roomId) async => _tokens[roomId];

  @override
  Future<void> write(String roomId, String token) async =>
      _tokens[roomId] = token;

  @override
  Future<void> delete(String roomId) async => _tokens.remove(roomId);
}
