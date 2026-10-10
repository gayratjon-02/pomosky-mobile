import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'ui/theme.dart';

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const _HomePlaceholder()),
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

class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Pomosky')));
  }
}
