import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/screen_awake.dart';
import 'data/settings.dart';
import 'data/signal_player.dart';
import 'features/room/room_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        appSettingsProvider.overrideWithValue(PreferencesSettings(prefs)),
        signalPlayerProvider.overrideWith((ref) => DeviceSignalPlayer()),
        screenAwakeProvider.overrideWithValue(DeviceScreenAwake()),
      ],
      child: const PomoskyApp(),
    ),
  );
}
