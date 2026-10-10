import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/places_api.dart';

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
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            autocorrect: false,
            onChanged: _onChanged,
            decoration: InputDecoration(
              labelText: 'Search for a city',
              border: const OutlineInputBorder(),
              suffixIcon: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            )
          else if (_searched && _results.isEmpty && !_loading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('No places found'),
            ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final p in _results)
                  ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(p.label),
                    onTap: () => Navigator.of(context).pop(p),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
