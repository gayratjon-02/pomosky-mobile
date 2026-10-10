import 'package:flutter/painting.dart';

// Port of the website's `web/src/sky/palette.ts`: sky colours follow the sun's
// elevation above the horizon, in degrees, interpolated smoothly between
// keyframes.

double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

/// 0 below [a], 1 above [b], smooth in between.
double smoothstep(double a, double b, double x) {
  final t = _clamp01((x - a) / (b - a));
  return t * t * (3 - 2 * t);
}

Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

/// Perceived brightness 0..1 (the same weights the website uses).
double luminance(Color c) => 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;

/// Moves a colour towards its own grey (amount 0..1) and scales brightness.
Color desaturate(Color c, double amount, [double brightness = 1]) {
  final grey = luminance(c);
  final m = mix(
    c,
    Color.from(alpha: 1, red: grey, green: grey, blue: grey),
    _clamp01(amount),
  );
  return Color.from(
    alpha: 1,
    red: _clamp01(m.r * brightness),
    green: _clamp01(m.g * brightness),
    blue: _clamp01(m.b * brightness),
  );
}

class _Key {
  const _Key(this.e, this.top, this.mid, this.bottom);

  final double e;
  final Color top;
  final Color mid;
  final Color bottom;
}

const _keys = [
  _Key(-18, Color(0xFF02030F), Color(0xFF050A22), Color(0xFF0A1236)), // night
  _Key(
    -12,
    Color(0xFF060B2A),
    Color(0xFF101A4D),
    Color(0xFF27306B),
  ), // nautical twilight
  _Key(
    -6,
    Color(0xFF17236A),
    Color(0xFF4A3F86),
    Color(0xFFC4607A),
  ), // dusk / dawn
  _Key(
    -1,
    Color(0xFF2D3F94),
    Color(0xFFA15F9D),
    Color(0xFFFF9A62),
  ), // sunrise / sunset
  _Key(4, Color(0xFF3F62B8), Color(0xFFC98FB0), Color(0xFFFFC27A)),
  _Key(
    12,
    Color(0xFF3F7FD0),
    Color(0xFF8FB9E8),
    Color(0xFFFFE1B0),
  ), // golden hour
  _Key(28, Color(0xFF2B7AD8), Color(0xFF6FB2EF), Color(0xFFB4DBFF)), // day
  _Key(
    60,
    Color(0xFF1566CC),
    Color(0xFF4EA1EE),
    Color(0xFFA3D1FF),
  ), // high noon
];

class SkyGradient {
  const SkyGradient({
    required this.top,
    required this.mid,
    required this.bottom,
  });

  final Color top;
  final Color mid;
  final Color bottom;
}

/// Sky gradient for a sun elevation. [overcast] (0 clear .. 1 fully overcast)
/// greys and darkens the sky the way a cloud deck does.
SkyGradient skyGradient(double sunElevationDeg, [double overcast = 0]) {
  final e = sunElevationDeg.clamp(_keys.first.e, _keys.last.e).toDouble();
  var i = 0;
  while (i < _keys.length - 2 && e > _keys[i + 1].e) {
    i++;
  }
  final a = _keys[i];
  final b = _keys[i + 1];
  final t = smoothstep(a.e, b.e, e);

  final g = SkyGradient(
    top: mix(a.top, b.top, t),
    mid: mix(a.mid, b.mid, t),
    bottom: mix(a.bottom, b.bottom, t),
  );
  if (overcast <= 0) return g;

  // Overcast skies are greyer and a little darker, but never go flat.
  final amount = 0.75 * overcast;
  final dim = 1 - 0.18 * overcast;
  return SkyGradient(
    top: desaturate(g.top, amount, dim),
    mid: desaturate(g.mid, amount, dim),
    bottom: desaturate(g.bottom, amount * 0.9, dim),
  );
}

/// The sun disc: deep orange near the horizon, white-yellow when high.
Color sunColor(double sunElevationDeg) => mix(
  const Color(0xFFFF7A2E),
  const Color(0xFFFFF6DC),
  smoothstep(-2, 25, sunElevationDeg),
);

/// The lit side of clouds: pink-gold at sunrise/sunset, white by day, blue at night.
Color cloudLit(double sunElevationDeg) {
  const night = Color(0xFF3A4778);
  const twilight = Color(0xFFFFB899);
  const day = Color(0xFFFFFFFF);
  final toTwilight = smoothstep(-14, 0, sunElevationDeg);
  final toDay = smoothstep(2, 22, sunElevationDeg);
  return mix(mix(night, twilight, toTwilight), day, toDay);
}

/// The horizon silhouette (hills), tinted by the sky above it; [depth] is 0 at
/// the back and 1 at the front.
Color horizonColor(double sunElevationDeg, double depth) {
  final sky = skyGradient(sunElevationDeg).bottom;
  return mix(sky, const Color(0xFF05070F), 0.6 + 0.3 * depth);
}

/// The shaded underside of clouds.
Color cloudShade(double sunElevationDeg, double overcast) {
  final lit = cloudLit(sunElevationDeg);
  final dark = desaturate(mix(lit, const Color(0xFF1C2440), 0.55), 0.35);
  return mix(
    mix(lit, dark, 0.45),
    mix(dark, const Color(0xFF0E1426), 0.35),
    overcast,
  );
}
