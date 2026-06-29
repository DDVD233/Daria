import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../i18n/strings.g.dart';
import '../../../model/account.dart';
import '../../../provider/tab_reselect_provider.dart';
import 'explore_featured.dart';
import 'explore_recommendations.dart';
import 'explore_users.dart';

class ExplorePage extends HookConsumerWidget {
  const ExplorePage({super.key, required this.account, this.barsAnimation});

  final Account account;

  /// When non-null, the top bar collapses/expands with this animation as the
  /// feed is scrolled. When null, the bar is fixed.
  final Animation<double>? barsAnimation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The personalized recommendation feed is specific to dvd.chat. When
    // available it is the first (and default) tab.
    final showRecommendations = account.host.toLowerCase() == 'dvd.chat';
    final tabs = [
      if (showRecommendations) Tab(text: t.aria.forYou),
      Tab(text: t.misskey.featured),
      Tab(text: t.misskey.users),
    ];
    final controller = useTabController(initialLength: tabs.length);

    // Maps a sub-tab index to its [ReselectSlot] (the "For You" tab is only
    // present on instances offering recommendations).
    String slotAt(int index) {
      if (showRecommendations) {
        return switch (index) {
          0 => ReselectSlot.exploreForYou,
          1 => ReselectSlot.exploreFeatured,
          _ => ReselectSlot.exploreUsers,
        };
      }
      return switch (index) {
        0 => ReselectSlot.exploreFeatured,
        _ => ReselectSlot.exploreUsers,
      };
    }

    // Re-tapping the Explore destination fans the signal out to the visible
    // sub-tab (scroll to top, then refresh).
    ref.listen(tabReselectProvider(account, ReselectSlot.explore), (_, _) {
      ref
          .read(tabReselectProvider(account, slotAt(controller.index)).notifier)
          .notify();
    });

    final appBar = AppBar(
      title: Text(t.misskey.explore),
      bottom: TabBar(
        controller: controller,
        // Re-tapping the already-selected sub-tab scrolls it to the top, then
        // refreshes on a further tap once already at the top.
        onTap: (index) {
          if (controller.indexIsChanging) return;
          ref
              .read(tabReselectProvider(account, slotAt(index)).notifier)
              .notify();
        },
        tabs: tabs,
      ),
    );

    final barsAnimation = this.barsAnimation;
    if (barsAnimation == null) {
      return Scaffold(
        appBar: appBar,
        body: TabBarView(
          controller: controller,
          children: [
            if (showRecommendations) ExploreRecommendations(account: account),
            ExploreFeatured(account: account),
            ExploreUsers(account: account),
          ],
        ),
      );
    }
    // Overlay the top bar on full-bleed content so the feed never resizes as the
    // bar hides — the scroll stays entirely user-controlled. A scrollable
    // [PaginatedListView.topInset] spacer keeps content clear of the bar when
    // shown. The bar is held at a fixed height (toolbar + tab bar + status bar)
    // so its toolbar — laid out in an Expanded because of the `bottom` tab bar —
    // can size inside the unbounded overlay.
    final topBarHeight =
        appBar.preferredSize.height + MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: TabBarView(
              controller: controller,
              children: [
                if (showRecommendations)
                  ExploreRecommendations(
                    account: account,
                    topInset: topBarHeight,
                  ),
                ExploreFeatured(account: account, topInset: topBarHeight),
                ExploreUsers(account: account, topInset: topBarHeight),
              ],
            ),
          ),
          Positioned(
            top: 0.0,
            left: 0.0,
            right: 0.0,
            child: AnimatedBuilder(
              animation: barsAnimation,
              builder: (context, child) => Transform.translate(
                offset: Offset(
                  0.0,
                  -(1.0 - barsAnimation.value) * topBarHeight,
                ),
                child: child,
              ),
              child: SizedBox(height: topBarHeight, child: appBar),
            ),
          ),
        ],
      ),
    );
  }
}
