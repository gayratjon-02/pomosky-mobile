import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/data/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('sound is on by default and the choice is remembered', () async {
    SharedPreferences.setMockInitialValues({});
    final first = PreferencesSettings(await SharedPreferences.getInstance());
    expect(first.soundEnabled, isTrue);

    await first.setSoundEnabled(false);
    // A new instance on the same storage, like the next launch.
    final next = PreferencesSettings(await SharedPreferences.getInstance());
    expect(next.soundEnabled, isFalse);
  });

  test('memory settings behave the same way', () async {
    final s = MemorySettings();
    expect(s.soundEnabled, isTrue);
    await s.setSoundEnabled(false);
    expect(s.soundEnabled, isFalse);
  });

  test('the nickname is remembered and starts empty', () async {
    SharedPreferences.setMockInitialValues({});
    final first = PreferencesSettings(await SharedPreferences.getInstance());
    expect(first.nickname, '');
    await first.setNickname('Ayla');
    final next = PreferencesSettings(await SharedPreferences.getInstance());
    expect(next.nickname, 'Ayla');
  });
}
