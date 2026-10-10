import 'package:flutter/material.dart';

import '../../domain/nickname.dart';
import '../../ui/buttons.dart';
import '../../ui/tokens.dart';

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
    final text = Theme.of(context).textTheme;
    final problem = _problem;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: Gap.xl,
        vertical: Gap.xl,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.xl, Gap.xl, Gap.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Your name in this room', style: text.titleLarge),
              const SizedBox(height: Gap.xs),
              Text(
                'Everyone in the room sees it.',
                style: text.bodyMedium?.copyWith(color: Tint.creamDim),
              ),
              const SizedBox(height: Gap.l),
              TextField(
                controller: _controller,
                autofocus: true,
                maxLength: 24,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                onChanged: (_) {
                  if (_problem != null) setState(() => _problem = null);
                },
                style: text.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Anonymous',
                  counterText: '',
                  error: problem == null ? null : const SizedBox.shrink(),
                ),
              ),
              AnimatedSize(
                duration: Motion.normal,
                curve: Motion.curve,
                alignment: Alignment.topCenter,
                child: problem == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Gap.xs,
                          Gap.s,
                          Gap.xs,
                          0,
                        ),
                        child: Text(
                          problem,
                          style: text.bodySmall?.copyWith(color: Tint.rose),
                        ),
                      ),
              ),
              const SizedBox(height: Gap.xl),
              PrimaryButton(label: 'Save', onPressed: _save),
              const SizedBox(height: Gap.xs),
              // Wraps onto two lines when large text leaves no room.
              OverflowBar(
                alignment: widget.initial.isEmpty
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.spaceBetween,
                overflowAlignment: OverflowBarAlignment.center,
                children: [
                  if (widget.initial.isNotEmpty)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(''),
                      child: const Text('Be anonymous'),
                    ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(foregroundColor: Tint.creamDim),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
