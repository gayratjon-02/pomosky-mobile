/// Timer phases as the server names them.
enum Phase {
  idle,
  focus,
  break_,
  paused;

  static Phase fromWire(String value) => switch (value) {
    'focus' => Phase.focus,
    'break' => Phase.break_,
    'paused' => Phase.paused,
    _ => Phase.idle,
  };

  String get wire => this == Phase.break_ ? 'break' : name;
}

/// The room timer on the wire: `startedAtMs + durationMs` while running,
/// `pausedRemainingMs` while paused.
class TimerView {
  const TimerView({
    required this.phase,
    this.pausedFrom,
    required this.startedAtMs,
    required this.durationMs,
    required this.pausedRemainingMs,
    required this.label,
  });

  static const idle = TimerView(
    phase: Phase.idle,
    startedAtMs: 0,
    durationMs: 0,
    pausedRemainingMs: 0,
    label: '',
  );

  final Phase phase;
  final Phase? pausedFrom;
  final int startedAtMs;
  final int durationMs;
  final int pausedRemainingMs;
  final String label;

  factory TimerView.fromJson(Map<String, dynamic> json) => TimerView(
    phase: Phase.fromWire(json['phase'] as String? ?? ''),
    pausedFrom: json['pausedFrom'] == null
        ? null
        : Phase.fromWire(json['pausedFrom'] as String),
    startedAtMs: (json['startedAtMs'] as num?)?.toInt() ?? 0,
    durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
    pausedRemainingMs: (json['pausedRemainingMs'] as num?)?.toInt() ?? 0,
    label: json['label'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'phase': phase.wire,
    if (pausedFrom != null) 'pausedFrom': pausedFrom!.wire,
    'startedAtMs': startedAtMs,
    'durationMs': durationMs,
    'pausedRemainingMs': pausedRemainingMs,
    'label': label,
  };
}
