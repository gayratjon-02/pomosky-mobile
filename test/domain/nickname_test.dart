import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/domain/nickname.dart';

void main() {
  test('accepts 2 to 24 characters, counted after trimming', () {
    expect(nicknameProblem('Al'), isNull);
    expect(nicknameProblem('  Ayla  '), isNull);
    expect(nicknameProblem('a' * 24), isNull);
  });

  test('rejects too short and too long', () {
    expect(nicknameProblem(''), isNotNull);
    expect(nicknameProblem('A'), isNotNull);
    expect(nicknameProblem('   A   '), isNotNull);
    expect(nicknameProblem('a' * 25), isNotNull);
  });

  test('counts characters, not bytes', () {
    expect(nicknameProblem('휘린'), isNull); // two characters
    expect(nicknameProblem('ខ្មែរ'), isNull);
    expect(nicknameProblem('👍🏽'), isNull);
  });

  test('rejects control characters', () {
    expect(nicknameProblem('Ay\nla'), isNotNull);
    expect(nicknameProblem('Ay\u0000la'), isNotNull);
  });

  test('sends the trimmed name or nothing', () {
    expect(nicknameToSend('  Ayla '), 'Ayla');
    expect(nicknameToSend('x'), isNull);
  });
}
