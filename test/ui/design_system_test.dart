import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/ui/buttons.dart';
import 'package:pomosky_mobile/ui/glass.dart';
import 'package:pomosky_mobile/ui/theme.dart';
import 'package:pomosky_mobile/ui/tokens.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: pomoskyTheme(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('the primary button taps, shows its label and can be disabled', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        PrimaryButton(
          label: 'Start focus',
          icon: Icons.play_arrow_rounded,
          onPressed: () => taps++,
        ),
      ),
    );
    expect(find.text('Start focus'), findsOneWidget);
    await tester.tap(find.text('Start focus'));
    expect(taps, 1);

    await tester.pumpWidget(
      _wrap(const PrimaryButton(label: 'Start focus', onPressed: null)),
    );
    await tester.tap(find.text('Start focus'), warnIfMissed: false);
    expect(taps, 1);
  });

  testWidgets('a busy primary button ignores taps and hides the label', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        PrimaryButton(
          label: 'Create a room',
          busy: true,
          onPressed: () => taps++,
        ),
      ),
    );
    expect(find.text('Create a room'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(PrimaryButton), warnIfMissed: false);
    expect(taps, 0);
  });

  testWidgets('buttons are at least 44 points tall', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(label: 'A', onPressed: () {}),
            GlassButton(label: 'B', onPressed: () {}),
            GlassButton(label: 'C', compact: true, onPressed: () {}),
          ],
        ),
      ),
    );
    for (final label in ['A', 'B', 'C']) {
      final pill = find
          .ancestor(of: find.text(label), matching: find.byType(Container))
          .first;
      expect(tester.getSize(pill).height, greaterThanOrEqualTo(44));
    }
  });

  testWidgets('segments pick one option and say which is selected', (
    tester,
  ) async {
    int? picked;
    await tester.pumpWidget(
      _wrap(
        PillSegments<int>(
          options: const [15, 25, 45],
          selected: 25,
          labelOf: (m) => '$m',
          onChanged: (m) => picked = m,
        ),
      ),
    );
    await tester.tap(find.text('45'));
    expect(picked, 45);
    final semantics = tester.getSemantics(find.text('25'));
    expect(semantics.flagsCollection.isSelected, isNotNull);
  });

  testWidgets('a glass card shows its child', (tester) async {
    await tester.pumpWidget(_wrap(const GlassCard(child: Text('inside'))));
    expect(find.text('inside'), findsOneWidget);
  });

  test('the theme is dark with the apricot accent and a cream text colour', () {
    final theme = pomoskyTheme();
    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.primary, Tint.apricot);
    expect(theme.colorScheme.onSurface, Tint.cream);
    expect(theme.textTheme.displayLarge?.fontWeight, FontWeight.w200);
  });

  test('spacing follows the 4-point scale', () {
    for (final v in [Gap.xs, Gap.s, Gap.m, Gap.l, Gap.xl, Gap.xxl, Gap.huge]) {
      expect(v % 4, 0);
    }
  });
}
