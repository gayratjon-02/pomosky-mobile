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
}
