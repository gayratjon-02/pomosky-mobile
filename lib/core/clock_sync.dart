/// Server clock synchronisation: serverTime ~= clientTime + offset.

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

  int get sampleCount => _samples.length;

  void add(double offsetMs) {
    _samples.add(offsetMs);
    if (_samples.length > maxSamples) _samples.removeAt(0);
  }

  double get offsetMs {
    if (_samples.isEmpty) return 0;
    final sorted = [..._samples]..sort();
    return sorted[sorted.length ~/ 2];
  }

  /// The server's time for the given local time (ms since epoch).
  int serverNow(int clientNowMs) => (clientNowMs + offsetMs).round();
}
