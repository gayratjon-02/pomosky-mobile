import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/config.dart';
import '../../data/places_api.dart';
import '../../data/room_api.dart';
import '../../data/weather_api.dart';
import '../../data/ws/room_transport.dart';
import '../../domain/host_actions.dart';
import '../../domain/timer_math.dart';
import '../../domain/weather_text.dart';
import '../../domain/timer_view.dart';
import '../../ui/glass.dart';
import '../../ui/sky/sky_background.dart';
import '../../ui/sky/sky_inputs.dart';
import '../../ui/timer_ring.dart';
import '../../ui/tokens.dart';
import 'error_text.dart';
import 'host_controls.dart';
import 'nickname_dialog.dart';
import 'live_timer_providers.dart';
import 'place_picker.dart';
import 'room_providers.dart';
import 'room_session.dart';
import 'room_state.dart';

const _reactions = {'clap': '👏', 'coffee': '☕', 'fire': '🔥', 'heart': '❤️'};

/// Checks that the room exists, then shows it.
class RoomScreen extends ConsumerWidget {
  const RoomScreen({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lookup = ref.watch(roomLookupProvider(roomId));
    // The session must know the host token before it connects.
    final token = ref.watch(hostTokenProvider(roomId));
    // A refresh of the lookup keeps the old value, so the room stays on screen
    // while the server is asked again.
    if ((lookup.isLoading && !lookup.hasValue) ||
        (token.isLoading && !token.hasValue)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return lookup.value == RoomLookup.notFound
        ? const _RoomNotFound()
        : _RoomView(roomId: roomId);
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
    ref.watch(liveTimerControllerProvider(roomId)); // lock screen countdown
    ref.watch(tickProvider); // repaint the countdown
    final weather = ref.watch(weatherProvider(roomId)).value;
    ref.listen(roomStateProvider(roomId), (previous, next) {
      final error = next.error;
      if (error == null || identical(error, previous?.error)) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(friendlyError(error))));
    });
    ref.watch(screenAwakeSyncProvider(roomId));
    ref.watch(lifecycleReconnectProvider(roomId));
    ref.watch(roomGoneCheckProvider(roomId));
    ref.watch(hostRejectionProvider(roomId));
    ref.watch(phaseNotificationSyncProvider(roomId));
    final soundOn = ref.watch(soundEnabledProvider);
    final watcher = ref.watch(phaseEndWatcherProvider(roomId));
    ref.listen(tickProvider, (_, _) {
      final timer = ref.read(roomStateProvider(roomId)).timer;
      if (watcher.shouldSignal(timer, session.serverNowMs())) {
        ref
            .read(signalPlayerProvider)
            .ring(sound: ref.read(soundEnabledProvider));
      }
    });
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
        actions: [
          IconButton(
            tooltip: soundOn ? 'Mute the signal' : 'Unmute the signal',
            icon: Icon(
              soundOn ? Icons.volume_up_outlined : Icons.volume_off_outlined,
            ),
            onPressed: () => ref.read(soundEnabledProvider.notifier).toggle(),
          ),
          _Viewers(count: state.viewers),
          PopupMenuButton<_MenuAction>(
            tooltip: 'More',
            onSelected: (a) => switch (a) {
              _MenuAction.share => ref.read(shareTextProvider)(
                'Focus with me on Pomosky: ${roomLink(roomId)}',
              ),
              _MenuAction.name => _editName(context, ref, session),
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _MenuAction.share,
                child: Text('Share the link'),
              ),
              PopupMenuItem(value: _MenuAction.name, child: Text('Your name')),
            ],
          ),
        ],
      ),
      body: SkyBackground(
        inputs: _skyFor(state, weather, DateTime.now()),
        child: SafeArea(
          // The app bar floats over the sky, so the content starts below it.
          // Scrolls only when the screen is too short for everything (small
          // phones, large text); otherwise the column fills the screen.
          minimum: const EdgeInsets.only(top: kToolbarHeight),
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      if (state.connection != SocketStatus.connected)
                        _ConnectionBanner(status: state.connection),
                      if (weather != null)
                        _WeatherLine(weather: weather, nowMs: nowMs),
                      Expanded(
                        child: Center(
                          child: _TimerFace(
                            timer: state.timer,
                            remainingMs: remaining,
                            fraction: remainingFraction(state.timer, nowMs),
                            size: (box.maxHeight * 0.36).clamp(180.0, 300.0),
                          ),
                        ),
                      ),
                      _People(state: state),
                      if (state.isHost) ...[
                        HostControls(
                          actions: hostActionsFor(state.timer, remaining),
                          city: state.city,
                          onPickPlace: () => _pickPlace(context, ref, session),
                          onStart: (focus, durationMs, label) =>
                              session.startTimer(
                                focus: focus,
                                durationMs: durationMs,
                                label: label,
                              ),
                          onPause: session.pause,
                          onResume: session.resume,
                          onReset: session.reset,
                        ),
                        const SizedBox(height: 8),
                      ],
                      _ReactionBar(state: state, onReact: session.react),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _MenuAction { share, name }

/// Asks for a name and tells the room. The server cannot drop a name it was
/// given, so going anonymous reconnects without it.
Future<void> _editName(
  BuildContext context,
  WidgetRef ref,
  RoomSession session,
) async {
  final current = ref.read(nicknameProvider);
  final name = await showDialog<String>(
    context: context,
    builder: (_) => NicknameDialog(initial: current),
  );
  if (name == null || name == current) return;
  await ref.read(nicknameProvider.notifier).set(name);
  if (name.isEmpty) {
    session.reconnect();
  } else {
    session.join(name);
  }
}

/// Lets the host search for a city and sets it as the room's place; the server
/// rounds the coordinates to about 1 km.
Future<void> _pickPlace(
  BuildContext context,
  WidgetRef ref,
  RoomSession session,
) async {
  final place = await showModalBottomSheet<Place>(
    context: context,
    isScrollControlled: true,
    builder: (_) => PlacePicker(search: ref.read(placeSearchProvider)),
  );
  if (place == null) return;
  session.setLocation(
    city: place.name,
    lat: place.lat,
    lon: place.lon,
    tz: place.tz,
  );
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

class _WeatherLine extends StatelessWidget {
  const _WeatherLine({required this.weather, required this.nowMs});

  final WeatherData weather;
  final int nowMs;

  @override
  Widget build(BuildContext context) {
    final age = Duration(
      milliseconds: (nowMs - weather.observedAtMs).clamp(0, 1 << 40),
    );
    final text = weatherLine(
      temperatureC: weather.temperatureC,
      description: describeWeather(
        cloudCoverPct: weather.cloudCoverPct,
        precipitationMmh: weather.precipitationMmh,
        snowfallCmh: weather.snowfallCmh,
        fogDensity: weather.fogDensity,
        thunder: weather.thunder,
      ),
      age: age,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.l, Gap.s, Gap.l, 0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Tint.creamDim,
          fontWeight: FontWeight.w500,
          // A faint shadow, so the line holds on a pale afternoon sky.
          shadows: [
            Shadow(
              color: Night.background.withValues(alpha: 0.5),
              blurRadius: 8,
            ),
          ],
        ),
      ),
    );
  }
}

/// A quiet plaque under the app bar: a lost connection is the network's
/// fault, not the user's, so it is amber and calm rather than an alarm.
class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.status});

  final SocketStatus status;

  @override
  Widget build(BuildContext context) {
    final connecting = status == SocketStatus.connecting;
    final text = connecting ? 'Connecting…' : 'Connection lost, trying again…';
    final color = connecting ? Tint.creamDim : Tint.amber;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.l, Gap.xs, Gap.l, 0),
      child: GlassCard(
        strong: true,
        radius: Radii.pill,
        padding: const EdgeInsets.symmetric(
          horizontal: Gap.l,
          vertical: Gap.s + 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (connecting)
              const SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.6,
                  color: Tint.creamDim,
                ),
              )
            else
              const Icon(Icons.cloud_off_rounded, size: 16, color: Tint.amber),
            const SizedBox(width: Gap.s),
            Flexible(
              child: Text(
                text,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
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
    required this.size,
  });

  final TimerView timer;
  final int remainingMs;
  final double fraction;
  final double size;

  String get _phaseLabel => switch (timer.phase) {
    Phase.focus => 'Focus',
    Phase.break_ => 'Break',
    Phase.paused => 'Paused',
    Phase.idle => 'Waiting for the host',
  };

  Color get _color => switch (timer.phase) {
    Phase.focus => Tint.apricot,
    Phase.break_ => Tint.mint,
    Phase.paused => Tint.amber,
    Phase.idle => Tint.creamFaint,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _color;
    // A soft dusk behind the numbers keeps them readable on a daytime sky.
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Night.background.withValues(alpha: 0.38),
            Night.background.withValues(alpha: 0.18),
            Night.background.withValues(alpha: 0),
          ],
          stops: const [0, 0.62, 1],
        ),
      ),
      child: TimerRing(
        fraction: fraction,
        color: color,
        size: size,
        strokeWidth: (size / 36).clamp(4.0, 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedDefaultTextStyle(
              duration: Motion.normal,
              style: theme.textTheme.labelSmall!.copyWith(
                color: color,
                letterSpacing: 2,
              ),
              child: Text(_phaseLabel),
            ),
            const SizedBox(height: Gap.s),
            Semantics(
              label: '${formatMMSS(remainingMs)} remaining',
              child: Text(
                formatMMSS(remainingMs),
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: size * 0.24,
                  letterSpacing: -size * 0.008,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            if (timer.label.isNotEmpty) ...[
              const SizedBox(height: Gap.s),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: size * 0.6),
                child: Text(
                  timer.label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Tint.creamDim,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
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
