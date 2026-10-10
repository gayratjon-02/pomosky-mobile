import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/features/room/nickname_dialog.dart';

Future<void> _open(
  WidgetTester tester,
  String initial,
  void Function(String?) onResult,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => onResult(
            await showDialog<String>(
              context: context,
              builder: (_) => NicknameDialog(initial: initial),
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('saves the trimmed name', (tester) async {
    String? result = 'untouched';
    await _open(tester, '', (r) => result = r);
    await tester.enterText(find.byType(TextField), '  Ayla ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result, 'Ayla');
  });

  testWidgets('a name the server would refuse shows why and stays open', (
    tester,
  ) async {
    String? result = 'untouched';
    await _open(tester, '', (r) => result = r);
    await tester.enterText(find.byType(TextField), 'A');
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Use 2 to 24 characters'), findsOneWidget);
    expect(result, 'untouched');
  });

  testWidgets('cancel returns nothing', (tester) async {
    String? result = 'untouched';
    await _open(tester, 'Ayla', (r) => result = r);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('a named viewer can go back to anonymous', (tester) async {
    String? result = 'untouched';
    await _open(tester, 'Ayla', (r) => result = r);
    await tester.tap(find.text('Be anonymous'));
    await tester.pumpAndSettle();
    expect(result, '');
  });

  testWidgets('an anonymous viewer is not offered that button', (tester) async {
    await _open(tester, '', (_) {});
    expect(find.text('Be anonymous'), findsNothing);
  });
}
