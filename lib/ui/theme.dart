import 'package:flutter/material.dart';

import 'tokens.dart';

/// The app is dark only: it sits on a night sky.
ThemeData pomoskyTheme() {
  const scheme = ColorScheme.dark(
    primary: Tint.apricot,
    onPrimary: Night.background,
    secondary: Tint.sky,
    onSecondary: Night.background,
    tertiary: Tint.mint,
    surface: Night.surface,
    onSurface: Tint.cream,
    onSurfaceVariant: Tint.creamDim,
    outline: Glass.edge,
    outlineVariant: Color(0x14FFFFFF),
    error: Tint.rose,
    onError: Night.background,
    surfaceContainerHighest: Night.raised,
  );

  // The system font, shaped: tight tracking on large text, open tracking on
  // small caps, and calm weights.
  const text = TextTheme(
    displayLarge: TextStyle(
      fontSize: 76,
      fontWeight: FontWeight.w200,
      letterSpacing: -2,
      height: 1,
    ),
    displayMedium: TextStyle(
      fontSize: 52,
      fontWeight: FontWeight.w300,
      letterSpacing: -1.2,
      height: 1.05,
    ),
    displaySmall: TextStyle(
      fontSize: 38,
      fontWeight: FontWeight.w600,
      letterSpacing: -1,
      height: 1.1,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.6,
    ),
    headlineSmall: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.4,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    bodyLarge: TextStyle(fontSize: 17, height: 1.35),
    bodyMedium: TextStyle(fontSize: 15, height: 1.35),
    bodySmall: TextStyle(fontSize: 13, height: 1.3, letterSpacing: 0.1),
    labelLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
    ),
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: Night.background,
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
  );

  return base.copyWith(
    textTheme: text.apply(bodyColor: Tint.cream, displayColor: Tint.cream),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      foregroundColor: Tint.cream,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: Tint.cream,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Glass.fill,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Gap.l,
        vertical: Gap.m + 2,
      ),
      hintStyle: const TextStyle(color: Tint.creamFaint),
      labelStyle: const TextStyle(color: Tint.creamDim),
      floatingLabelStyle: const TextStyle(color: Tint.apricot),
      border: _inputBorder(Glass.edge),
      enabledBorder: _inputBorder(Glass.edge),
      focusedBorder: _inputBorder(Tint.apricot, width: 1.5),
      errorBorder: _inputBorder(Tint.rose),
      focusedErrorBorder: _inputBorder(Tint.rose, width: 1.5),
      errorStyle: const TextStyle(color: Tint.rose),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Night.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: const BorderSide(color: Glass.edge),
      ),
      titleTextStyle: text.titleLarge?.copyWith(color: Tint.cream),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Night.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: Tint.creamFaint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Night.raised,
      contentTextStyle: const TextStyle(color: Tint.cream, fontSize: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.chip),
        side: const BorderSide(color: Glass.edge),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Night.raised,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.chip + 2),
        side: const BorderSide(color: Glass.edge),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Glass.edge, space: 1),
    listTileTheme: const ListTileThemeData(
      iconColor: Tint.creamDim,
      textColor: Tint.cream,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Tint.apricot,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Tint.sky,
        textStyle: text.labelLarge,
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(Radii.chip + 2),
      borderSide: BorderSide(color: color, width: width),
    );
