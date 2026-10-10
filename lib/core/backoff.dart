import 'dart:math';

/// Delay before reconnect attempt number [attempt] (0-based): exponential,
/// capped at [max], with up to 25% random jitter so many phones that lost the
/// server together do not return at the same instant.
Duration backoffDelay(
  int attempt, {
  Duration base = const Duration(milliseconds: 500),
  Duration max = const Duration(seconds: 15),
  required Random random,
}) {
  final exp = base.inMilliseconds * pow(2, attempt.clamp(0, 20));
  final capped = min(exp, max.inMilliseconds.toDouble());
  final jitter = capped * 0.25 * random.nextDouble();
  return Duration(milliseconds: (capped + jitter).round());
}
