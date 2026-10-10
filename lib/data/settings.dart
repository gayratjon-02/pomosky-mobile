import 'package:shared_preferences/shared_preferences.dart';

/// The few choices the app remembers between launches.
abstract interface class AppSettings {
  /// Whether the end-of-phase signal plays a sound (the vibration is separate).
  bool get soundEnabled;
  Future<void> setSoundEnabled(bool value);
}

class PreferencesSettings implements AppSettings {
  PreferencesSettings(this._prefs);

  final SharedPreferences _prefs;

  static const _soundKey = 'sound.enabled';

  @override
  bool get soundEnabled => _prefs.getBool(_soundKey) ?? true;

  @override
  Future<void> setSoundEnabled(bool value) => _prefs.setBool(_soundKey, value);
}

/// Settings that live only in memory, for tests and as the default.
class MemorySettings implements AppSettings {
  @override
  bool soundEnabled = true;

  @override
  Future<void> setSoundEnabled(bool value) async => soundEnabled = value;
}
