import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/home/home_screen.dart';
import 'features/room/room_screen.dart';
import 'ui/theme.dart';

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/r/:id',
      builder: (context, state) =>
          RoomScreen(roomId: state.pathParameters['id']!),
    ),
  ],
);

class PomoskyApp extends StatelessWidget {
  const PomoskyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pomosky',
      theme: pomoskyTheme(),
      routerConfig: _router,
    );
  }
}
