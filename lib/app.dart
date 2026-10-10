import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/home/home_screen.dart';
import 'features/room/room_screen.dart';
import 'ui/theme.dart';

GoRouter _buildRouter() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
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
