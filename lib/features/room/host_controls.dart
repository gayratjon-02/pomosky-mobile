import 'package:flutter/material.dart';

import '../../domain/host_actions.dart';

const _focusMinutes = [15, 25, 45, 50];
const _breakMinutes = [5, 10, 15];

/// The host's timer controls: pick a length and a label and start, or pause,
/// resume and reset a running phase. [actions] says what the server allows now.
class HostControls extends StatefulWidget {
  const HostControls({
    super.key,
    required this.actions,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onReset,
  });

  final HostActions actions;
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: a.canStart ? _setup() : _running(a),
      ),
    );
  }

  Widget _setup() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _minutes(
          'Focus',
          _focusMinutes,
          _focus,
          (m) => setState(() => _focus = m),
        ),
        _minutes(
          'Break',
          _breakMinutes,
          _break,
          (m) => setState(() => _break = m),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _label,
          maxLength: 60,
          decoration: const InputDecoration(
            labelText: 'What are you working on?',
            counterText: '',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () => _start(true),
                child: const Text('Start focus'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonal(
                onPressed: () => _start(false),
                child: const Text('Start break'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _minutes(
    String name,
    List<int> options,
    int selected,
    ValueChanged<int> onPick,
  ) {
    return Row(
      children: [
        SizedBox(width: 56, child: Text(name)),
        Expanded(
          child: Wrap(
            spacing: 8,
            children: [
              for (final m in options)
                ChoiceChip(
                  label: Text('$m'),
                  selected: m == selected,
                  onSelected: (_) => onPick(m),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _running(HostActions a) {
    return Row(
      children: [
        if (a.canPause)
          Expanded(
            child: FilledButton(
              onPressed: widget.onPause,
              child: const Text('Pause'),
            ),
          ),
        if (a.canResume)
          Expanded(
            child: FilledButton(
              onPressed: widget.onResume,
              child: const Text('Resume'),
            ),
          ),
        if (a.canReset) ...[
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: widget.onReset,
              child: const Text('Reset'),
            ),
          ),
        ],
      ],
    );
  }
}
