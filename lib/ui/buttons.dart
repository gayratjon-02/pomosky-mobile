import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

/// The one loud button of a screen: a warm apricot pill. Use it once per
/// screen for the main action; everything else is a [GlassButton] or text.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Shows a spinner instead of the label and ignores taps.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    return _Pill(
      enabled: enabled,
      onTap: onPressed,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Tint.apricot, Tint.apricotDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x55FF8F5A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: busy
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Night.background,
              ),
            )
          : _Label(label: label, icon: icon, color: Night.background),
    );
  }
}

/// A calm secondary button: a glass pill with a hairline edge.
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// A smaller height, for controls inside a panel.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _Pill(
      enabled: onPressed != null,
      onTap: onPressed,
      height: compact ? 44 : 54,
      decoration: BoxDecoration(
        color: Glass.fill,
        border: Border.all(color: Glass.edge),
      ),
      child: _Label(label: label, icon: icon, color: Tint.cream),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.label, required this.color, this.icon});

  final String label;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(color: color);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: color),
          const SizedBox(width: Gap.s),
        ],
        Flexible(
          child: Text(
            label,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// The shared body of the pill buttons: shape, ripple, a light press scale, a
/// tick of haptics and the disabled look. At least 44 points tall.
class _Pill extends StatefulWidget {
  const _Pill({
    required this.enabled,
    required this.onTap,
    required this.decoration,
    required this.child,
    this.height = 54,
  });

  final bool enabled;
  final VoidCallback? onTap;
  final BoxDecoration decoration;
  final Widget child;
  final double height;

  @override
  State<_Pill> createState() => _PillState();
}

class _PillState extends State<_Pill> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(Radii.pill);
    return AnimatedScale(
      scale: _down && widget.enabled ? 0.97 : 1,
      duration: Motion.quick,
      curve: Motion.curve,
      child: AnimatedOpacity(
        opacity: widget.enabled ? 1 : 0.45,
        duration: Motion.quick,
        child: Container(
          height: widget.height,
          constraints: const BoxConstraints(minWidth: 44),
          decoration: widget.decoration.copyWith(borderRadius: shape),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: shape,
            child: InkWell(
              borderRadius: shape,
              onHighlightChanged: (v) => setState(() => _down = v),
              onTap: widget.enabled
                  ? () {
                      HapticFeedback.selectionClick();
                      widget.onTap?.call();
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.xl),
                child: Center(child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A row of options in one glass track, the chosen one lit in apricot. It
/// replaces a row of check-marked chips for short, exclusive choices such as
/// the length of a focus phase.
class PillSegments<T> extends StatelessWidget {
  const PillSegments({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.labelOf,
  });

  final List<T> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T) labelOf;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Glass.fill,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: Glass.edge),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: Semantics(
                button: true,
                selected: option == selected,
                label: labelOf(option),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (option != selected) HapticFeedback.selectionClick();
                    onChanged(option);
                  },
                  child: AnimatedContainer(
                    duration: Motion.normal,
                    curve: Motion.curve,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      // A lighter wash, not a tinted one: apricot at low alpha
                      // turns muddy brown over dark glass.
                      color: option == selected
                          ? const Color(0x33FFFFFF)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(Radii.pill),
                    ),
                    child: Text(
                      labelOf(option),
                      style: style?.copyWith(
                        color: option == selected ? Tint.cream : Tint.creamDim,
                        fontWeight: option == selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
