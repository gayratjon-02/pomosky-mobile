import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/data/protocol/server_messages.dart';
import 'package:pomosky_mobile/features/room/error_text.dart';

String say(String code, [String message = '']) =>
    friendlyError(ErrorMessage(code: code, message: message));

void main() {
  test('known codes get a plain sentence', () {
    expect(say('forbidden', 'host only'), 'Only the host can do that');
    expect(say('rate_limited'), 'Slow down a little');
    expect(say('invalid_transition'), 'That is not possible right now');
  });

  test('other codes use the server message, or a fallback', () {
    expect(say('invalid', 'label is too long'), 'label is too long');
    expect(say('bad_request'), 'Something went wrong');
  });
}
