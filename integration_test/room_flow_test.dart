import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pomosky_mobile/app.dart';

/// Runs against a real server: start one, create a room, let its host start a
/// timer, then run with
/// `flutter test integration_test -d <device> --dart-define=BASE_URL=http://localhost:8098 --dart-define=ROOM=<id>`.
const _room = String.fromEnvironment('ROOM');

/// Seconds to keep the final screen up, so it can be looked at or captured.
const _hold = int.fromEnvironment('HOLD');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('join a live room and see its running timer', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PomoskyApp()));
    await tester.enterText(find.byType(TextField), _room);
    await tester.tap(find.text('Join room'));

    final clock = RegExp(r'^\d\d:\d\d$');
    var seen = false;
    for (var i = 0; i < 50 && !seen; i++) {
      await tester.pump(const Duration(milliseconds: 200));
      seen =
          find.text('Focus').evaluate().isNotEmpty &&
          find
              .byWidgetPredicate(
                (w) => w is Text && clock.hasMatch(w.data ?? ''),
              )
              .evaluate()
              .isNotEmpty;
    }
    expect(seen, isTrue, reason: 'the room never showed a running focus timer');
    expect(find.text('Seoul'), findsOneWidget);

    // The countdown keeps moving.
    String shown() => tester
        .widgetList<Text>(
          find.byWidgetPredicate(
            (w) => w is Text && clock.hasMatch(w.data ?? ''),
          ),
        )
        .first
        .data!;
    final first = shown();
    await tester.pump(const Duration(seconds: 3));
    expect(shown(), isNot(first));

    // A reaction goes to the server and comes back as a bigger count.
    int claps() => int.parse(
      tester.widget<Text>(find.textContaining('👏')).data!.split(' ').last,
    );
    final before = claps();
    await tester.tap(find.textContaining('👏'));
    await tester.pump(const Duration(seconds: 1));
    expect(claps(), before + 1);

    if (_hold > 0) await tester.pump(const Duration(seconds: _hold));
  });

  testWidgets('an unknown room says so', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PomoskyApp()));
    await tester.enterText(find.byType(TextField), 'aaaaaaaa');
    await tester.tap(find.text('Join room'));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('Room not found'), findsOneWidget);
  });
}
