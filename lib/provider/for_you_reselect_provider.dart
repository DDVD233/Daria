import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/account.dart';

part 'for_you_reselect_provider.g.dart';

/// A monotonically increasing signal asking the "For You" explore feed to scroll
/// back to the top and refresh.
///
/// It is bumped from two unrelated places — re-tapping the "For You" tab inside
/// the explore page, and re-tapping the already-selected Explore destination in
/// the home shell's bottom navigation bar — so a plain counter (rather than a
/// callback) lets both trigger the refresh without holding a reference to the
/// list. `ExploreRecommendations` listens for changes.
@riverpod
class ForYouReselect extends _$ForYouReselect {
  @override
  int build(Account account) => 0;

  void notifyReselect() => state++;
}
