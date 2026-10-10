import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pomosky_mobile/features/home/home_screen.dart';

Widget _app(List<String> visited) => MaterialApp.router(
  routerConfig: GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: '/r/:id',
        builder: (_, state) {
          visited.add(state.pathParameters['id']!);
          return const Scaffold(body: Text('room'));
        },
      ),
    ],
  ),
);

void main() {
  testWidgets('a pasted link opens that room', (tester) async {
    final visited = <String>[];
    await tester.pumpWidget(_app(visited));
    await tester.enterText(
      find.byType(TextField),
      'https://pomosky.example/r/abcd2345?utm_source=telegram',
    );
    await tester.tap(find.text('Join room'));
    await tester.pumpAndSettle();
    expect(visited, ['abcd2345']);
  });

  testWidgets('a bad code shows an error and stays', (tester) async {
    final visited = <String>[];
    await tester.pumpWidget(_app(visited));
    await tester.enterText(find.byType(TextField), 'nope');
    await tester.tap(find.text('Join room'));
    await tester.pump();
    expect(find.textContaining('8-letter'), findsOneWidget);
    expect(visited, isEmpty);
  });
}
