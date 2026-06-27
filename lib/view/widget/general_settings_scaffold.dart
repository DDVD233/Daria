import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'adaptive/adaptive_scaffold.dart';
import 'general_settings_navigation.dart';

export 'general_settings_navigation.dart' show GeneralSettingsDestination;

class GeneralSettingsScaffold extends StatelessWidget {
  const GeneralSettingsScaffold({
    super.key,
    this.title,
    this.actions,
    this.body,
    this.floatingActionButton,
    this.selectedDestination,
  });

  final Widget? title;
  final List<Widget>? actions;
  final Widget? body;
  final Widget? floatingActionButton;
  final GeneralSettingsDestination? selectedDestination;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMiddleScreen = width > 800.0;
    final isLargeScreen = width > 1200.0;

    // Phone-sized iOS has no settings rail, so use the native Cupertino page
    // scaffold + navigation bar. Wider layouts (tablet/desktop) keep the
    // Material master-detail rail.
    if (defaultTargetPlatform == TargetPlatform.iOS && !isMiddleScreen) {
      return AdaptiveScaffold(
        title: title,
        actions: actions,
        floatingActionButton: floatingActionButton,
        body: body,
      );
    }

    return Scaffold(
      appBar: title != null || (actions?.isNotEmpty ?? false)
          ? AppBar(title: title, actions: actions)
          : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMiddleScreen)
            Material(
              color: Theme.of(context).colorScheme.surface,
              child: SizedBox(
                width: isLargeScreen ? 300.0 : 48.0,
                height: double.infinity,
                child: GeneralSettingsNavigation(
                  rail: !isLargeScreen,
                  selectedDestination: selectedDestination,
                ),
              ),
            ),
          if (body case final body?) Expanded(child: body),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
