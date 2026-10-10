import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/live_activity/ios_live_timer_activity.dart';
import 'data/phase_notifier.dart';
import 'data/screen_awake.dart';
import 'data/settings.dart';
import 'data/signal_player.dart';
import 'features/room/live_timer_providers.dart';
import 'features/room/room_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final notifier = await LocalPhaseNotifier.create();
  runApp(
    ProviderScope(
      overrides: [
        appSettingsProvider.overrideWithValue(PreferencesSettings(prefs)),
        signalPlayerProvider.overrideWith((ref) => DeviceSignalPlayer()),
        screenAwakeProvider.overrideWithValue(DeviceScreenAwake()),
        phaseNotifierProvider.overrideWithValue(notifier),
        if (!kIsWeb && Platform.isIOS)
          liveTimerActivityProvider.overrideWithValue(IosLiveTimerActivity()),
      ],
      child: const PomoskyApp(),
    ),
  );
}
