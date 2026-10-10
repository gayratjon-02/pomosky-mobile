import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/data/host_tokens.dart';

void main() {
  test('a stored token comes back for its room only', () async {
    final store = MemoryHostTokenStore();
    await store.write('abcd2345', 'secret');
    expect(await store.read('abcd2345'), 'secret');
    expect(await store.read('zzzz2345'), isNull);
  });

  test('a deleted token is gone', () async {
    final store = MemoryHostTokenStore();
    await store.write('abcd2345', 'secret');
    await store.delete('abcd2345');
    expect(await store.read('abcd2345'), isNull);
  });
}
