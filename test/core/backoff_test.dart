import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/core/backoff.dart';

/// Always returns [value] from nextDouble, so jitter is predictable.
class _Fixed implements Random {
  _Fixed(this.value);
  final double value;
  @override
  double nextDouble() => value;
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
}

void main() {
  test('doubles each attempt without jitter', () {
    final r = _Fixed(0);
    expect(backoffDelay(0, random: r), const Duration(milliseconds: 500));
    expect(backoffDelay(1, random: r), const Duration(seconds: 1));
    expect(backoffDelay(2, random: r), const Duration(seconds: 2));
    expect(backoffDelay(3, random: r), const Duration(seconds: 4));
  });

  test('is capped', () {
    final r = _Fixed(0);
    expect(backoffDelay(10, random: r), const Duration(seconds: 15));
    expect(backoffDelay(500, random: r), const Duration(seconds: 15));
  });

  test('jitter adds at most a quarter', () {
    expect(
      backoffDelay(1, random: _Fixed(1)),
      const Duration(milliseconds: 1250),
    );
  });

  test('a negative attempt behaves like the first', () {
    expect(
      backoffDelay(-3, random: _Fixed(0)),
      const Duration(milliseconds: 500),
    );
  });
}
