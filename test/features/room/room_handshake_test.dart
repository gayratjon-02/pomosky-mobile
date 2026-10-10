import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/data/settings.dart';
import 'package:pomosky_mobile/data/ws/room_socket.dart';
import 'package:pomosky_mobile/features/room/room_providers.dart';

List<String> handshake(ProviderContainer c, {String? token}) {
  final socket =
      c.read(roomTransportFactoryProvider)('abcd2345', token) as RoomSocket;
  return socket.handshake();
}

ProviderContainer container(String nickname) {
  final settings = MemorySettings()..nickname = nickname;
  final c = ProviderContainer(
    overrides: [appSettingsProvider.overrideWithValue(settings)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('an anonymous viewer sends nothing', () {
    expect(handshake(container('')), isEmpty);
  });

  test('a viewer with a nickname introduces itself', () {
    final frames = handshake(container('  Ayla '));
    expect(frames.length, 1);
    expect(frames.single, contains('"join"'));
    expect(frames.single, contains('"Ayla"'));
  });

  test('a host authenticates first, then introduces itself', () {
    final frames = handshake(container('Ayla'), token: 'secret');
    expect(frames.length, 2);
    expect(frames.first, contains('host.auth'));
    expect(frames.first, contains('secret'));
    expect(frames.last, contains('join'));
  });

  test('a nickname the server would refuse is not sent', () {
    expect(handshake(container('A')), isEmpty);
  });

  test('a changed nickname applies to the next connection', () async {
    final c = container('');
    expect(handshake(c), isEmpty);
    await c.read(nicknameProvider.notifier).set('Bo!');
    expect(handshake(c).single, contains('Bo!'));
  });
}
