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
    );
  }
}
