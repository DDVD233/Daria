import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../i18n/strings.g.dart';
import '../../../model/account.dart';
import '../../../provider/for_you_reselect_provider.dart';
import 'explore_featured.dart';
import 'explore_recommendations.dart';
import 'explore_users.dart';

class ExplorePage extends HookConsumerWidget {
  const ExplorePage({super.key, required this.account, this.barsAnimation});

  final Account account;

  /// When non-null (Android), the top bar collapses/expands with this
  /// animation as the feed is scrolled. When null, the bar is fixed.
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

    final appBar = AppBar(
      title: Text(t.misskey.explore),
      bottom: TabBar(
        controller: controller,
        // Re-tapping the already-selected "For You" tab scrolls it back to
        // the top and refreshes the recommendation feed.
        onTap: (index) {
          if (controller.indexIsChanging) return;
          if (showRecommendations && index == 0) {
            ref.read(forYouReselectProvider(account).notifier).notifyReselect();
          }
        },
        tabs: tabs,
      ),
    );

    final body = TabBarView(
      controller: controller,
      children: [
        if (showRecommendations) ExploreRecommendations(account: account),
        ExploreFeatured(account: account),
        ExploreUsers(account: account),
      ],
    );

    final barsAnimation = this.barsAnimation;
    if (barsAnimation == null) {
      return Scaffold(appBar: appBar, body: body);
    }
    // Android: collapse the top bar upward as the feed is scrolled down.
    // Constrain the bar to a fixed height (toolbar + tab bar + status bar
    // inset) so the AppBar — which lays its toolbar out in an Expanded when it
    // has a `bottom` — can size inside the unbounded Column/SizeTransition.
    final barHeight =
        appBar.preferredSize.height + MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizeTransition(
            sizeFactor: barsAnimation,
            alignment: Alignment.topCenter,
            child: SizedBox(height: barHeight, child: appBar),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
