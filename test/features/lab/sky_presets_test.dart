import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/features/lab/sky_presets.dart';

void main() {
  SkyPreset named(String n) => skyPresets.firstWhere((p) => p.name == n);

  test('every preset has a unique name', () {
    final names = skyPresets.map((p) => p.name).toSet();
    expect(names.length, skyPresets.length);
  });

  test('day presets have the sun up and night has it down', () {
    expect(named('Noon').inputs().sunElevationDeg, greaterThan(40));
    expect(named('Night').inputs().sunElevationDeg, lessThan(-30));
    expect(named('Dusk').inputs().sunElevationDeg, inInclusiveRange(-8, 2));
  });

  test('weather presets carry their weather', () {
    expect(named('Rain').inputs().precipitationMmh, greaterThan(0));
    expect(named('Snow').inputs().snowfallCmh, greaterThan(0));
    expect(named('Storm').inputs().thunder, isTrue);
    expect(named('Fog').inputs().fogDensity, greaterThan(0.5));
    expect(named('Noon').inputs().precipitationMmh, 0);
  });
}
