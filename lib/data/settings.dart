import 'package:shared_preferences/shared_preferences.dart';

/// The few choices the app remembers between launches.
abstract interface class AppSettings {
  /// Whether the end-of-phase signal plays a sound (the vibration is separate).
  bool get soundEnabled;
  Future<void> setSoundEnabled(bool value);

  /// The name other people see in a room; empty means anonymous.
  String get nickname;
  Future<void> setNickname(String value);
}

class PreferencesSettings implements AppSettings {
  PreferencesSettings(this._prefs);

  final SharedPreferences _prefs;

  static const _soundKey = 'sound.enabled';
  static const _nicknameKey = 'nickname';

  @override
  bool get soundEnabled => _prefs.getBool(_soundKey) ?? true;

  @override
  Future<void> setSoundEnabled(bool value) => _prefs.setBool(_soundKey, value);

  @override
  String get nickname => _prefs.getString(_nicknameKey) ?? '';

  @override
  Future<void> setNickname(String value) =>
      _prefs.setString(_nicknameKey, value);
}

/// Settings that live only in memory, for tests and as the default.
class MemorySettings implements AppSettings {
  @override
  bool soundEnabled = true;

  @override
  Future<void> setSoundEnabled(bool value) async => soundEnabled = value;

  @override
  String nickname = '';

  @override
  Future<void> setNickname(String value) async => nickname = value;
}
