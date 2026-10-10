import 'package:flutter/material.dart';

import '../../domain/nickname.dart';

/// Asks for the name the others see. Pops with the trimmed name, or with an
/// empty string to become anonymous again; null means the dialog was dismissed.
class NicknameDialog extends StatefulWidget {
  const NicknameDialog({super.key, required this.initial});

  final String initial;

  @override
  State<NicknameDialog> createState() => _NicknameDialogState();
}

class _NicknameDialogState extends State<NicknameDialog> {
  late final _controller = TextEditingController(text: widget.initial);
  String? _problem;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final problem = nicknameProblem(_controller.text);
    if (problem != null) {
      setState(() => _problem = problem);
      return;
    }
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Your name in this room'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 24,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
        onChanged: (_) {
          if (_problem != null) setState(() => _problem = null);
        },
        decoration: InputDecoration(
          hintText: 'Anonymous',
          errorText: _problem,
          counterText: '',
        ),
      ),
      actions: [
        if (widget.initial.isNotEmpty)
          TextButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: const Text('Be anonymous'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
