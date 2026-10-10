import 'package:flutter/material.dart';

import '../../domain/host_actions.dart';
import '../../ui/buttons.dart';
import '../../ui/glass.dart';
import '../../ui/tokens.dart';

const _focusMinutes = [15, 25, 45, 50];
const _breakMinutes = [5, 10, 15];

/// The host's timer controls: pick a length and a label and start, or pause,
/// resume and reset a running phase. [actions] says what the server allows now.
class HostControls extends StatefulWidget {
  const HostControls({
    super.key,
    required this.actions,
    required this.city,
    required this.onPickPlace,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onReset,
  });

  final HostActions actions;

  /// The place the sky shows; empty until the host sets one.
  final String city;
  final VoidCallback onPickPlace;
  final void Function(bool focus, int durationMs, String label) onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onReset;

  @override
  State<HostControls> createState() => _HostControlsState();
}

class _HostControlsState extends State<HostControls> {
  int _focus = 25;
  int _break = 5;
  final _label = TextEditingController();

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  void _start(bool focus) => widget.onStart(
    focus,
    (focus ? _focus : _break) * 60 * 1000,
    _label.text.trim(),
  );

  @override
  Widget build(BuildContext context) {
    final a = widget.actions;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.l),
      // A touch of night under the glass: on a bright daytime sky the panel
      // would otherwise wash out to white behind cream text.
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Night.background.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(Radii.card),
        ),
        child: GlassCard(
          strong: true,
          padding: const EdgeInsets.fromLTRB(Gap.l, Gap.s, Gap.l, Gap.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PlaceRow(city: widget.city, onTap: widget.onPickPlace),
              const SizedBox(height: Gap.s),
              AnimatedSize(
                duration: Motion.normal,
                curve: Motion.curve,
                alignment: Alignment.topCenter,
                child: a.canStart ? _setup() : _running(a),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _setup() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Caption('Focus'),
        const SizedBox(height: Gap.s),
        PillSegments<int>(
          options: _focusMinutes,
          selected: _focus,
          labelOf: (m) => '$m',
          onChanged: (m) => setState(() => _focus = m),
        ),
        const SizedBox(height: Gap.m),
        _Caption('Break'),
        const SizedBox(height: Gap.s),
        PillSegments<int>(
          options: _breakMinutes,
          selected: _break,
          labelOf: (m) => '$m',
          onChanged: (m) => setState(() => _break = m),
        ),
        const SizedBox(height: Gap.l),
        TextField(
          controller: _label,
          maxLength: 60,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Working on…',
            counterText: '',
          ),
        ),
        const SizedBox(height: Gap.l),
        _Pair(
          first: PrimaryButton(
            label: 'Start focus',
            onPressed: () => _start(true),
          ),
          second: GlassButton(
            label: 'Start break',
            onPressed: () => _start(false),
          ),
        ),
      ],
    );
  }

  Widget _running(HostActions a) {
    return _Pair(
      first: a.canResume
          ? PrimaryButton(
              label: 'Resume',
              icon: Icons.play_arrow_rounded,
              onPressed: widget.onResume,
            )
          : a.canPause
          ? GlassButton(
              label: 'Pause',
              icon: Icons.pause_rounded,
              onPressed: widget.onPause,
            )
          : null,
      second: a.canReset
          ? GlassButton(
              label: 'Reset',
              icon: Icons.replay_rounded,
              onPressed: widget.onReset,
            )
          : null,
    );
  }
}

/// Two buttons side by side when there is room for both labels, else stacked
/// (narrow phones, large text).
class _Pair extends StatelessWidget {
  const _Pair({this.first, this.second});

  final Widget? first;
  final Widget? second;

  @override
  Widget build(BuildContext context) {
    final buttons = [first, second].whereType<Widget>().toList();
    if (buttons.length < 2) {
      return buttons.isEmpty ? const SizedBox.shrink() : buttons.single;
    }
    // The screen width, not a LayoutBuilder: the room measures its column's
    // intrinsic height, which a LayoutBuilder cannot report.
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final width = MediaQuery.sizeOf(context).width - 4 * Gap.l;
    if (width >= 290 * scale) {
      return Row(
        children: [
          Expanded(child: buttons[0]),
          const SizedBox(width: Gap.s),
          Expanded(child: buttons[1]),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buttons[0],
        const SizedBox(height: Gap.s),
        buttons[1],
      ],
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: Gap.xs),
      child: Row(
        children: [
          Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: Tint.creamDim),
          ),
          const Spacer(),
          Text(
            'min',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: Tint.creamFaint),
          ),
        ],
      ),
    );
  }
}

/// The sky's city, quiet until tapped: the host sets it once and rarely again.
class _PlaceRow extends StatelessWidget {
  const _PlaceRow({required this.city, required this.onTap});

  final String city;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;
    final empty = city.isEmpty;
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.pill),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  empty
                      ? Icons.add_location_alt_outlined
                      : Icons.place_outlined,
                  size: 18,
                  color: empty ? Tint.apricot : Tint.creamDim,
                ),
                const SizedBox(width: Gap.s),
                Flexible(
                  child: Text(
                    empty ? 'Choose the sky\'s city' : '$city · change',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style?.copyWith(
                      color: empty ? Tint.apricot : Tint.creamDim,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
