import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/app.dart';

void main() {
  testWidgets('app starts on the home screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PomoskyApp()));
    // The live sky never settles, so pump a moment instead.
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Pomosky'), findsOneWidget);
  });

  test('parses a forced viewport and refuses nonsense', () {
    expect(parseViewport('320x568'), const Size(320, 568));
    expect(parseViewport('375.5x667'), const Size(375.5, 667));
    expect(parseViewport(''), isNull);
    expect(parseViewport('320'), isNull);
    expect(parseViewport('axb'), isNull);
    expect(parseViewport('10x10'), isNull);
  });
}
