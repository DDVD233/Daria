import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../i18n/strings.g.dart';

Future<bool> confirm(
  BuildContext context, {
  Widget? title,
  String? message,
  Widget? content,
  String? okText,
  String? cancelText,
}) async {
  final result = await showAdaptiveDialog<bool>(
    context: context,
    builder: (context) => ConfirmationDialog(
      title: title,
      message: message,
      content: content,
      okText: okText,
      cancelText: cancelText,
    ),
  );
  return result ?? false;
}

class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    this.title,
    this.message,
    this.content,
    this.okText,
    this.cancelText,
  });

  final Widget? title;
  final String? message;
  final Widget? content;
  final String? okText;
  final String? cancelText;

  @override
  Widget build(BuildContext context) {
    // Native iOS alert; Android keeps the original Material dialog untouched.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return CupertinoAlertDialog(
        title: title,
        content: content ?? Text(message ?? ''),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => context.pop(true),
            child: Text(okText ?? t.misskey.ok),
          ),
          CupertinoDialogAction(
            onPressed: () => context.pop(false),
            child: Text(cancelText ?? t.misskey.cancel),
          ),
        ],
      );
    }

    final theme = Theme.of(context);

    return AlertDialog(
      icon: title == null ? const Icon(Icons.help_outline, size: 36.0) : null,
      title: title,
      content: content ?? Text(message ?? ''),
      actions: [
        ElevatedButton(
          autofocus: true,
          onPressed: () => context.pop(true),
          child: Text(okText ?? t.misskey.ok),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.surfaceContainerLowest,
          ),
          onPressed: () => context.pop(false),
          child: Text(cancelText ?? t.misskey.cancel),
        ),
      ],
      scrollable: true,
    );
  }
}
