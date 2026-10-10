/// Short words for the weather, for the chip under the city name.
String describeWeather({
  required double cloudCoverPct,
  required double precipitationMmh,
  required double snowfallCmh,
  required double fogDensity,
  required bool thunder,
}) {
  if (thunder) return 'Thunderstorm';
  if (snowfallCmh > 0.05) return 'Snow';
  if (precipitationMmh > 0.05) {
    return precipitationMmh >= 4 ? 'Heavy rain' : 'Rain';
  }
  if (fogDensity >= 0.5) return 'Fog';
  if (cloudCoverPct >= 80) return 'Overcast';
  if (cloudCoverPct >= 45) return 'Cloudy';
  if (cloudCoverPct >= 15) return 'Partly cloudy';
  return 'Clear';
}

/// "just now", "4 min ago", "2 h ago". The weather can be a quarter of an hour
/// old, and the app says so instead of pretending it is live.
String ageLabel(Duration age) {
  final minutes = age.inMinutes;
  if (minutes < 1) return 'just now';
  if (minutes < 60) return '$minutes min ago';
  return '${age.inHours} h ago';
}

/// "18° · Overcast · updated 4 min ago".
String weatherLine({
  required double temperatureC,
  required String description,
  required Duration age,
}) => '${temperatureC.round()}° · $description · updated ${ageLabel(age)}';
