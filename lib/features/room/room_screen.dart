import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/ws/room_transport.dart';
import '../../domain/timer_math.dart';
import '../../domain/timer_view.dart';
import 'room_providers.dart';
import 'room_state.dart';

const _reactions = {'clap': '👏', 'coffee': '☕', 'fire': '🔥', 'heart': '❤️'};

class RoomScreen extends ConsumerWidget {
  const RoomScreen({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(roomSessionProvider(roomId));
    final state = ref.watch(roomStateProvider(roomId));
    ref.watch(tickProvider); // repaint the countdown
    final remaining = remainingMs(state.timer, session.serverNowMs());

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Leave room',
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/'),
        ),
        title: Text(state.city.isEmpty ? 'Pomosky' : state.city),
        actions: [_Viewers(count: state.viewers)],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (state.connection != SocketStatus.connected)
              _ConnectionBanner(status: state.connection),
            Expanded(
              child: Center(
                child: _TimerFace(timer: state.timer, remainingMs: remaining),
              ),
            ),
            _People(state: state),
            _ReactionBar(state: state, onReact: session.react),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.status});

  final SocketStatus status;

  @override
  Widget build(BuildContext context) {
    final text = status == SocketStatus.connecting
        ? 'Connecting…'
        : 'Connection lost, trying again…';
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Text(text, textAlign: TextAlign.center),
    );
  }
}

class _Viewers extends StatelessWidget {
  const _Viewers({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        children: [
          const Icon(Icons.people_outline, size: 20),
          const SizedBox(width: 4),
          Text('$count'),
        ],
      ),
    );
  }
}

class _TimerFace extends StatelessWidget {
  const _TimerFace({required this.timer, required this.remainingMs});

  final TimerView timer;
  final int remainingMs;

  String get _phaseLabel => switch (timer.phase) {
    Phase.focus => 'Focus',
    Phase.break_ => 'Break',
    Phase.paused => 'Paused',
    Phase.idle => 'Waiting for the host',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_phaseLabel, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Semantics(
          label: '${formatMMSS(remainingMs)} remaining',
          child: Text(
            formatMMSS(remainingMs),
            style: theme.textTheme.displayLarge?.copyWith(
              fontSize: 88,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (timer.label.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(timer.label, style: theme.textTheme.bodyLarge),
        ],
      ],
    );
  }
}

class _People extends StatelessWidget {
  const _People({required this.state});

  final RoomState state;

  @override
  Widget build(BuildContext context) {
    if (state.people.isEmpty) return const SizedBox.shrink();
    final names = state.people.map((p) => p.name).join(', ');
    final more = state.morePeople > 0 ? ' +${state.morePeople}' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        '$names$more',
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ReactionBar extends StatelessWidget {
  const _ReactionBar({required this.state, required this.onReact});

  final RoomState state;
  final void Function(String kind) onReact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final e in _reactions.entries)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextButton(
              onPressed: () => onReact(e.key),
              style: TextButton.styleFrom(minimumSize: const Size(56, 48)),
              child: Text('${e.value} ${state.reactions[e.key] ?? 0}'),
            ),
          ),
      ],
    );
  }
}
