import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/domain/weather_text.dart';

String d({
  double cloud = 0,
  double rain = 0,
  double snow = 0,
  double fog = 0,
  bool thunder = false,
}) => describeWeather(
  cloudCoverPct: cloud,
  precipitationMmh: rain,
  snowfallCmh: snow,
  fogDensity: fog,
  thunder: thunder,
);

void main() {
  test('picks the strongest condition', () {
    expect(d(), 'Clear');
    expect(d(cloud: 20), 'Partly cloudy');
    expect(d(cloud: 60), 'Cloudy');
    expect(d(cloud: 95), 'Overcast');
    expect(d(cloud: 95, rain: 1), 'Rain');
    expect(d(cloud: 95, rain: 6), 'Heavy rain');
    expect(d(cloud: 95, snow: 1), 'Snow');
    expect(d(fog: 0.9, cloud: 70), 'Fog');
    expect(d(cloud: 100, rain: 9, thunder: true), 'Thunderstorm');
  });

  test('light fog does not hide the clouds', () {
    expect(d(fog: 0.1, cloud: 90), 'Overcast');
  });

  test('says how old the reading is', () {
    expect(ageLabel(const Duration(seconds: 20)), 'just now');
    expect(ageLabel(const Duration(minutes: 4, seconds: 50)), '4 min ago');
    expect(ageLabel(const Duration(minutes: 59)), '59 min ago');
    expect(ageLabel(const Duration(minutes: 125)), '2 h ago');
  });

  test('builds the line', () {
    expect(
      weatherLine(
        temperatureC: 17.6,
        description: 'Overcast',
        age: const Duration(minutes: 4),
      ),
      '18° · Overcast · updated 4 min ago',
    );
    expect(
      weatherLine(temperatureC: -2.4, description: 'Snow', age: Duration.zero),
      '-2° · Snow · updated just now',
    );
  });
}
