import '../../ui/sky/sky_inputs.dart';

/// A named look of the sky: a local hour in Seoul plus a weather.
class SkyPreset {
  const SkyPreset(this.name, this.hour, this.weather);

  final String name;

  /// Local hour (0..24) at Seoul on 2026-10-10.
  final double hour;
  final SkyInputs Function(SkyInputs base) weather;

  SkyInputs inputs() {
    final minutes = (hour * 60).round();
    // Seoul is UTC+9.
    final when = DateTime.utc(
      2026,
      10,
      10,
    ).add(Duration(minutes: minutes - 9 * 60));
    return weather(SkyInputs.forPlace(when, 37.5665, 126.978));
  }
}

SkyInputs _wx(
  SkyInputs b, {
  double cloud = 0,
  double rain = 0,
  double snow = 0,
  double wind = 5,
  double dir = 270,
  double fog = 0,
  bool thunder = false,
}) => b.withWeather(
  cloudCoverPct: cloud,
  precipitationMmh: rain,
  snowfallCmh: snow,
  windSpeedKmh: wind,
  windDirDeg: dir,
  fogDensity: fog,
  thunder: thunder,
);

final skyPresets = <SkyPreset>[
  SkyPreset('Noon', 12.3, (b) => _wx(b, cloud: 12, wind: 8)),
  SkyPreset('Golden', 17.4, (b) => _wx(b, cloud: 35, wind: 10, dir: 250)),
  SkyPreset('Dusk', 18.1, (b) => _wx(b, cloud: 45, wind: 12, dir: 260)),
  SkyPreset('Night', 23.2, (b) => _wx(b, cloud: 6, wind: 4)),
  SkyPreset('Cloudy', 14, (b) => _wx(b, cloud: 92, wind: 18, dir: 300)),
  SkyPreset(
    'Rain',
    15,
    (b) => _wx(b, cloud: 96, rain: 4.5, wind: 22, dir: 300, fog: 0.1),
  ),
  SkyPreset(
    'Storm',
    19,
    (b) => _wx(
      b,
      cloud: 100,
      rain: 9,
      wind: 45,
      dir: 310,
      fog: 0.05,
      thunder: true,
    ),
  ),
  SkyPreset(
    'Snow',
    11,
    (b) => _wx(b, cloud: 88, snow: 1.8, wind: 14, dir: 330, fog: 0.15),
  ),
  SkyPreset('Fog', 8, (b) => _wx(b, cloud: 70, wind: 3, dir: 200, fog: 0.85)),
];
