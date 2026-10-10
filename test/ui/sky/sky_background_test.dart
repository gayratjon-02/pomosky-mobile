import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/ui/sky/sky_background.dart';
import 'package:pomosky_mobile/ui/sky/sky_inputs.dart';

Widget _app(SkyInputs inputs) => MaterialApp(
  home: SizedBox(
    width: 400,
    height: 800,
    child: SkyBackground(inputs: inputs, child: const Text('hi')),
  ),
);

void main() {
  testWidgets('paints day, night and weather without errors', (tester) async {
    final seoul = DateTime.utc(2026, 10, 10, 3, 20); // noon in Seoul
    for (final when in [
      seoul,
      seoul.add(const Duration(hours: 9)),
      seoul.add(const Duration(hours: 6)),
    ]) {
      await tester.pumpWidget(_app(SkyInputs.forPlace(when, 37.5665, 126.978)));
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pumpWidget(
      _app(const SkyInputs(cloudCoverPct: 100, precipitationMmh: 5)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('hi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stands still when animations are disabled', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: _app(const SkyInputs()),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}
