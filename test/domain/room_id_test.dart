import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/domain/room_id.dart';

void main() {
  group('parseRoomId', () {
    final cases = <String, String?>{
      'abcd2345': 'abcd2345',
      '  ABCD2345 \n': 'abcd2345',
      'https://pomosky.example/r/abcd2345': 'abcd2345',
      'https://pomosky.example/r/abcd2345?utm_source=telegram': 'abcd2345',
      'https://pomosky.example/r/abcd2345/host#token': 'abcd2345',
      'pomosky.example/r/abcd2345': 'abcd2345',
      '': null,
      'abc': null,
      'abcd2341': null, // 1 is not base32
      'https://pomosky.example/': null,
      'https://pomosky.example/r/short': null,
      'https://pomosky.example/x/abcd2345': null,
    };
    cases.forEach((input, want) {
      test('"$input" -> $want', () => expect(parseRoomId(input), want));
    });
  });
}
