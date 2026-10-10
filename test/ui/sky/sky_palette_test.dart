import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/ui/sky/sky_palette.dart';

double brightness(double e) =>
    luminance(skyGradient(e).bottom) + luminance(skyGradient(e).top);

double spread(Color c) =>
    [c.r, c.g, c.b].reduce((a, b) => a > b ? a : b) -
    [c.r, c.g, c.b].reduce((a, b) => a < b ? a : b);

void main() {
  test('smoothstep clamps and eases', () {
    expect(smoothstep(0, 10, -5), 0);
    expect(smoothstep(0, 10, 15), 1);
    expect(smoothstep(0, 10, 5), closeTo(0.5, 1e-9));
  });

  test('gets brighter from night up to golden hour', () {
    const elevations = [-30.0, -18.0, -12.0, -6.0, 0.0, 6.0, 12.0];
    for (var i = 1; i < elevations.length; i++) {
      expect(
        brightness(elevations[i]),
        greaterThanOrEqualTo(brightness(elevations[i - 1]) - 1e-9),
      );
    }
  });

  test('is brighter by day than at dusk', () {
    expect(brightness(40), greaterThan(brightness(-6)));
    expect(brightness(40), greaterThan(brightness(-12)));
  });

  test('is very dark at night and bright by day', () {
    expect(luminance(skyGradient(-30).top), lessThan(0.05));
    expect(luminance(skyGradient(45).bottom), greaterThan(0.6));
  });

  test('clamps outside the keyframe range', () {
    expect(skyGradient(-90).top, skyGradient(-18).top);
    expect(skyGradient(90).bottom, skyGradient(60).bottom);
  });

  test('the horizon is warm during sunset', () {
    final c = skyGradient(0).bottom;
    expect(c.r, greaterThan(c.b));
  });

  test('overcast is greyer and no brighter', () {
    final clear = skyGradient(40, 0);
    final grey = skyGradient(40, 1);
    expect(spread(grey.top), lessThan(spread(clear.top)));
    expect(luminance(grey.top), lessThanOrEqualTo(luminance(clear.top) + 0.05));
  });

  test('the sun is orange low and pale high', () {
    final low = sunColor(0);
    final high = sunColor(50);
    expect(low.r, greaterThan(low.b));
    expect(high.b, greaterThan(low.b));
  });

  test('clouds are white by day and dim at night', () {
    expect(luminance(cloudLit(45)), greaterThan(0.9));
    expect(luminance(cloudLit(-30)), lessThan(0.4));
  });
}
