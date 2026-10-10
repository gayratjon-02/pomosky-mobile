import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/data/protocol/server_messages.dart';
import 'package:pomosky_mobile/data/protocol/timer_view.dart';

ServerMessage decode(String frame) =>
    ServerMessage.fromJson(jsonDecode(frame) as Map<String, dynamic>);

void main() {
  test('decodes state with a location', () {
    final m = decode('''{"type":"state","data":{"roomId":"abc","viewers":3,
      "reactions":{"clap":2},"city":"Seoul","serverNowMs":99,
      "location":{"lat":37.57,"lon":126.98,"tz":"Asia/Seoul"},
      "timer":{"phase":"focus","startedAtMs":10,"durationMs":1500000,
      "pausedRemainingMs":0,"label":"x"}}}''');
    expect(m, isA<StateMessage>());
    final s = m as StateMessage;
    expect(s.roomId, 'abc');
    expect(s.viewers, 3);
    expect(s.reactions['clap'], 2);
    expect(s.location!.tz, 'Asia/Seoul');
    expect(s.timer.phase, Phase.focus);
    expect(s.serverNowMs, 99);
  });

  test('state without a location leaves it null', () {
    final s =
        decode('{"type":"state","data":{"roomId":"a","serverNowMs":1}}')
            as StateMessage;
    expect(s.location, isNull);
    expect(s.timer.phase, Phase.idle);
  });

  test('decodes people', () {
    final m =
        decode(
              '{"type":"people","data":{"people":[{"name":"Ayla","avatarUrl":"u"},{"name":"Bo"}],"more":4}}',
            )
            as PeopleMessage;
    expect(m.people.length, 2);
    expect(m.people.first.avatarUrl, 'u');
    expect(m.people.last.avatarUrl, isNull);
    expect(m.more, 4);
  });

  test('decodes pong, error and host.ok', () {
    expect(
      (decode('{"type":"pong","data":{"serverNowMs":5}}') as PongMessage)
          .serverNowMs,
      5,
    );
    final e =
        decode('{"type":"error","data":{"code":"forbidden","message":"no"}}')
            as ErrorMessage;
    expect(e.code, 'forbidden');
    expect(decode('{"type":"host.ok"}'), isA<HostOkMessage>());
  });

  test('unknown types do not throw', () {
    expect(decode('{"type":"future.thing","data":{}}'), isA<UnknownMessage>());
  });
}
