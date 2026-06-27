import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../i18n/strings.g.dart';
import '../../../model/account.dart';
import '../../../provider/api/recommendation_timeline_notifier_provider.dart';
import '../../../provider/for_you_reselect_provider.dart';
import '../../widget/note_widget.dart';
import '../../widget/paginated_list_view.dart';

class ExploreRecommendations extends HookConsumerWidget {
  const ExploreRecommendations({super.key, required this.account});

  final Account account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(recommendationTimelineNotifierProvider(account));
    final scrollController = useScrollController();

    // Re-tapping the "For You" tab (or the Explore navigation destination)
    // jumps to the top and rebuilds the feed; offset 0 re-requests a fresh
    // ranking, so the user sees entirely new recommendations.
    ref.listen(forYouReselectProvider(account), (_, _) {
      if (scrollController.hasClients) {
        unawaited(
          scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          ),
        );
      }
      ref.invalidate(recommendationTimelineNotifierProvider(account));
    });

    return PaginatedListView(
      controller: scrollController,
      paginationState: notes,
      itemBuilder: (context, note) =>
          NoteWidget(account: account, noteId: note.id),
      onRefresh: () =>
          ref.refresh(recommendationTimelineNotifierProvider(account).future),
      loadMore: (skipError) => ref
          .read(recommendationTimelineNotifierProvider(account).notifier)
          .loadMore(skipError: skipError),
      noItemsLabel: t.misskey.noNotes,
    );
  }
}
