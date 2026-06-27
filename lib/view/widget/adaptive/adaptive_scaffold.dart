import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A page scaffold that renders native iOS chrome on iOS and Material chrome
/// elsewhere.
///
/// - iOS: [CupertinoPageScaffold] with a [CupertinoNavigationBar]. The bar is
///   kept opaque so [CupertinoPageScaffold] lays the body *below* it; a
///   translucent bar would require every body to inset for it, and bodies that
///   are [CustomScrollView]s (unlike [ListView]) don't do that automatically,
///   so their first item would hide behind the bar. The body is wrapped in a
///   transparent [Material] so the Material widgets inside it (ink, list tiles,
///   text fields) still find a [Material] ancestor.
/// - Other platforms: a plain [Scaffold] + [AppBar], identical to before.
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.body,
    this.floatingActionButton,
    this.backgroundColor,
    this.automaticallyImplyLeading = true,
    this.resizeToAvoidBottomInset,
  });

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? body;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool automaticallyImplyLeading;
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final trailing = switch (actions) {
        null || [] => null,
        [final action] => action,
        final actions => Row(mainAxisSize: MainAxisSize.min, children: actions),
      };
      Widget content = Material(
        type: MaterialType.transparency,
        child: body ?? const SizedBox.shrink(),
      );
      if (floatingActionButton case final fab?) {
        content = Stack(
          children: [
            Positioned.fill(child: content),
            SafeArea(
              child: Align(
                alignment: AlignmentDirectional.bottomEnd,
                child: Padding(padding: const EdgeInsets.all(16.0), child: fab),
              ),
            ),
          ],
        );
      }
      return CupertinoPageScaffold(
        backgroundColor: backgroundColor,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset ?? true,
        navigationBar: CupertinoNavigationBar(
          middle: title,
          leading: leading,
          trailing: trailing,
          automaticallyImplyLeading: automaticallyImplyLeading,
          // Opaque (fully obstructing) so the body is laid out below the bar
          // instead of scrolling behind it. Derived from the themed bar colour.
          backgroundColor: CupertinoTheme.of(
            context,
          ).barBackgroundColor.withValues(alpha: 1.0),
        ),
        child: content,
      );
    }

    final hasAppBar =
        title != null ||
        leading != null ||
        (actions?.isNotEmpty ?? false) ||
        automaticallyImplyLeading;
    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: hasAppBar
          ? AppBar(
              title: title,
              leading: leading,
              actions: actions,
              automaticallyImplyLeading: automaticallyImplyLeading,
            )
          : null,
      body: body,
    );
  }
}
