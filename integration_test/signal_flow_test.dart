import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pomosky_mobile/app.dart';
import 'package:pomosky_mobile/data/signal_player.dart';
import 'package:pomosky_mobile/features/room/room_providers.dart';

/// Against a real server: a room whose host started a short phase just before
/// this test runs. The app joins as a viewer and must ring exactly once when
/// the phase ends. Run with
/// `flutter test integration_test/signal_flow_test.dart -d <device> --dart-define=BASE_URL=http://localhost:8098 --dart-define=ROOM=<id>`.
const _room = String.fromEnvironment('ROOM');

class _CountingPlayer implements SignalPlayer {
  final rings = <DateTime>[];

  @override
  Future<void> ring({required bool sound}) async => rings.add(DateTime.now());

  @override
  Future<void> stop() async {}
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('rings once when the phase of a real room ends', (tester) async {
    final player = _CountingPlayer();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [signalPlayerProvider.overrideWithValue(player)],
        child: const PomoskyApp(),
      ),
    );
    await tester.enterText(find.byType(TextField), _room);
    await tester.tap(find.text('Join room'));

    // The phase is running when we arrive.
    for (var i = 0; i < 50 && find.text('Focus').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('Focus'), findsOneWidget);
    expect(player.rings, isEmpty);

    // Wait for the end (the script's phase is 40 s long), then a little more:
    // it must not ring twice.
    for (var i = 0; i < 300 && player.rings.isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(player.rings.length, 1, reason: 'the phase should ring once');
    await tester.pump(const Duration(seconds: 3));
    expect(player.rings.length, 1);
    expect(find.text('00:00'), findsOneWidget);
  });
}
