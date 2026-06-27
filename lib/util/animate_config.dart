import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../provider/general_settings_notifier_provider.dart';

/// A consistent entrance: a quick fade combined with a small upward slide.
///
/// Pass a [delay] to stagger a list/section of items.
List<Effect<dynamic>> entranceEffects({Duration? delay}) => [
  FadeEffect(
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeOut,
    delay: delay,
  ),
  MoveEffect(
    begin: const Offset(0, 8),
    end: Offset.zero,
    duration: const Duration(milliseconds: 260),
    curve: Curves.easeOutCubic,
    delay: delay,
  ),
];

/// Applies [effects] to [child] unless the user enabled `reduceAnimation`, in
/// which case [child] is returned unchanged.
///
/// This is the single chokepoint for honouring the accessibility setting, so new
/// animations should funnel through here rather than calling `.animate()`
/// directly.
Widget maybeAnimate(
  WidgetRef ref,
  Widget child, {
  required List<Effect<dynamic>> effects,
}) {
  final reduce = ref.watch(
    generalSettingsNotifierProvider.select((s) => s.reduceAnimation),
  );
  if (reduce) {
    return child;
  }
  return child.animate(effects: effects);
}
