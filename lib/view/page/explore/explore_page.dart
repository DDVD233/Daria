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
  const ExplorePage({super.key, required this.account});

  final Account account;

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

    return Scaffold(
      appBar: AppBar(
        title: Text(t.misskey.explore),
        bottom: TabBar(
          controller: controller,
          // Re-tapping the already-selected "For You" tab scrolls it back to
          // the top and refreshes the recommendation feed.
          onTap: (index) {
            if (controller.indexIsChanging) return;
            if (showRecommendations && index == 0) {
              ref
                  .read(forYouReselectProvider(account).notifier)
                  .notifyReselect();
            }
          },
          tabs: tabs,
        ),
      ),
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
}
