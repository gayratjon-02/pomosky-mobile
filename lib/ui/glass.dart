import 'dart:ui';

import 'package:flutter/material.dart';

import 'tokens.dart';

/// A panel of frosted glass: the live sky shows through, softly blurred, with a
/// hairline edge. Use it for the few things that sit on the sky (the host
/// panel, the reactions, dialogs of the room), not for every box: blurring
/// behind an animated sky costs frame time.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Gap.l),
    this.radius = Radii.card,
    this.strong = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// A more opaque wash, for text that must stay readable on a bright sky.
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: shape,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: Glass.blur, sigmaY: Glass.blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: strong ? Glass.fillStrong : Glass.fill,
            borderRadius: shape,
            border: Border.all(color: Glass.edge),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
