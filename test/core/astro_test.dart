import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/core/astro.dart';

const _lat = 37.5665;
const _lon = 126.978;

// 2026-10-10 in Seoul (KST = UTC+9).
DateTime kst(int h, [int m = 0]) => DateTime.utc(2026, 10, 10, h - 9, m);

void main() {
  group('sunPosition', () {
    test('is high and south around noon in Seoul in October', () {
      final p = sunPosition(kst(12, 20), _lat, _lon);
      expect(p.elevationDeg, inInclusiveRange(43, 48));
      expect(p.azimuthDeg, inInclusiveRange(170, 190));
    });

    test('rises in the east and sets in the west', () {
      expect(
        sunPosition(kst(7), _lat, _lon).azimuthDeg,
        inInclusiveRange(80, 140),
      );
      expect(
        sunPosition(kst(17), _lat, _lon).azimuthDeg,
        inInclusiveRange(220, 280),
      );
    });

    test('is below the horizon before sunrise and after sunset', () {
      expect(sunPosition(kst(5), _lat, _lon).elevationDeg, lessThan(-5));
      expect(sunPosition(kst(6), _lat, _lon).elevationDeg, lessThan(0));
      expect(sunPosition(kst(7), _lat, _lon).elevationDeg, greaterThan(3));
      expect(sunPosition(kst(17, 30), _lat, _lon).elevationDeg, greaterThan(0));
      expect(sunPosition(kst(18, 30), _lat, _lon).elevationDeg, lessThan(0));
      expect(sunPosition(kst(0), _lat, _lon).elevationDeg, lessThan(-30));
    });

    test('is overhead at the equator on the equinox', () {
      final p = sunPosition(DateTime.utc(2026, 3, 20, 12), 0, 0);
      expect(p.elevationDeg, greaterThan(84));
    });

    test('is mirrored in the southern hemisphere', () {
      final p = sunPosition(DateTime.utc(2026, 12, 21, 1, 30), -33.87, 151.21);
      expect(p.elevationDeg, greaterThan(70));
    });
  });

  group('moonLight', () {
    test('new moon at the reference new moon', () {
      expect(
        moonLight(DateTime.utc(2000, 1, 6, 18, 14)).fraction,
        lessThan(0.03),
      );
    });

    test('full moon at the reference full moon', () {
      final m = moonLight(DateTime.utc(2000, 1, 21, 4, 40));
      expect(m.fraction, greaterThan(0.97));
      expect((m.phase - 0.5).abs(), lessThan(0.03));
    });

    test('about half lit at the first quarter', () {
      final m = moonLight(DateTime.utc(2000, 1, 14));
      expect(m.phase, inInclusiveRange(0.2, 0.3));
      expect(m.fraction, inInclusiveRange(0.4, 0.6));
    });

    test('keeps its values in range', () {
      for (var day = 0; day < 60; day++) {
        final m = moonLight(DateTime.utc(2026, 10, 1 + day));
        expect(m.phase, inInclusiveRange(0, 1));
        expect(m.fraction, inInclusiveRange(0, 1));
      }
    });
  });

  test('the moon moves across the sky', () {
    final a = moonPosition(kst(20), _lat, _lon);
    final b = moonPosition(kst(23), _lat, _lon);
    expect(a.elevationDeg.isFinite, isTrue);
    expect((a.azimuthDeg - b.azimuthDeg).abs(), greaterThan(5));
  });
}
