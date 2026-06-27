import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../i18n/strings.g.dart';

Future<void> showMessageDialog(
  BuildContext context,
  String message, {
  Widget icon = const Icon(Icons.error_outline),
}) async {
  await showAdaptiveDialog<void>(
    context: context,
    builder: (context) => MessageDialog(message: message, icon: icon),
  );
}

class MessageDialog extends StatelessWidget {
  const MessageDialog({super.key, required this.message, required this.icon});

  final String message;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => context.pop(),
            child: Text(t.misskey.gotIt),
          ),
        ],
      );
    }

    return AlertDialog(
      icon: IconTheme.merge(data: const IconThemeData(size: 36.0), child: icon),
      content: Text(message),
      actions: [
        ElevatedButton(
          autofocus: true,
          onPressed: () => context.pop(),
          child: Text(t.misskey.gotIt),
        ),
      ],
    );
  }
}
