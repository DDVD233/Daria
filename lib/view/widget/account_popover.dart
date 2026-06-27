import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../model/account.dart';
import 'account_preview.dart';

/// Shows [builder] in a lightweight popover anchored next to [anchor] (a rect in
/// global/screen coordinates). The barrier is transparent and dismisses on an
/// outside tap or back gesture, so the menu feels non-intrusive. The content
/// fades and scales in, and is free to animate its own size (e.g. with
/// [AnimatedSize]) — the layout follows it and stays clamped on screen.
Future<T?> showAnchoredPopover<T>(
  BuildContext context, {
  required Rect anchor,
  required WidgetBuilder builder,
  double width = 280.0,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    barrierDismissible: true,
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (context, animation, secondaryAnimation) {
      return CustomSingleChildLayout(
        delegate: _PopoverLayoutDelegate(
          anchor: anchor,
          preferredWidth: width,
          padding: MediaQuery.viewPaddingOf(context),
        ),
        child: builder(context),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          alignment: Alignment.topCenter,
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Opens an account picker anchored at [at] (e.g. the position of a long-press)
/// and returns the chosen account, or `null` if dismissed. Used by the
/// "boost/react with account" flows. [current] is highlighted with a check.
Future<Account?> selectAccountAt(
  BuildContext context, {
  required Offset at,
  required Account current,
  required List<Account> candidates,
  required String title,
}) {
  return showAnchoredPopover<Account>(
    context,
    anchor: Rect.fromLTWH(at.dx, at.dy, 0.0, 0.0),
    builder: (context) => AccountPickerCard(
      title: title,
      current: current,
      candidates: candidates,
    ),
  );
}

/// A card listing [candidates] as tappable [AccountPreview] rows; tapping one
/// pops the surrounding route with that account. The [current] account is
/// marked with a check.
class AccountPickerCard extends StatelessWidget {
  const AccountPickerCard({
    super.key,
    required this.title,
    required this.current,
    required this.candidates,
  });

  final String title;
  final Account current;
  final List<Account> candidates;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      type: MaterialType.card,
      elevation: 8.0,
      borderRadius: BorderRadius.circular(12.0),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 4.0),
              child: Text(title, style: theme.textTheme.labelLarge),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  for (final account in candidates)
                    AccountPreview(
                      account: account,
                      avatarSize: 36.0,
                      trailing: account == current
                          ? Icon(Icons.check, color: theme.colorScheme.primary)
                          : null,
                      onTap: () => context.pop(account),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Positions the popover child below (or, when it doesn't fit, above) the
/// anchor, clamped within the safe area.
class _PopoverLayoutDelegate extends SingleChildLayoutDelegate {
  _PopoverLayoutDelegate({
    required this.anchor,
    required this.preferredWidth,
    required this.padding,
  });

  final Rect anchor;
  final double preferredWidth;
  final EdgeInsets padding;

  static const double _margin = 8.0;
  static const double _gap = 6.0;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final maxWidth = (constraints.maxWidth - 2 * _margin).clamp(0.0, 560.0);
    return BoxConstraints(
      maxWidth: preferredWidth < maxWidth ? preferredWidth : maxWidth,
      maxHeight:
          constraints.maxHeight - padding.top - padding.bottom - 2 * _margin,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final spaceBelow = size.height - anchor.bottom - padding.bottom - _gap;
    final fitsBelow = childSize.height <= spaceBelow;
    final top = fitsBelow
        ? anchor.bottom + _gap
        : (anchor.top - _gap - childSize.height);
    const minLeft = _margin;
    final maxLeft = size.width - childSize.width - _margin;
    final left = anchor.left.clamp(
      minLeft,
      maxLeft < minLeft ? minLeft : maxLeft,
    );
    final minTop = padding.top + _margin;
    final maxTop = size.height - padding.bottom - childSize.height - _margin;
    return Offset(left, top.clamp(minTop, maxTop < minTop ? minTop : maxTop));
  }

  @override
  bool shouldRelayout(_PopoverLayoutDelegate oldDelegate) =>
      anchor != oldDelegate.anchor ||
      preferredWidth != oldDelegate.preferredWidth ||
      padding != oldDelegate.padding;
}
