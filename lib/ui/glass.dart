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

/// A soft patch of dusk behind text that sits straight on the sky. At night it
/// is invisible; on a bright daytime sky it keeps cream text readable without
/// a hard box. Wrap the text block in it. The veil is an ellipse that fades to
/// nothing at its edge, so no outline is ever visible.
class DuskVeil extends StatelessWidget {
  const DuskVeil({super.key, required this.child, this.reach = 36});

  final Widget child;

  /// How far the veil extends beyond the child on every side.
  final double reach;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -reach,
          right: -reach,
          top: -reach,
          bottom: -reach,
          child: IgnorePointer(
            child: LayoutBuilder(
              builder: (context, box) {
                final aspect = box.maxHeight <= 0
                    ? 1.0
                    : box.maxWidth / box.maxHeight;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 0.5,
                      colors: [
                        Night.background.withValues(alpha: 0.36),
                        Night.background.withValues(alpha: 0.16),
                        Night.background.withValues(alpha: 0),
                      ],
                      stops: const [0, 0.55, 1],
                      transform: _Ellipse(aspect),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Stretches a radial gradient sideways so it fills a wide box as an ellipse.
class _Ellipse extends GradientTransform {
  const _Ellipse(this.aspect);

  final double aspect;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final c = bounds.center;
    return Matrix4.identity()
      ..translateByDouble(c.dx, c.dy, 0, 1)
      ..scaleByDouble(aspect, 1, 1, 1)
      ..translateByDouble(-c.dx, -c.dy, 0, 1);
  }
}

/// A gentle shadow for cream text on the open sky, so letters keep their edge
/// against bright clouds and sun.
const skyTextShadow = [
  Shadow(color: Color(0x73050818), blurRadius: 14),
  Shadow(color: Color(0x40050818), blurRadius: 3),
];
