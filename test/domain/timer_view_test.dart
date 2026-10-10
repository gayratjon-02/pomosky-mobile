import 'package:flutter_test/flutter_test.dart';
import 'package:pomosky_mobile/domain/timer_view.dart';

void main() {
  test('decodes a running focus timer', () {
    final t = TimerView.fromJson({
      'phase': 'focus',
      'startedAtMs': 1000,
      'durationMs': 1500000,
      'pausedRemainingMs': 0,
      'label': 'Go backend',
    });
    expect(t.phase, Phase.focus);
    expect(t.pausedFrom, isNull);
    expect(t.startedAtMs, 1000);
    expect(t.durationMs, 1500000);
    expect(t.label, 'Go backend');
  });

  test('decodes a paused break', () {
    final t = TimerView.fromJson({
      'phase': 'paused',
      'pausedFrom': 'break',
      'startedAtMs': 5,
      'durationMs': 300000,
      'pausedRemainingMs': 120000,
      'label': '',
    });
    expect(t.phase, Phase.paused);
    expect(t.pausedFrom, Phase.break_);
    expect(t.pausedRemainingMs, 120000);
  });

  test('unknown phase falls back to idle', () {
    expect(Phase.fromWire('nope'), Phase.idle);
  });

  test('round trips through json', () {
    const t = TimerView(
      phase: Phase.break_,
      startedAtMs: 7,
      durationMs: 300000,
      pausedRemainingMs: 0,
      label: 'rest',
    );
    final back = TimerView.fromJson(t.toJson());
    expect(back.phase, Phase.break_);
    expect(back.toJson()['phase'], 'break');
    expect(back.label, 'rest');
  });
}
