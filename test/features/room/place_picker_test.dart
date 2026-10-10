import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/data/places_api.dart';
import 'package:pomosky_mobile/features/room/place_picker.dart';

const _seoul = Place(
  name: 'Seoul',
  region: 'Seoul',
  country: 'South Korea',
  lat: 37.56,
  lon: 126.97,
  tz: 'Asia/Seoul',
);

Future<Place?> _open(WidgetTester tester, PlaceSearch search) async {
  Place? picked;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              picked = await showModalBottomSheet<Place>(
                context: context,
                isScrollControlled: true,
                builder: (_) => PlacePicker(search: search),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return picked;
}

void main() {
  testWidgets('waits for a pause in typing, then searches once', (
    tester,
  ) async {
    final queries = <String>[];
    await _open(tester, (q) async {
      queries.add(q);
      return [_seoul];
    });

    await tester.enterText(find.byType(TextField), 'se');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byType(TextField), 'seo');
    await tester.pump(const Duration(milliseconds: 200));
    expect(queries, isEmpty);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(queries, ['seo']);
    expect(find.text('Seoul'), findsOneWidget);
    expect(find.text('South Korea'), findsOneWidget);
  });

  testWidgets('tapping a result returns that place', (tester) async {
    Place? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => picked = await showModalBottomSheet<Place>(
                context: context,
                isScrollControlled: true,
                builder: (_) => PlacePicker(search: (_) async => [_seoul]),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'seoul');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    await tester.tap(find.text('Seoul'));
    await tester.pumpAndSettle();

    expect(picked?.tz, 'Asia/Seoul');
  });

  testWidgets('an empty answer says so; an error shows its message', (
    tester,
  ) async {
    var fail = false;
    await _open(tester, (q) async {
      if (fail) {
        throw const PlaceSearchException('Searching too fast, wait a moment');
      }
      return const [];
    });

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.text('No places found'), findsOneWidget);

    fail = true;
    await tester.enterText(find.byType(TextField), 'zzzzz');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.textContaining('too fast'), findsOneWidget);
    expect(find.text('No places found'), findsNothing);
  });

  testWidgets('an old answer never replaces a newer query', (tester) async {
    await _open(tester, (q) async {
      if (q == 'seo') {
        await Future<void>.delayed(const Duration(seconds: 2));
        return [_seoul];
      }
      return const [];
    });

    await tester.enterText(find.byType(TextField), 'seo');
    await tester.pump(const Duration(milliseconds: 500)); // 'seo' is sent
    await tester.enterText(find.byType(TextField), 'x'); // too short: cleared
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Seoul'), findsNothing);
  });
}
