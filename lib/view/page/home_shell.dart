import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:misskey_dart/misskey_dart.dart';

import '../../i18n/strings.g.dart';
import '../../model/account.dart';
import '../../model/tab_settings.dart';
import '../../model/tab_type.dart';
import '../../provider/accounts_notifier_provider.dart';
import '../../provider/api/endpoints_notifier_provider.dart';
import '../../provider/api/i_notifier_provider.dart';
import '../../provider/current_account_provider.dart';
import '../../provider/for_you_reselect_provider.dart';
import '../../provider/misskey_colors_provider.dart';
import '../../util/account_sign_out.dart';
import '../../util/haptics.dart';
import '../dialog/confirmation_dialog.dart';
import '../widget/account_switcher_menu.dart';
import '../widget/adaptive/adaptive_scaffold.dart';
import '../widget/timeline_list_view.dart';
import '../widget/user_avatar.dart';
import 'explore/explore_page.dart';
import 'notifications_page.dart';
import 'search/search_page.dart';

/// The main app shell shown once an account is signed in.
///
/// Replaces the legacy multi-account [TimelinesPage] with a single-account,
/// Twitter-style layout: a platform-native bottom navigation bar (Home,
/// Search, Notification, Explore, More), a swipeable set of timelines on the
/// Home tab, a floating compose button and a profile avatar.
class HomeShell extends HookConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(currentAccountProvider);
    final index = useState(0);
    // Destinations are built lazily on first visit, then kept alive so their
    // state (scroll position, search input) survives nav switches. This also
    // avoids the Search tab's auto-focusing field grabbing focus at launch.
    final visited = useRef(<int>{0});

    // Drives the show/hide of the top and bottom bars as the timeline is
    // scrolled (Android only). 1.0 = fully shown, 0.0 = hidden.
    final barsController = useAnimationController(
      duration: const Duration(milliseconds: 200),
      initialValue: 1.0,
    );
    // Only Android auto-hides the bars on scroll; elsewhere they stay fixed.
    final autoHideBars = defaultTargetPlatform == TargetPlatform.android;

    // Guard against the brief window after sign out where the account list is
    // empty but the router redirect to /login has not run yet.
    if (account == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final hasUnreadNotification = ref.watch(
      iNotifierProvider(
        account,
      ).select((i) => i.value?.hasUnreadNotification ?? false),
    );

    Widget destination(int i) {
      if (!visited.value.contains(i)) return const SizedBox.shrink();
      return switch (i) {
        0 => _TimelinesTab(
          account: account,
          barsAnimation: autoHideBars ? barsController : null,
        ),
        1 => SearchPage(account: account),
        2 => NotificationsPage(account: account),
        3 => ExplorePage(
          account: account,
          barsAnimation: autoHideBars ? barsController : null,
        ),
        _ => _MoreTab(account: account),
      };
    }

    // Reveal or hide the bars based on the active timeline's vertical scroll
    // direction. Horizontal swipes (e.g. between timelines) are ignored.
    bool handleScroll(ScrollNotification notification) {
      if (notification.metrics.axis != Axis.vertical) return false;
      if (notification is UserScrollNotification) {
        final direction = notification.direction;
        if (direction == ScrollDirection.reverse) {
          // Scrolling down: hide, unless bouncing at the very top.
          if (notification.metrics.pixels >
              notification.metrics.minScrollExtent) {
            unawaited(barsController.reverse());
          }
        } else if (direction == ScrollDirection.forward) {
          unawaited(barsController.forward()); // Scrolling up: reveal.
        }
      } else if (notification is ScrollUpdateNotification) {
        // Always show the bars once back at the top.
        if (notification.metrics.pixels <=
            notification.metrics.minScrollExtent) {
          unawaited(barsController.forward());
        }
      }
      return false;
    }

    final body = IndexedStack(
      index: index.value,
      children: [for (var i = 0; i < 5; i++) destination(i)],
    );

    final navBar = _AdaptiveNavBar(
      selectedIndex: index.value,
      onSelect: (value) {
        // Re-tapping the already-selected Explore destination refreshes the
        // "For You" feed (scroll to top + re-request recommendations).
        if (value == index.value && value == 3) {
          ref.read(forYouReselectProvider(account).notifier).notifyReselect();
        }
        // A light selection tick when moving to a different tab (honours the
        // global haptic-feedback setting).
        if (value != index.value) {
          hapticSelection(ref);
        }
        // Make sure the bars are visible again whenever the tab changes.
        unawaited(barsController.forward());
        visited.value.add(value);
        index.value = value;
      },
      hasUnreadNotification: hasUnreadNotification,
    );

    return Scaffold(
      // On iOS, let the tab content extend behind the bottom navigation bar so
      // [CupertinoTabBar]'s native translucent backdrop blur reveals the content
      // scrolling underneath. Left off on Material, whose [NavigationBar] is
      // opaque, so content would just be hidden behind it.
      extendBody: defaultTargetPlatform == TargetPlatform.iOS,
      body: autoHideBars
          ? NotificationListener<ScrollNotification>(
              onNotification: handleScroll,
              child: body,
            )
          : body,
      floatingActionButton: index.value == 0
          ? _ComposeFab(account: account)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // Collapse the bottom nav downward as the timeline is scrolled down.
      bottomNavigationBar: autoHideBars
          ? SizeTransition(
              sizeFactor: barsController,
              alignment: Alignment.bottomCenter,
              child: navBar,
            )
          : navBar,
    );
  }
}

