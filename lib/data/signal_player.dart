import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import '../core/chime.dart';

/// What happens when a phase ends: a ring and a buzz. Behind an interface so
/// tests need no audio hardware.
abstract interface class SignalPlayer {
  /// Rings the chime (when [sound] is true) and vibrates the phone.
  Future<void> ring({required bool sound});

  /// Stops a ring that is still playing.
  Future<void> stop();
}

/// Does nothing; the default in tests.
class SilentSignalPlayer implements SignalPlayer {
  @override
  Future<void> ring({required bool sound}) async {}

  @override
  Future<void> stop() async {}
}

/// Plays the synthesised chime and vibrates with three short pulses.
class DeviceSignalPlayer implements SignalPlayer {
  DeviceSignalPlayer({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  late final BytesSource _chime = BytesSource(
    synthesizeChime(),
    mimeType: 'audio/wav',
  );

  @override
  Future<void> ring({required bool sound}) async {
    // Both are best effort: a phone without a vibrator or a muted audio route
    // must never break the timer.
    _buzz();
    if (!sound) return;
    try {
      await _player.stop();
      await _player.play(_chime);
    } catch (_) {}
  }

  Future<void> _buzz() async {
    try {
      for (var i = 0; i < 3; i++) {
        await HapticFeedback.heavyImpact();
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
    } catch (_) {}
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }
}
