import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen on while a phase runs, so the countdown stays in view.
abstract interface class ScreenAwake {
  Future<void> set(bool on);
}

/// Does nothing; the default in tests.
class NoScreenAwake implements ScreenAwake {
  @override
  Future<void> set(bool on) async {}
}

class DeviceScreenAwake implements ScreenAwake {
  @override
  Future<void> set(bool on) async {
    try {
      await WakelockPlus.toggle(enable: on);
    } catch (_) {
      // Not supported everywhere; the timer works without it.
    }
  }
}
