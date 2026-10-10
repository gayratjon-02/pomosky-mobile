// Server clock synchronisation: serverTime ~= clientTime + offset.

/// Estimates the offset from one ping/pong round trip.
double estimateOffset({
  required int serverNowMs,
  required int sentAtMs,
  required int receivedAtMs,
}) {
  final rtt = receivedAtMs - sentAtMs;
  return serverNowMs - (sentAtMs + rtt / 2);
}

/// Keeps the median of the latest samples, which is robust against the odd
/// slow round trip.
class ClockSync {
  ClockSync({this.maxSamples = 8});

  final int maxSamples;
  final List<double> _samples = [];
  double? _provisional;

  int get sampleCount => _samples.length;

  /// A rough first guess (for example from the server time in the first
  /// message, which has no round trip to measure). It is used only until a
  /// real sample arrives and is then forgotten.
  void seed(double offsetMs) {
    if (_samples.isEmpty) _provisional = offsetMs;
  }

  void add(double offsetMs) {
    _provisional = null;
    _samples.add(offsetMs);
    if (_samples.length > maxSamples) _samples.removeAt(0);
  }

  double get offsetMs {
    if (_samples.isEmpty) return _provisional ?? 0;
    final sorted = [..._samples]..sort();
    return sorted[sorted.length ~/ 2];
  }

  /// The server's time for the given local time (ms since epoch).
  int serverNow(int clientNowMs) => (clientNowMs + offsetMs).round();
}
