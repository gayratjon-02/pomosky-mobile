import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/places_api.dart';
import '../../ui/tokens.dart';

typedef PlaceSearch = Future<List<Place>> Function(String query);

/// A bottom sheet where the host searches for a city. The search waits for a
/// pause in typing, because the server limits how fast it can be called.
/// Pops with the chosen [Place].
class PlacePicker extends StatefulWidget {
  const PlacePicker({
    super.key,
    required this.search,
    this.debounce = const Duration(milliseconds: 450),
  });

  final PlaceSearch search;
  final Duration debounce;

  @override
  State<PlacePicker> createState() => _PlacePickerState();
}

class _PlacePickerState extends State<PlacePicker> {
  final _controller = TextEditingController();
  Timer? _timer;
  int _generation = 0; // ignores answers to queries that are out of date
  List<Place> _results = const [];
  bool _loading = false;
  String? _error;
  bool _searched = false;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _timer?.cancel();
    final generation = ++_generation;
    if (text.trim().length < 2) {
      setState(() {
        _results = const [];
        _loading = false;
        _error = null;
        _searched = false;
      });
      return;
    }
    setState(() => _loading = true);
    _timer = Timer(widget.debounce, () => _run(text, generation));
  }

  Future<void> _run(String text, int generation) async {
    try {
      final found = await widget.search(text);
      if (!mounted || generation != _generation) return;
      setState(() {
        _results = found;
        _error = null;
        _searched = true;
        _loading = false;
      });
    } on PlaceSearchException catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _results = const [];
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final query = _controller.text.trim();
    return Padding(
      padding: EdgeInsets.only(
        left: Gap.xl,
        right: Gap.xl,
        bottom: MediaQuery.viewInsetsOf(context).bottom + Gap.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Where is your sky?', style: text.headlineSmall),
          const SizedBox(height: Gap.xs),
          Text(
            'The room shows the sky and weather of this city.',
            style: text.bodyMedium?.copyWith(color: Tint.creamDim),
          ),
          const SizedBox(height: Gap.l),
          TextField(
            controller: _controller,
            autofocus: true,
            autocorrect: false,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
            style: text.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Search for a city',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Tint.creamFaint,
              ),
              suffixIcon: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(Gap.m + 2),
                      child: SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: Gap.s),
          AnimatedSize(
            duration: Motion.normal,
            curve: Motion.curve,
            alignment: Alignment.topCenter,
            child: _body(context, query),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, String query) {
    final error = _error;
    if (error != null) {
      return _Note(error, color: Tint.rose);
    }
    if (_searched && _results.isEmpty && !_loading) {
      return const _Note(
        'No places found',
        detail: 'Try the English name or a bigger city nearby.',
      );
    }
    if (_results.isEmpty) {
      return query.length < 2 && !_loading
          ? const _Note('Type at least two letters', faint: true)
          : const SizedBox(width: double.infinity, height: Gap.s);
    }
    // A long answer scrolls inside the sheet instead of pushing it off screen.
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.45,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _results.length,
        separatorBuilder: (_, _) => const Divider(indent: Gap.m),
        itemBuilder: (context, i) => _PlaceRow(
          place: _results[i],
          onTap: () => Navigator.of(context).pop(_results[i]),
        ),
      ),
    );
  }
}

/// One answer: the city large, where it is underneath.
class _PlaceRow extends StatelessWidget {
  const _PlaceRow({required this.place, required this.onTap});

  final Place place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final where = _where(place);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.chip),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Gap.m,
            vertical: Gap.s + 2,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(place.name, style: text.titleMedium),
              if (where.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  where,
                  style: text.bodySmall?.copyWith(color: Tint.creamDim),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// "Gyeonggi-do, South Korea": the region and country, without repeating the
/// city's own name (Seoul is also the name of its region).
String _where(Place place) {
  final parts = <String>[];
  for (final p in [place.region, place.country]) {
    if (p.isNotEmpty && p != place.name && !parts.contains(p)) parts.add(p);
  }
  return parts.join(', ');
}

/// A quiet line under the field for the empty, waiting and failed states.
class _Note extends StatelessWidget {
  const _Note(
    this.message, {
    this.detail,
    this.color = Tint.cream,
    this.faint = false,
  });

  final String message;
  final String? detail;
  final Color color;
  final bool faint;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final detail = this.detail;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.xs, Gap.m, Gap.xs, Gap.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: (faint ? text.bodySmall : text.bodyMedium)?.copyWith(
              color: faint ? Tint.creamFaint : color,
            ),
          ),
          if (detail != null) ...[
            const SizedBox(height: 2),
            Text(
              detail,
              style: text.bodySmall?.copyWith(color: Tint.creamFaint),
            ),
          ],
        ],
      ),
    );
  }
}
