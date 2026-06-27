import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../i18n/strings.g.dart';

/// A single action in an [showAdaptiveActionSheet].
class AdaptiveAction {
  const AdaptiveAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isDestructive;
}

/// Presents a menu of [actions]: a [CupertinoActionSheet] on iOS, a Material
/// [showModalBottomSheet] list elsewhere.
///
/// The sheet is dismissed before [AdaptiveAction.onPressed] runs, so callbacks
/// that push a route or open another sheet behave correctly.
Future<void> showAdaptiveActionSheet({
  required BuildContext context,
  required List<AdaptiveAction> actions,
  Widget? title,
  Widget? message,
  bool showCancel = true,
}) {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: title,
        message: message,
        actions: [
          for (final action in actions)
            CupertinoActionSheetAction(
              isDestructiveAction: action.isDestructive,
              onPressed: () {
                Navigator.pop(sheetContext);
                action.onPressed();
              },
              child: Text(action.label),
            ),
        ],
        cancelButton: showCancel
            ? CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(sheetContext),
                child: Text(t.misskey.cancel),
              )
            : null,
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            ListTile(title: DefaultTextStyle.merge(child: title)),
          for (final action in actions)
            ListTile(
              leading: action.icon != null ? Icon(action.icon) : null,
              textColor: action.isDestructive
                  ? Theme.of(sheetContext).colorScheme.error
                  : null,
              iconColor: action.isDestructive
                  ? Theme.of(sheetContext).colorScheme.error
                  : null,
              title: Text(action.label),
              onTap: () {
                Navigator.pop(sheetContext);
                action.onPressed();
              },
            ),
        ],
      ),
    ),
  );
}