/// The Home tab: the 3 swipeable timelines (Home, Local, Social) bound
/// to the single current account.
class _TimelinesTab extends HookConsumerWidget {
  const _TimelinesTab({required this.account, this.barsAnimation});

  final Account account;

  /// When non-null (Android), the top bar collapses/expands with this
  /// animation as the timeline is scrolled. When null, the bar is fixed.
  final Animation<double>? barsAnimation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = useMemoized(
      () => [
        TabSettings.homeTimeline(account),
        TabSettings.localTimeline(account),
        TabSettings(tabType: TabType.hybridTimeline, account: account),
      ],
      [account],
    );
    final controller = useTabController(initialLength: 3, keys: [account]);

    final appBar = AppBar(
      toolbarHeight: 64.0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12.0, top: 8.0),
        child: Center(child: _ProfileAvatarButton(account: account)),
      ),
      titleSpacing: 0.0,
      title: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: TabBar(
          controller: controller,
          tabs: [
            Tab(text: t.misskey.timelines_.home),
            Tab(text: t.misskey.timelines_.local),
            Tab(text: t.misskey.timelines_.social),
          ],
        ),
      ),
    );

    final body = TabBarView(
      controller: controller,
      children: [
        for (final tabSettings in tabs)
          TimelineListView(tabSettings: tabSettings),
      ],
    );

    final barsAnimation = this.barsAnimation;
    if (barsAnimation == null) {
      return Scaffold(appBar: appBar, body: body);
    }
    // Android: collapse the top bar upward as the timeline is scrolled down.
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizeTransition(
            sizeFactor: barsAnimation,
            alignment: Alignment.topCenter,
            child: appBar,
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// Profile avatar shown in the upper-left of the Home tab; opens the Twitter-style
/// account switcher menu anchored to itself.
class _ProfileAvatarButton extends ConsumerWidget {
  const _ProfileAvatarButton({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i = ref.watch(iNotifierProvider(account)).value;
    void openMenu() => unawaited(showAccountSwitcher(context, context));

    return i != null
        ? UserAvatar(account: account, user: i, size: 28.0, onTap: openMenu)
        : IconButton(
            onPressed: openMenu,
            icon: const Icon(Icons.account_circle),
          );
  }
}

/// Floating compose button at the lower-right; opens the full post screen.
class _ComposeFab extends ConsumerWidget {
  const _ComposeFab({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(
      misskeyColorsProvider(Theme.of(context).brightness),
    );

    return FloatingActionButton(
      backgroundColor: colors.accent,
      foregroundColor: colors.fgOnAccent,
      onPressed: () => unawaited(context.push('/$account/post')),
      child: const Icon(Icons.edit),
    );
  }
}

/// Platform-native bottom navigation: [CupertinoTabBar] on iOS, Material 3
/// [NavigationBar] elsewhere.
class _AdaptiveNavBar extends ConsumerWidget {
  const _AdaptiveNavBar({
    required this.selectedIndex,
    required this.onSelect,
    required this.hasUnreadNotification,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool hasUnreadNotification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinations = [
      (
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        cupertinoIcon: CupertinoIcons.house_fill,
        label: t.misskey.timelines_.home,
        badge: false,
      ),
      (
        icon: Icons.search,
        selectedIcon: Icons.search,
        cupertinoIcon: CupertinoIcons.search,
        label: t.misskey.search,
        badge: false,
      ),
      (
        icon: Icons.notifications_outlined,
        selectedIcon: Icons.notifications,
        cupertinoIcon: CupertinoIcons.bell_fill,
        label: t.misskey.notifications,
        badge: hasUnreadNotification,
      ),
      (
        icon: Icons.explore_outlined,
        selectedIcon: Icons.explore,
        cupertinoIcon: CupertinoIcons.compass_fill,
        label: t.misskey.explore,
        badge: false,
      ),
      (
        icon: Icons.menu,
        selectedIcon: Icons.menu,
        cupertinoIcon: CupertinoIcons.ellipsis,
        label: t.misskey.more,
        badge: false,
      ),
    ];

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final accent = ref.watch(
        misskeyColorsProvider(
          Theme.of(context).brightness,
        ).select((colors) => colors.accent),
      );
      return CupertinoTabBar(
        currentIndex: selectedIndex,
        onTap: onSelect,
        activeColor: accent,
        iconSize: 24.0,
        items: [
          for (final (i, d) in destinations.indexed)
            BottomNavigationBarItem(
              // Subtle "pop" on the active icon for a more responsive feel;
              // [CupertinoTabBar] otherwise just recolours it.
              icon: AnimatedScale(
                scale: i == selectedIndex ? 1.18 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: d.badge
                    ? Badge(child: Icon(d.cupertinoIcon))
                    : Icon(d.cupertinoIcon),
              ),
              label: d.label,
            ),
        ],
      );
    }

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelect,
      destinations: [
        for (final d in destinations)
          NavigationDestination(
            icon: d.badge ? Badge(child: Icon(d.icon)) : Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: d.label,
          ),
      ],
    );
  }
}

/// The More tab: secondary destinations, settings and sign out for the current
/// account. Mirrors the menu set of the legacy [TimelineDrawer] without the
/// multi-account chrome.
class _MoreTab extends ConsumerWidget {
  const _MoreTab({required this.account});

  final Account account;

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final router = GoRouter.of(context);
    final confirmed = await confirm(context, message: t.misskey.logoutConfirm);
    if (!confirmed) return;
    if (!context.mounted) return;
    await logOutAccount(context, ref, account);
    // Fall back to the timeline of another account, or onboarding if none left.
    if (ref.read(accountsNotifierProvider).isEmpty) {
      router.go('/login');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i = ref.watch(iNotifierProvider(account)).value;
    final endpoints = ref.watch(endpointsNotifierProvider(account.host)).value;
    final chatAvailable =
        i?.policies?.chatAvailability != ChatAvailability.unavailable &&
        (endpoints?.contains('chat/history') ?? true);

    final destinations = <({IconData icon, String label, VoidCallback onTap})>[
      (
        icon: Icons.person,
        label: t.misskey.profile,
        onTap: () => context.push('/$account/@${account.username}'),
      ),
      (
        icon: Icons.list,
        label: t.misskey.lists,
        onTap: () => context.push('/$account/lists'),
      ),
      (
        icon: Icons.settings_input_antenna,
        label: t.misskey.antennas,
        onTap: () => context.push('/$account/antennas'),
      ),
      (
        icon: Icons.attach_file,
        label: t.misskey.clips,
        onTap: () => context.push('/$account/clips'),
      ),
      (
        icon: Icons.star_rounded,
        label: t.misskey.favorites,
        onTap: () => context.push('/$account/favorites'),
      ),
      (
        icon: Icons.cloud,
        label: t.misskey.drive,
        onTap: () => context.push('/$account/drive'),
      ),
      if (chatAvailable)
        (
          icon: Icons.message,
          label: t.misskey.directMessage_short,
          onTap: () => context.push('/$account/chat'),
        ),
      (
        icon: Icons.tv,
        label: t.misskey.channel,
        onTap: () => context.push('/$account/channels'),
      ),
      (
        icon: Icons.article,
        label: t.misskey.pages,
        onTap: () => context.push('/$account/pages'),
      ),
      (
        icon: Icons.play_arrow,
        label: 'Play',
        onTap: () => context.push('/$account/play'),
      ),
      (
        icon: Icons.collections,
        label: t.misskey.gallery,
        onTap: () => context.push('/$account/gallery'),
      ),
      (
        icon: Icons.games,
        label: 'Misskey Games',
        onTap: () => context.push('/$account/games'),
      ),
      (
        icon: Icons.campaign,
        label: t.misskey.announcements,
        onTap: () => context.push('/$account/announcements'),
      ),
      (
        icon: Icons.dns,
        label: t.misskey.instanceInfo,
        onTap: () => context.push('/$account/servers/${account.host}'),
      ),
    ];
    final errorColor = Theme.of(context).colorScheme.error;

    // Native iOS: inset-grouped Cupertino sections with disclosure chevrons.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AdaptiveScaffold(
        title: Text(t.misskey.more),
        body: ListView(
          children: [
            CupertinoListSection.insetGrouped(
              children: [
                for (final d in destinations)
                  CupertinoListTile.notched(
                    leading: Icon(d.icon),
                    title: Text(d.label),
                    trailing: const CupertinoListTileChevron(),
                    onTap: d.onTap,
                  ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              children: [
                CupertinoListTile.notched(
                  leading: const Icon(Icons.settings),
                  title: Text(t.misskey.settings),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => context.push('/settings'),
                ),
                CupertinoListTile.notched(
                  leading: Icon(Icons.logout, color: errorColor),
                  title: Text(
                    t.misskey.logout,
                    style: TextStyle(color: errorColor),
                  ),
                  onTap: () => unawaited(_signOut(context, ref)),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.misskey.more)),
      body: ListView(
        children: [
          for (final d in destinations)
            ListTile(
              leading: Icon(d.icon),
              title: Text(d.label),
              onTap: d.onTap,
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(t.misskey.settings),
            onTap: () => context.push('/settings'),
          ),
          ListTile(
            leading: Icon(Icons.logout, color: errorColor),
            title: Text(t.misskey.logout, style: TextStyle(color: errorColor)),
            onTap: () => unawaited(_signOut(context, ref)),
          ),
        ],
      ),
    );
  }
}
