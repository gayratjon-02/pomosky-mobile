import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/data/config.dart';

void main() {
  test('https becomes wss', () {
    expect(
      roomSocketUrl('abcd2345', base: 'https://pomosky.example'),
      'wss://pomosky.example/ws/abcd2345',
    );
  });

  test('http keeps the port and becomes ws', () {
    expect(
      roomSocketUrl('abcd2345', base: 'http://localhost:8080'),
      'ws://localhost:8080/ws/abcd2345',
    );
  });

  test('origin is scheme, host and port only', () {
    expect(
      originOf(base: 'https://pomosky.example/some/path'),
      'https://pomosky.example',
    );
    expect(originOf(base: 'http://localhost:8080'), 'http://localhost:8080');
  });
}
