import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/home/home_screen.dart';
import 'features/lab/sky_lab_screen.dart';
import 'features/room/room_screen.dart';
import 'ui/theme.dart';

/// Development only: `--dart-define=INITIAL_ROUTE=/r/<id>` opens that room at
/// launch, so a simulator does not need typing.
const _initialRoute = String.fromEnvironment(
  'INITIAL_ROUTE',
  defaultValue: '/',
);

/// Development only: `--dart-define=FORCE_VIEWPORT=320x568` shows the app in a
/// window of that logical size, centred on the screen, to check small phones
/// that no current simulator offers. Ignored outside debug builds.
const _forceViewport = String.fromEnvironment('FORCE_VIEWPORT');

/// Parses "WIDTHxHEIGHT"; null for anything else.
Size? parseViewport(String value) {
  final parts = value.split('x');
  if (parts.length != 2) return null;
  final w = double.tryParse(parts[0]);
  final h = double.tryParse(parts[1]);
  if (w == null || h == null || w < 200 || h < 300) return null;
  return Size(w, h);
}

Widget _inViewport(Widget app, Size size) => ColoredBox(
  color: const Color(0xFF000000),
  child: Center(
    child: ClipRect(
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: MediaQuery(
          data: MediaQueryData(size: size, padding: EdgeInsets.zero),
          child: app,
        ),
      ),
    ),
  ),
);

GoRouter _buildRouter() => GoRouter(
  initialLocation: _initialRoute,
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    if (kDebugMode)
      GoRoute(
        path: '/sky-lab',
        builder: (context, state) => SkyLabScreen(
          initial: state.uri.queryParameters['preset'],
          autoCycle: state.uri.queryParameters['auto'] == '1',
        ),
      ),
    GoRoute(
      path: '/r/:id',
      builder: (context, state) =>
          RoomScreen(roomId: state.pathParameters['id']!),
    ),
  ],
);

class PomoskyApp extends StatefulWidget {
  const PomoskyApp({super.key});

  @override
  State<PomoskyApp> createState() => _PomoskyAppState();
}

class _PomoskyAppState extends State<PomoskyApp> {
  // Owned by the app, not a global, so a rebuilt app starts at the home screen.
  late final GoRouter _router = _buildRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pomosky',
      theme: pomoskyTheme(),
      routerConfig: _router,
      builder: (context, child) {
        final size = kDebugMode ? parseViewport(_forceViewport) : null;
        return size == null || child == null
            ? child ?? const SizedBox()
            : _inViewport(child, size);
      },
    );
  }
}
