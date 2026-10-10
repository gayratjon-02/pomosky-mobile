import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'live_timer_activity.dart';
import 'live_timer_controller.dart';
import 'room_providers.dart';

/// The out-of-app countdown. A no-op unless `main` installs a platform one.
final liveTimerActivityProvider = Provider<LiveTimerActivity>(
  (ref) => const NoopLiveTimerActivity(),
);

/// Mirrors the room timer into [liveTimerActivityProvider] while the room
/// screen is open, and ends it when the screen goes away.
final liveTimerControllerProvider = Provider.autoDispose
    .family<LiveTimerController, String>((ref, roomId) {
      final controller = LiveTimerController(
        activity: ref.watch(liveTimerActivityProvider),
      );
      final session = ref.watch(roomSessionProvider(roomId));
      ref.listen(roomStateProvider(roomId), (_, next) {
        controller.onTimer(next.timer, serverNowMs: session.serverNowMs());
      }, fireImmediately: true);
      ref.onDispose(controller.leave);
      return controller;
    });
