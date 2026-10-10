import 'layers/clouds.dart';
import 'layers/hills.dart';
import 'layers/rain.dart';
import 'layers/snow.dart';
import 'layers/stars.dart';

/// The layers that keep fixed shapes, created once per sky and reused.
class SkyLayers {
  SkyLayers()
    : stars = StarField(),
      clouds = Clouds(),
      hills = Hills(),
      rain = Rain(),
      snow = Snow();

  final StarField stars;
  final Clouds clouds;
  final Hills hills;
  final Rain rain;
  final Snow snow;
}
