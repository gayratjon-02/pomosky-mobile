import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/data/live_activity/ios_live_timer_activity.dart';
import 'package:pomosky_mobile/domain/timer_view.dart';
import 'package:pomosky_mobile/features/room/live_timer_activity.dart';

const _snapshot = LiveTimerSnapshot(
  phase: Phase.break_,
  label: 'rest',
  durationMs: 300000,
  endsAtMs: 99,
  remainingMs: 250000,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = MethodChannel(IosLiveTimerActivity.channelName);

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('sends the snapshot with the wire phase name', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    final a = IosLiveTimerActivity();
    await a.start(_snapshot);
    await a.end();
    expect(calls.map((c) => c.method), ['start', 'end']);
    expect(calls.first.arguments, {
      'phase': 'break',
      'label': 'rest',
      'durationMs': 300000,
      'endsAtMs': 99,
      'remainingMs': 250000,
    });
  });

  test('swallows platform errors and a missing handler', () async {
    final a = IosLiveTimerActivity();
    await a.update(_snapshot); // no handler: MissingPluginException
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'disabled');
    });
    await a.start(_snapshot);
  });
}
