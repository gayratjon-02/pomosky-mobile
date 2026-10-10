import 'dart:math' as math;
import 'dart:ui';

import '../../core/astro.dart';

/// Everything the sky needs to draw one frame. The sun and moon come from
/// astronomy for the host's place; the weather part comes from the server.
class SkyInputs {
  const SkyInputs({
    this.sunElevationDeg = 30,
    this.sunAzimuthDeg = 180,
    this.moonElevationDeg = -30,
    this.moonAzimuthDeg = 90,
    this.moonPhase = 0.5,
    this.moonFraction = 1,
    this.cloudCoverPct = 0,
    this.precipitationMmh = 0,
    this.snowfallCmh = 0,
    this.windSpeedKmh = 5,
    this.windDirDeg = 270,
    this.fogDensity = 0,
    this.thunder = false,
  });

  /// Sun and moon for a place and moment, with clear weather.
  factory SkyInputs.forPlace(DateTime when, double lat, double lon) {
    final sun = sunPosition(when, lat, lon);
    final moon = moonPosition(when, lat, lon);
    final light = moonLight(when);
    return SkyInputs(
      sunElevationDeg: sun.elevationDeg,
      sunAzimuthDeg: sun.azimuthDeg,
      moonElevationDeg: moon.elevationDeg,
      moonAzimuthDeg: moon.azimuthDeg,
      moonPhase: light.phase,
      moonFraction: light.fraction,
    );
  }

  final double sunElevationDeg;
  final double sunAzimuthDeg;
  final double moonElevationDeg;
  final double moonAzimuthDeg;
  final double moonPhase;
  final double moonFraction;
  final double cloudCoverPct;
  final double precipitationMmh;
  final double snowfallCmh;
  final double windSpeedKmh;
  final double windDirDeg;
  final double fogDensity;
  final bool thunder;

  SkyInputs withWeather({
    required double cloudCoverPct,
    required double precipitationMmh,
    required double snowfallCmh,
    required double windSpeedKmh,
    required double windDirDeg,
    required double fogDensity,
    required bool thunder,
  }) => SkyInputs(
    sunElevationDeg: sunElevationDeg,
    sunAzimuthDeg: sunAzimuthDeg,
    moonElevationDeg: moonElevationDeg,
    moonAzimuthDeg: moonAzimuthDeg,
    moonPhase: moonPhase,
    moonFraction: moonFraction,
    cloudCoverPct: cloudCoverPct,
    precipitationMmh: precipitationMmh,
    snowfallCmh: snowfallCmh,
    windSpeedKmh: windSpeedKmh,
    windDirDeg: windDirDeg,
    fogDensity: fogDensity,
    thunder: thunder,
  );

  /// Cloud cover and precipitation both make the sky look overcast (0..1).
  double get overcast {
    final cover = (cloudCoverPct / 100).clamp(0.0, 1.0);
    return (math.pow(cover, 1.2) +
            0.2 * (precipitationMmh / 6).clamp(0.0, 1.0) +
            0.15 * (snowfallCmh / 2).clamp(0.0, 1.0))
        .clamp(0.0, 1.0)
        .toDouble();
  }
}

/// Maps a compass bearing and an elevation to a point on the canvas. The view
/// looks south: east is on the left, west on the right, and the horizon sits at
/// `horizonY`. Points can lie outside the canvas (a sun in the north-east).
Offset skyPoint(
  Size size,
  double horizonY,
  double azimuthDeg,
  double elevationDeg,
) {
  final relative =
      ((azimuthDeg - 180 + 540) % 360) - 180; // -180..180, 0 = south
  return Offset(
    size.width * (0.5 + relative / 200),
    horizonY - (elevationDeg / 70) * horizonY * 0.9,
  );
}
