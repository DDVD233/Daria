import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../extension/scroll_controller_extension.dart';
import '../../model/account.dart';
import '../../provider/tab_reselect_provider.dart';

/// Wires the [tabReselectProvider] signal for [slot] to [controller].
///
/// Call from a consumer's `build`. When the slot is bumped (the owning tab is
/// re-tapped) the view scrolls to the top if it is scrolled, otherwise it
/// refreshes — by triggering [refreshKey]'s indicator when given, or else
/// calling [onRefresh]. A null [slot] disables the listener, so the shared list
/// views keep their default behaviour wherever they are used outside the shell.
void listenTabReselect(
  WidgetRef ref, {
  required Account account,
  required String? slot,
  required ScrollController controller,
  GlobalKey<RefreshIndicatorState>? refreshKey,
  Future<void> Function()? onRefresh,
}) {
  if (slot == null) return;
  ref.listen(tabReselectProvider(account, slot), (_, _) {
    // Treat "within a few px of the top" as already-at-top so the second tap
    // refreshes; a center-anchored timeline can rest a hair above 0.
    if (controller.hasClients && controller.position.extentBefore > 8.0) {
      unawaited(controller.scrollToTop());
    } else if (refreshKey?.currentState case final state?) {
      unawaited(state.show());
    } else if (onRefresh != null) {
      unawaited(onRefresh());
    }
  });
}
