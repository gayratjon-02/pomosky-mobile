// Sun and moon positions from latitude, longitude and time.
//
// The formulas follow the widely used SunCalc algorithm (Vladimir Agafonkin,
// BSD-2-Clause), which is based on "Astronomy Answers" by Louis Strous. They
// are accurate to a fraction of a degree, which is far more than a sky
// animation needs. Everything is computed locally; no network is involved.
// This is a port of the website's `web/src/sky/astro.ts`.

import 'dart:math' as math;

const _rad = math.pi / 180;
const _dayMs = 86400000;
const _j1970 = 2440588;
const _j2000 = 2451545;
const _obliquity = _rad * 23.4397;

double _toDays(DateTime date) =>
    date.millisecondsSinceEpoch / _dayMs - 0.5 + _j1970 - _j2000;

double _rightAscension(double l, double b) => math.atan2(
  math.sin(l) * math.cos(_obliquity) - math.tan(b) * math.sin(_obliquity),
  math.cos(l),
);

double _declination(double l, double b) => math.asin(
  math.sin(b) * math.cos(_obliquity) +
      math.cos(b) * math.sin(_obliquity) * math.sin(l),
);

// Azimuth in radians from the south towards the west (SunCalc convention).
double _azimuth(double h, double phi, double dec) => math.atan2(
  math.sin(h),
  math.cos(h) * math.sin(phi) - math.tan(dec) * math.cos(phi),
);

double _altitude(double h, double phi, double dec) => math.asin(
  math.sin(phi) * math.sin(dec) + math.cos(phi) * math.cos(dec) * math.cos(h),
);

double _siderealTime(double d, double lw) =>
    _rad * (280.16 + 360.9856235 * d) - lw;

double _solarMeanAnomaly(double d) => _rad * (357.5291 + 0.98560028 * d);

double _eclipticLongitude(double m) {
  final c =
      _rad *
      (1.9148 * math.sin(m) +
          0.02 * math.sin(2 * m) +
          0.0003 * math.sin(3 * m));
  const perihelion = _rad * 102.9372;
  return m + c + perihelion + math.pi;
}

({double dec, double ra}) _sunCoords(double d) {
  final l = _eclipticLongitude(_solarMeanAnomaly(d));
  return (dec: _declination(l, 0), ra: _rightAscension(l, 0));
}

({double ra, double dec, double dist}) _moonCoords(double d) {
  final l = _rad * (218.316 + 13.176396 * d);
  final m = _rad * (134.963 + 13.064993 * d);
  final f = _rad * (93.272 + 13.22935 * d);
  final lon = l + _rad * 6.289 * math.sin(m);
  final lat = _rad * 5.128 * math.sin(f);
  return (
    ra: _rightAscension(lon, lat),
    dec: _declination(lon, lat),
    dist: 385001 - 20905 * math.cos(m), // km
  );
}

/// Where a body is in the sky. Azimuth is a compass bearing: 0 north, 90 east,
/// 180 south.
class SkyPosition {
  const SkyPosition({required this.elevationDeg, required this.azimuthDeg});

  final double elevationDeg;
  final double azimuthDeg;
}

double _compass(double azimuthFromSouth) =>
    (azimuthFromSouth / _rad + 180 + 360) % 360;

SkyPosition _position(
  ({double dec, double ra}) c,
  double d,
  double latDeg,
  double lonDeg,
) {
  final lw = _rad * -lonDeg;
  final phi = _rad * latDeg;
  final h = _siderealTime(d, lw) - c.ra;
  return SkyPosition(
    elevationDeg: _altitude(h, phi, c.dec) / _rad,
    azimuthDeg: _compass(_azimuth(h, phi, c.dec)),
  );
}

/// Sun position for a place and moment (latitude and longitude in degrees,
/// east positive). [date] is an absolute instant, so its zone does not matter.
SkyPosition sunPosition(DateTime date, double latDeg, double lonDeg) {
  final d = _toDays(date);
  return _position(_sunCoords(d), d, latDeg, lonDeg);
}

/// Moon position for a place and moment (no atmospheric refraction).
SkyPosition moonPosition(DateTime date, double latDeg, double lonDeg) {
  final d = _toDays(date);
  final m = _moonCoords(d);
  return _position((dec: m.dec, ra: m.ra), d, latDeg, lonDeg);
}

class MoonLight {
  const MoonLight({required this.phase, required this.fraction});

  /// Lunar cycle: 0 new moon, 0.25 first quarter, 0.5 full, 0.75 last quarter.
  final double phase;

  /// Illuminated fraction of the disc, 0..1.
  final double fraction;
}

/// Phase and lit fraction of the moon; it does not depend on the observer.
MoonLight moonLight(DateTime date) {
  final d = _toDays(date);
  final s = _sunCoords(d);
  final m = _moonCoords(d);
  const sunDistance = 149598000; // km

  final phi = math.acos(
    math.sin(s.dec) * math.sin(m.dec) +
        math.cos(s.dec) * math.cos(m.dec) * math.cos(s.ra - m.ra),
  );
  final inc = math.atan2(
    sunDistance * math.sin(phi),
    m.dist - sunDistance * math.cos(phi),
  );
  final angle = math.atan2(
    math.cos(s.dec) * math.sin(s.ra - m.ra),
    math.sin(s.dec) * math.cos(m.dec) -
        math.cos(s.dec) * math.sin(m.dec) * math.cos(s.ra - m.ra),
  );

  return MoonLight(
    fraction: (1 + math.cos(inc)) / 2,
    phase: 0.5 + (0.5 * inc * (angle < 0 ? -1 : 1)) / math.pi,
  );
}
