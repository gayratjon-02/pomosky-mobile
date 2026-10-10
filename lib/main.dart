import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/live_activity/ios_live_timer_activity.dart';
import 'features/room/live_timer_providers.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        if (!kIsWeb && Platform.isIOS)
          liveTimerActivityProvider.overrideWithValue(IosLiveTimerActivity()),
      ],
      child: const PomoskyApp(),
    ),
  );
}
