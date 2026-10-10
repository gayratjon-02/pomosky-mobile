import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pomosky_mobile/app.dart';

/// Against a real server: create a room, become its host, start a timer and
/// control it. Run with
/// `flutter test integration_test/host_flow_test.dart -d <device> --dart-define=BASE_URL=http://localhost:8098`.
/// `--dart-define=HOLD=15` keeps the setup screen up for that many seconds, so
/// it can be captured.
const _hold = int.fromEnvironment('HOLD');

Future<void> _until(WidgetTester tester, Finder finder, String what) async {
  for (var i = 0; i < 75; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 200));
  }
  fail('timed out waiting for $what');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('create a room, start, pause, resume and reset', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PomoskyApp()));
    await tester.tap(find.text('Create a room'));
    await _until(tester, find.text('Start focus'), 'the host controls');
    await tester.pump(const Duration(milliseconds: 600)); // let the page settle
    if (_hold > 0) await tester.pump(const Duration(seconds: _hold));

    await tester.tap(find.text('25'));
    await tester.enterText(find.byType(TextField), 'Integration');
    await tester.tap(find.text('Start focus'));
    await _until(tester, find.text('Pause'), 'the running phase');
    expect(find.text('Integration'), findsOneWidget);
    expect(find.text('Start focus'), findsNothing);

    await tester.tap(find.text('Pause'));
    await _until(tester, find.text('Resume'), 'the pause');
    await tester.tap(find.text('Resume'));
    await _until(tester, find.text('Pause'), 'the resume');

    await tester.tap(find.text('Reset'));
    await _until(tester, find.text('Start focus'), 'the reset');
  });
}
