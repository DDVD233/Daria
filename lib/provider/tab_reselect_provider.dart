import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/account.dart';

part 'tab_reselect_provider.g.dart';

/// Slot identifiers for [tabReselectProvider].
///
/// The outer slots ([home], [notifications], [explore]) are bumped by the home
/// shell when an already-selected bottom-navigation destination is re-tapped.
/// The per-tab pages listen for their outer slot and fan the signal out to the
/// inner slot of whichever sub-tab is currently visible; the matching list view
/// then scrolls to the top, or refreshes if already there.
abstract final class ReselectSlot {
  // Bottom-navigation destinations.
  static const home = 'home';
  static const notifications = 'notifications';
  static const explore = 'explore';

  // Home sub-tabs.
  static const homeTimeline = 'home:home';
  static const localTimeline = 'home:local';
  static const socialTimeline = 'home:social';

  // Notifications sub-tabs.
  static const notificationsAll = 'notifications:all';
  static const notificationsMentions = 'notifications:mentions';
  static const notificationsDirect = 'notifications:direct';
  static const notificationsFollowRequests = 'notifications:followRequests';

  // Explore sub-tabs.
  static const exploreForYou = 'explore:foryou';
  static const exploreFeatured = 'explore:featured';
  static const exploreUsers = 'explore:users';
}

/// A monotonically increasing signal asking the scrollable view identified by
/// [slot] to react to its owning tab being re-selected: scroll to the top, or,
/// if already at the top, refresh.
///
/// A plain counter (rather than a callback) lets the home shell, the per-tab
/// pages and the list views coordinate without holding references to one
/// another. See [ReselectSlot] for the slot vocabulary.
@riverpod
class TabReselect extends _$TabReselect {
  @override
  int build(Account account, String slot) => 0;

  void notify() => state++;
}
