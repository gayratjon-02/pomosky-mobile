import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/ui/sky/sky_inputs.dart';

void main() {
  test('the sun is up in Seoul at noon and down at midnight', () {
    final noon = SkyInputs.forPlace(
      DateTime.utc(2026, 10, 10, 3, 20),
      37.5665,
      126.978,
    );
    final night = SkyInputs.forPlace(
      DateTime.utc(2026, 10, 10, 15),
      37.5665,
      126.978,
    );
    expect(noon.sunElevationDeg, greaterThan(40));
    expect(night.sunElevationDeg, lessThan(-30));
  });

  test('overcast grows with cloud cover and rain', () {
    const clear = SkyInputs();
    const cloudy = SkyInputs(cloudCoverPct: 100);
    const rainy = SkyInputs(cloudCoverPct: 100, precipitationMmh: 6);
    expect(clear.overcast, 0);
    expect(cloudy.overcast, closeTo(1, 1e-9));
    expect(rainy.overcast, 1);
    expect(
      const SkyInputs(cloudCoverPct: 50).overcast,
      inInclusiveRange(0.3, 0.5),
    );
  });

  test('withWeather keeps the astronomy', () {
    final base = SkyInputs.forPlace(DateTime.utc(2026, 10, 10, 3), 37.5, 127);
    final wet = base.withWeather(
      cloudCoverPct: 90,
      precipitationMmh: 3,
      snowfallCmh: 0,
      windSpeedKmh: 20,
      windDirDeg: 300,
      fogDensity: 0.1,
      thunder: false,
    );
    expect(wet.sunElevationDeg, base.sunElevationDeg);
    expect(wet.cloudCoverPct, 90);
  });

  test('skyPoint puts the south sun in the middle, east left, west right', () {
    const size = Size(1000, 800);
    final south = skyPoint(size, 640, 180, 0);
    final east = skyPoint(size, 640, 90, 0);
    final west = skyPoint(size, 640, 270, 0);
    expect(south.dx, 500);
    expect(south.dy, 640);
    expect(east.dx, lessThan(south.dx));
    expect(west.dx, greaterThan(south.dx));
    expect(skyPoint(size, 640, 180, 35).dy, lessThan(640));
  });
}
