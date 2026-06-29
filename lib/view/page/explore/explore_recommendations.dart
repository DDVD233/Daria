import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../i18n/strings.g.dart';
import '../../../model/account.dart';
import '../../../provider/api/recommendation_timeline_notifier_provider.dart';
import '../../../provider/tab_reselect_provider.dart';
import '../../widget/note_widget.dart';
import '../../widget/paginated_list_view.dart';

class ExploreRecommendations extends ConsumerWidget {
  const ExploreRecommendations({
    super.key,
    required this.account,
    this.topInset = 0.0,
  });

  final Account account;
  final double topInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(recommendationTimelineNotifierProvider(account));

    // Re-tapping the "For You" tab (or the Explore navigation destination)
    // scrolls to the top, then on a second tap refreshes the feed; refreshing
    // at offset 0 re-requests a fresh ranking, so the user sees entirely new
    // recommendations.
    return PaginatedListView(
      topInset: topInset,
      reselectAccount: account,
      reselectSlot: ReselectSlot.exploreForYou,
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
