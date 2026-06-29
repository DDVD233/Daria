import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constant/inifite_scroll_extent_threshold.dart';
import '../../constant/max_content_width.dart';
import '../../model/account.dart';
import '../../model/pagination_state.dart';
import '../../provider/general_settings_notifier_provider.dart';
import 'haptic_feedback_refresh_indicator.dart';
import 'pagination_bottom_widget.dart';
import 'tab_reselect.dart';

class PaginatedListView<T> extends HookConsumerWidget {
  const PaginatedListView({
    super.key,
    this.controller,
    this.header,
    required this.paginationState,
    required this.itemBuilder,
    this.footer,
    this.onRefresh,
    this.loadMore,
    this.panel = true,
    this.noItemsLabel,
    this.reselectAccount,
    this.reselectSlot,
    this.topInset = 0.0,
  });

  final ScrollController? controller;
  final Widget? header;

  /// Height of a scrollable spacer prepended at the top of the list, so content
  /// scrolls out from under an overlaying, auto-hiding top bar.
  final double topInset;
  final AsyncValue<PaginationState<T>>? paginationState;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Widget? footer;
  final Future<void> Function()? onRefresh;
  final void Function(bool skipError)? loadMore;
  final bool panel;
  final String? noItemsLabel;

  /// When both are set, the list listens to [tabReselectProvider] for this
  /// account/slot and, on re-tap of its owning tab, scrolls to the top or
  /// refreshes (via [onRefresh]) if already there.
  final Account? reselectAccount;
  final String? reselectSlot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = this.controller ?? useScrollController();
    final refreshKey = useMemoized(
      () => GlobalKey<RefreshIndicatorState>(),
      [],
    );
    if (reselectAccount case final account?) {
      listenTabReselect(
        ref,
        account: account,
        slot: reselectSlot,
        controller: controller,
        refreshKey: refreshKey,
        onRefresh: onRefresh,
      );
    }
    final isAtBottom = useState(false);
    useEffect(() {
      void callback() {
        if (controller.position.extentAfter < infiniteScrollExtentThreshold) {
          if (!isAtBottom.value) {
            loadMore?.call(false);
            isAtBottom.value = true;
          }
        } else {
          isAtBottom.value = false;
        }
      }

      if (ref.read(generalSettingsNotifierProvider).enableInfiniteScroll) {
        controller.addListener(callback);
      }
      return () => controller.removeListener(callback);
    }, [loadMore]);

    return HapticFeedbackRefreshIndicator(
      indicatorKey: refreshKey,
      onRefresh: onRefresh ?? () async {},
      child: CustomScrollView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (topInset > 0.0)
            SliverToBoxAdapter(child: SizedBox(height: topInset)),
          if (header case final header?) header,
          if (paginationState case final paginationState?) ...[
            if (paginationState.value?.items case final items?
                when items.isNotEmpty)
              SliverList.separated(
                itemBuilder: (context, index) => Center(
                  child: Container(
                    margin: EdgeInsets.only(
                      top: index == 0 ? 8.0 : 0.0,
                      left: 8.0,
                      right: 8.0,
                      bottom: index == items.length - 1 ? 8.0 : 0.0,
                    ),
                    width: maxContentWidth,
                    child: panel
                        ? Material(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.vertical(
                              top: index == 0
                                  ? const Radius.circular(8.0)
                                  : Radius.zero,
                              bottom: index == items.length - 1
                                  ? const Radius.circular(8.0)
                                  : Radius.zero,
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: itemBuilder(context, items[index]),
                          )
                        : itemBuilder(context, items[index]),
                  ),
                ),
                separatorBuilder: (context, index) => Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    width: maxContentWidth,
                    child: panel
                        ? const Divider(height: 0.0)
                        : const SizedBox(height: 8.0),
                  ),
                ),
                itemCount: items.length,
              ),
            SliverToBoxAdapter(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                  width: maxContentWidth,
                  child: PaginationBottomWidget(
                    paginationState: paginationState,
                    noItemsLabel: noItemsLabel,
                    loadMore: loadMore != null ? () => loadMore!(true) : null,
                    height: 120.0,
                  ),
                ),
              ),
            ),
          ],
          if (footer case final footer?) footer,
        ],
      ),
    );
  }
}
