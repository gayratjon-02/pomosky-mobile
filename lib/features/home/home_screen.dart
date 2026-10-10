import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/room_api.dart';
import '../../domain/room_id.dart';
import '../../ui/buttons.dart';
import '../../ui/glass.dart';
import '../../ui/sky/sky_background.dart';
import '../../ui/sky/sky_inputs.dart';
import '../../ui/tokens.dart';
import '../room/room_providers.dart';

/// The front door: start a room, or join one by its link or 8-letter code.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _controller = TextEditingController();
  late final SkyInputs _sky = _localSky(DateTime.now());
  String? _error;
  String? _createError;
  bool _creating = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _join() {
    final id = parseRoomId(_controller.text);
    if (id == null) {
      setState(() => _error = 'Enter a room link or an 8-letter code');
      return;
    }
    context.go('/r/$id');
  }

  Future<void> _create() async {
    setState(() {
      _creating = true;
      _createError = null;
    });
    try {
      final created = await ref.read(roomCreatorProvider)();
      await ref
          .read(hostTokenStoreProvider)
          .write(created.id, created.hostToken);
      if (mounted) context.go('/r/${created.id}');
    } on RoomCreateException catch (e) {
      if (mounted) setState(() => _createError = e.message);
    } catch (_) {
      // The room exists but its host key (shown only once) could not be kept.
      if (mounted) {
        setState(
          () => _createError =
              'Could not save the host key on this phone. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // The sky stays full size under the keyboard; only the content moves up.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SkyBackground(
        inputs: _sky,
        child: SafeArea(
          bottom: keyboard == 0,
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              padding: EdgeInsets.only(bottom: keyboard),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (box.maxHeight - keyboard).clamp(
                    0,
                    double.infinity,
                  ),
                ),
                child: Padding(
                  // Centred and capped in width on tablets.
                  padding: EdgeInsets.fromLTRB(
                    _side(box.maxWidth),
                    Gap.huge,
                    _side(box.maxWidth),
                    Gap.xl,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(flex: 2),
                        Text('Pomosky', style: text.displayMedium),
                        const SizedBox(height: Gap.s),
                        Text(
                          'Focus together under a live sky',
                          style: text.bodyLarge?.copyWith(color: Tint.creamDim),
                        ),
                        const Spacer(flex: 3),
                        const SizedBox(height: Gap.huge),
                        PrimaryButton(
                          label: 'Create a room',
                          busy: _creating,
                          onPressed: _create,
                        ),
                        _Problem(_createError),
                        const SizedBox(height: Gap.xl),
                        _JoinPanel(
                          controller: _controller,
                          error: _error,
                          onJoin: _join,
                          onEdit: () {
                            if (_error != null) {
                              setState(() => _error = null);
                            }
                          },
                        ),
                        const SizedBox(height: Gap.l),
                        Text(
                          'No account needed',
                          textAlign: TextAlign.center,
                          style: text.bodySmall?.copyWith(
                            color: Tint.creamFaint,
                          ),
                        ),
                      ],
                    ),
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

double _side(double width) =>
    width > 420 + 2 * Gap.xl ? (width - 420) / 2 : Gap.xl;

/// The code field and its button on one pane of glass, so they read as a
/// single thing next to the louder create button.
class _JoinPanel extends StatelessWidget {
  const _JoinPanel({
    required this.controller,
    required this.error,
    required this.onJoin,
    required this.onEdit,
  });

  final TextEditingController controller;
  final String? error;
  final VoidCallback onJoin;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GlassCard(
      strong: true,
      padding: const EdgeInsets.all(Gap.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.xs, Gap.xs, Gap.xs, Gap.s),
            child: Text(
              'Have a link from a friend?',
              style: text.titleSmall?.copyWith(color: Tint.creamDim),
            ),
          ),
          TextField(
            controller: controller,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => onJoin(),
            onChanged: (_) => onEdit(),
            style: text.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Room link or code',
              fillColor: Night.background.withValues(alpha: 0.35),
              error: error == null ? null : const SizedBox.shrink(),
            ),
          ),
          _Problem(error),
          const SizedBox(height: Gap.m),
          GlassButton(label: 'Join room', onPressed: onJoin),
        ],
      ),
    );
  }
}

/// A short error line that slides open under the thing it is about, so the
/// layout eases instead of jumping.
class _Problem extends StatelessWidget {
  const _Problem(this.message);

  final String? message;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    return AnimatedSize(
      duration: Motion.normal,
      curve: Motion.curve,
      alignment: Alignment.topCenter,
      child: message == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(Gap.xs, Gap.s, Gap.xs, 0),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Tint.rose),
              ),
            ),
    );
  }
}

/// The sky over the phone's own time zone. The latitude is a fixed middle
/// value: reading the real location is not allowed, and the time zone is
/// enough to get day, dusk and night right.
SkyInputs _localSky(DateTime now) {
  final lon = now.timeZoneOffset.inMinutes / 60 * 15;
  return SkyInputs.forPlace(now, 35, lon);
}
