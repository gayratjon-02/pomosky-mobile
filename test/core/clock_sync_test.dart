import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/core/clock_sync.dart';

void main() {
  test('offset assumes the reply took half the round trip', () {
    // Sent at 1000, answered at 1100: server stamped 5050 mid-flight.
    expect(
      estimateOffset(serverNowMs: 5050, sentAtMs: 1000, receivedAtMs: 1100),
      4000,
    );
  });

  test('no samples means no offset', () {
    final c = ClockSync();
    expect(c.offsetMs, 0);
    expect(c.serverNow(1000), 1000);
  });

  test('the median ignores one slow outlier', () {
    final c = ClockSync();
    for (final v in [100.0, 102.0, 98.0, 900.0, 101.0]) {
      c.add(v);
    }
    expect(c.offsetMs, 101);
    expect(c.serverNow(1000), 1101);
  });

  test('only the latest samples are kept', () {
    final c = ClockSync(maxSamples: 3);
    for (final v in [1.0, 1.0, 1.0, 50.0, 50.0, 50.0]) {
      c.add(v);
    }
    expect(c.sampleCount, 3);
    expect(c.offsetMs, 50);
  });

  test('a seed stands in until the first real sample, then is forgotten', () {
    final c = ClockSync()..seed(500);
    expect(c.offsetMs, 500);
    expect(c.sampleCount, 0);

    c.add(100);
    expect(c.offsetMs, 100); // the seed no longer counts
    c.seed(900); // ignored once real samples exist
    expect(c.offsetMs, 100);
  });
}
