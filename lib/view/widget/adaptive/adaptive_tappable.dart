import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../provider/general_settings_notifier_provider.dart';

/// A tap surface that adapts its press feedback to the platform.
///
/// - iOS has no ink ripple, so a tap produces a subtle scale + opacity dip
///   (skipped when `reduceAnimation` is on).
/// - Other platforms keep the Material [InkWell] ripple, unchanged.
///
/// Requires a [Material] ancestor (for the [InkWell] branch); the existing note
/// widget already provides one.
class AdaptiveTappable extends ConsumerStatefulWidget {
  const AdaptiveTappable({
    super.key,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.borderRadius,
    required this.child,
  });

  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;
  final Widget child;

  @override
  ConsumerState<AdaptiveTappable> createState() => _AdaptiveTappableState();
}

class _AdaptiveTappableState extends ConsumerState<AdaptiveTappable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return InkWell(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        onLongPress: widget.onLongPress,
        borderRadius: widget.borderRadius,
        child: widget.child,
      );
    }

    final hasGesture =
        widget.onTap != null ||
        widget.onDoubleTap != null ||
        widget.onLongPress != null;
    final reduceAnimation = ref.watch(
      generalSettingsNotifierProvider.select((s) => s.reduceAnimation),
    );
    final animate = hasGesture && !reduceAnimation;

    Widget content = widget.child;
    if (animate) {
      content = AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.72 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: content,
        ),
      );
    }

    // Use an InkWell (not a raw GestureDetector) even on iOS: InkResponse has
    // built-in parent<->child coordination, so nested buttons win the gesture
    // arena (their long-press works) and a pressed child suppresses this note's
    // highlight (so touching a button doesn't dim the whole note). A raw
    // GestureDetector does neither. The ripple is disabled; the scale/opacity
    // above is the iOS press feedback, driven by the highlight state.
    return InkWell(
      onTap: widget.onTap,
      onDoubleTap: widget.onDoubleTap,
      onLongPress: widget.onLongPress,
      borderRadius: widget.borderRadius,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onHighlightChanged: animate ? _setPressed : null,
      child: content,
    );
  }
}
