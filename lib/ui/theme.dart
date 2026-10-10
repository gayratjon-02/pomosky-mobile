import 'package:flutter/material.dart';

/// The app is dark only for now: it sits on a night-sky background.
ThemeData pomoskyTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6C8CFF),
      brightness: Brightness.dark,
    ),
  );
}
