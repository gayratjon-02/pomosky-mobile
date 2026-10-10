import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/room_api.dart';
import '../../data/weather_api.dart';
import '../../data/ws/room_transport.dart';
import '../../domain/timer_math.dart';
import '../../domain/timer_view.dart';
import '../../ui/sky/sky_background.dart';
import '../../ui/sky/sky_inputs.dart';
import '../../ui/timer_ring.dart';
import 'room_providers.dart';
import 'room_state.dart';

const _reactions = {'clap': '👏', 'coffee': '☕', 'fire': '🔥', 'heart': '❤️'};

/// Checks that the room exists, then shows it.
class RoomScreen extends ConsumerWidget {
  const RoomScreen({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lookup = ref.watch(roomLookupProvider(roomId));
    return switch (lookup) {
      AsyncData(value: RoomLookup.notFound) => const _RoomNotFound(),
      AsyncData() => _RoomView(roomId: roomId),
      AsyncError() => _RoomView(roomId: roomId),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}

class _RoomNotFound extends StatelessWidget {
  const _RoomNotFound();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Room not found', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text(
                'The code may be wrong, or the host closed the room.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomView extends ConsumerWidget {
  const _RoomView({required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(roomSessionProvider(roomId));
    final state = ref.watch(roomStateProvider(roomId));
    ref.watch(tickProvider); // repaint the countdown
    final weather = ref.watch(weatherProvider(roomId)).value;
    final nowMs = session.serverNowMs();
    final remaining = remainingMs(state.timer, nowMs);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Leave room',
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/'),
        ),
        title: Text(state.city.isEmpty ? 'Pomosky' : state.city),
        actions: [_Viewers(count: state.viewers)],
      ),
      body: SkyBackground(
        inputs: _skyFor(state, weather, DateTime.now()),
        child: SafeArea(
          child: Column(
            children: [
              if (state.connection != SocketStatus.connected)
                _ConnectionBanner(status: state.connection),
              Expanded(
                child: Center(
                  child: _TimerFace(
                    timer: state.timer,
                    remainingMs: remaining,
                    fraction: remainingFraction(state.timer, nowMs),
                  ),
                ),
              ),
              _People(state: state),
              _ReactionBar(state: state, onReact: session.react),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// The sky above the host's place. Until the host sets one, the longitude is
/// guessed from the phone's time zone so day and night still look right.
SkyInputs _skyFor(RoomState state, WeatherData? weather, DateTime now) {
  final place = state.location;
  final lon = now.timeZoneOffset.inMinutes / 60 * 15;
  final base = place != null
      ? SkyInputs.forPlace(now, place.lat, place.lon)
      : SkyInputs.forPlace(now, 35, lon);
  if (weather == null) return base;
  return base.withWeather(
    cloudCoverPct: weather.cloudCoverPct,
    precipitationMmh: weather.precipitationMmh,
    snowfallCmh: weather.snowfallCmh,
    windSpeedKmh: weather.windSpeedKmh,
    windDirDeg: weather.windDirDeg,
    fogDensity: weather.fogDensity,
    thunder: weather.thunder,
  );
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
  const _TimerFace({
    required this.timer,
    required this.remainingMs,
    required this.fraction,
  });

  final TimerView timer;
  final int remainingMs;
  final double fraction;

  String get _phaseLabel => switch (timer.phase) {
    Phase.focus => 'Focus',
    Phase.break_ => 'Break',
    Phase.paused => 'Paused',
    Phase.idle => 'Waiting for the host',
  };

  Color _color(ColorScheme scheme) => switch (timer.phase) {
    Phase.focus => const Color(0xFFFF8A65),
    Phase.break_ => const Color(0xFF66D9A8),
    Phase.paused => scheme.outline,
    Phase.idle => scheme.outlineVariant,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TimerRing(
      fraction: fraction,
      color: _color(theme.colorScheme),
      size: 300,
      strokeWidth: 12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_phaseLabel, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Semantics(
            label: '${formatMMSS(remainingMs)} remaining',
            child: Text(
              formatMMSS(remainingMs),
              style: theme.textTheme.displayLarge?.copyWith(
                fontSize: 64,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (timer.label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              timer.label,
              style: theme.textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
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
