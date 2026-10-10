import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/data/protocol/client_messages.dart';

Map<String, dynamic> parse(String frame) =>
    jsonDecode(frame) as Map<String, dynamic>;

void main() {
  test('timer.start carries phase, duration and label', () {
    final m = parse(
      ClientMessages.timerStart(focus: true, durationMs: 1500000, label: 'Go'),
    );
    expect(m['type'], 'timer.start');
    expect(m['data'], {'phase': 'focus', 'durationMs': 1500000, 'label': 'Go'});
  });

  test('a break uses the break phase', () {
    final m = parse(
      ClientMessages.timerStart(focus: false, durationMs: 300000, label: ''),
    );
    expect((m['data'] as Map)['phase'], 'break');
  });

  test('messages without data have no data field', () {
    expect(parse(ClientMessages.ping()), {'type': 'ping'});
    expect(parse(ClientMessages.timerPause()), {'type': 'timer.pause'});
  });

  test('join, host.auth and reaction', () {
    expect(parse(ClientMessages.join('Ayla'))['data'], {'nickname': 'Ayla'});
    expect(parse(ClientMessages.hostAuth('tok'))['data'], {'token': 'tok'});
    expect(parse(ClientMessages.reaction('fire'))['data'], {'kind': 'fire'});
  });

  test('location.set sends city, coordinates and zone', () {
    final d =
        parse(
              ClientMessages.locationSet(
                city: 'Seoul',
                lat: 37.57,
                lon: 126.98,
                tz: 'Asia/Seoul',
              ),
            )['data']
            as Map;
    expect(d['city'], 'Seoul');
    expect(d['lat'], 37.57);
    expect(d['tz'], 'Asia/Seoul');
  });
}
