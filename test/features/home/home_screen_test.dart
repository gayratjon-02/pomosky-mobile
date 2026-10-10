import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pomosky_mobile/data/host_tokens.dart';
import 'package:pomosky_mobile/data/room_api.dart';
import 'package:pomosky_mobile/features/home/home_screen.dart';
import 'package:pomosky_mobile/features/room/room_providers.dart';

class _BrokenStore implements HostTokenStore {
  @override
  Future<String?> read(String roomId) async => null;
  @override
  Future<void> write(String roomId, String token) async =>
      throw StateError('keychain locked');
  @override
  Future<void> delete(String roomId) async {}
}

Widget _app(
  List<String> visited, {
  HostTokenStore? store,
  Future<CreatedRoom> Function()? creator,
}) => ProviderScope(
  overrides: [
    hostTokenStoreProvider.overrideWithValue(store ?? MemoryHostTokenStore()),
    if (creator != null) roomCreatorProvider.overrideWithValue(creator),
  ],
  child: MaterialApp.router(
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
    await _settle(tester);
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

  testWidgets('creating a room keeps the host token and opens the room', (
    tester,
  ) async {
    final visited = <String>[];
    final store = MemoryHostTokenStore();
    await tester.pumpWidget(
      _app(
        visited,
        store: store,
        creator: () async =>
            const CreatedRoom(id: 'abcd2345', hostToken: 'secret'),
      ),
    );
    await tester.tap(find.text('Create a room'));
    await _settle(tester);

    expect(await store.read('abcd2345'), 'secret');
    expect(visited, ['abcd2345']);
  });

  testWidgets('a failed creation shows the reason and stays', (tester) async {
    final visited = <String>[];
    await tester.pumpWidget(
      _app(
        visited,
        creator: () async => throw const RoomCreateException('Too many rooms'),
      ),
    );
    await tester.tap(find.text('Create a room'));
    await _settle(tester);

    expect(find.text('Too many rooms'), findsOneWidget);
    expect(visited, isEmpty);
  });

  testWidgets(
    'a host key that cannot be saved is reported, not lost silently',
    (tester) async {
      final visited = <String>[];
      await tester.pumpWidget(
        _app(
          visited,
          store: _BrokenStore(),
          creator: () async =>
              const CreatedRoom(id: 'abcd2345', hostToken: 'secret'),
        ),
      );
      await tester.tap(find.text('Create a room'));
      await _settle(tester);

      expect(
        find.textContaining('Could not save the host key'),
        findsOneWidget,
      );
      expect(visited, isEmpty);
      // The button works again for another try.
      expect(find.text('Create a room'), findsOneWidget);
    },
  );

  testWidgets('fits a small phone with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 568),
          textScaler: TextScaler.linear(1.5),
        ),
        child: _app(<String>[]),
      ),
    );
    await _settle(tester);

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Join room'));
    expect(find.text('Join room').hitTestable(), findsOneWidget);
  });
}

/// The home screen sits on the live sky, which animates forever, so
/// pumpAndSettle would never return.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}
