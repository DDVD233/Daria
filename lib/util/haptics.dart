import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../provider/general_settings_notifier_provider.dart';

/// Haptic helpers that honour the global `enableHapticFeedback` setting.
///
/// Centralises the tactile feedback that was previously scattered as raw
/// `HapticFeedback.*` calls, so every cue can be muted from a single place.
bool _hapticsEnabled(WidgetRef ref) =>
    ref.read(generalSettingsNotifierProvider).enableHapticFeedback;

/// A light tap, e.g. confirming a post action (reply/renote/reaction).
void hapticLight(WidgetRef ref) {
  if (_hapticsEnabled(ref)) {
    HapticFeedback.lightImpact();
  }
}

/// A selection tick, e.g. toggling a reaction or moving between options.
void hapticSelection(WidgetRef ref) {
  if (_hapticsEnabled(ref)) {
    HapticFeedback.selectionClick();
  }
}

/// A medium impact, e.g. crossing a drag-to-dismiss threshold.
void hapticImpact(WidgetRef ref) {
  if (_hapticsEnabled(ref)) {
    HapticFeedback.mediumImpact();
  }
}
