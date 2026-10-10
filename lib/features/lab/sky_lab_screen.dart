import 'dart:async';

import 'package:flutter/material.dart';

import '../../ui/sky/sky_background.dart';
import 'sky_presets.dart';

/// Development playground: pick a look of the sky, or let it cycle on its own
/// with `?auto=1`. Only registered in debug builds.
class SkyLabScreen extends StatefulWidget {
  const SkyLabScreen({super.key, this.initial, this.autoCycle = false});

  final String? initial;
  final bool autoCycle;

  @override
  State<SkyLabScreen> createState() => _SkyLabScreenState();
}

class _SkyLabScreenState extends State<SkyLabScreen> {
  late int _index = _start();
  Timer? _timer;

  int _start() {
    final i = skyPresets.indexWhere(
      (p) => p.name.toLowerCase() == widget.initial?.toLowerCase(),
    );
    return i < 0 ? 0 : i;
  }

  @override
  void initState() {
    super.initState();
    if (widget.autoCycle) {
      _timer = Timer.periodic(const Duration(seconds: 7), (_) {
        setState(() => _index = (_index + 1) % skyPresets.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preset = skyPresets[_index];
    return Scaffold(
      body: SkyBackground(
        inputs: preset.inputs(),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              Text(
                preset.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: skyPresets.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => ChoiceChip(
                    label: Text(skyPresets[i].name),
                    selected: i == _index,
                    onSelected: (_) => setState(() => _index = i),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
