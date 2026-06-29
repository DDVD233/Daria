import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../../model/account.dart';
import '../../model/tab_settings.dart';
import '../../provider/api/i_notifier_provider.dart';
import '../../provider/tab_reselect_provider.dart';
import '../widget/follow_requests_list_view.dart';
import '../widget/notifications_list_view.dart';
import '../widget/timeline_list_view.dart';

class NotificationsPage extends HookConsumerWidget {
  const NotificationsPage({super.key, required this.account});

  final Account account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i = ref.watch(iNotifierProvider(account)).value;
    final isLocked = i?.isLocked ?? false;
    final tabs = [
      Tab(text: t.misskey.all),
      Tab(text: t.misskey.mentions),
      Tab(text: t.misskey.directNotes),
      if (isLocked) Tab(text: t.misskey.followRequests),
    ];
    final views = [
      NotificationsListView(
        account: account,
        reselectSlot: ReselectSlot.notificationsAll,
      ),
      TimelineListView(
        tabSettings: TabSettings.mention(account),
        reselectSlot: ReselectSlot.notificationsMentions,
      ),
      TimelineListView(
        tabSettings: TabSettings.direct(account),
        reselectSlot: ReselectSlot.notificationsDirect,
      ),
      if (isLocked)
        FollowRequestsListView(
          account: account,
          reselectSlot: ReselectSlot.notificationsFollowRequests,
        ),
    ];
    final controller = useTabController(
      initialLength: tabs.length,
      keys: [account, tabs.length],
    );

    // Re-tapping the Notifications destination fans the signal out to the
    // visible sub-tab (scroll to top, then refresh).
    ref.listen(tabReselectProvider(account, ReselectSlot.notifications), (
      _,
      _,
    ) {
      final slot = switch (controller.index) {
        0 => ReselectSlot.notificationsAll,
        1 => ReselectSlot.notificationsMentions,
        2 => ReselectSlot.notificationsDirect,
        _ => ReselectSlot.notificationsFollowRequests,
      };
      ref.read(tabReselectProvider(account, slot).notifier).notify();
    });

    // On iOS, an opaque [CupertinoNavigationBar] lays the body below it, so the
    // tab bar can sit at the top of the body (Cupertino has no app-bar `bottom`
    // slot). Other platforms keep the original Material app bar + `bottom` tabs.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(t.misskey.notifications),
          automaticallyImplyLeading: false,
          backgroundColor: CupertinoTheme.of(
            context,
          ).barBackgroundColor.withValues(alpha: 1.0),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            children: [
              TabBar(controller: controller, tabs: tabs),
              Expanded(
                child: TabBarView(controller: controller, children: views),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.misskey.notifications),
        bottom: TabBar(controller: controller, tabs: tabs),
      ),
      body: TabBarView(controller: controller, children: views),
    );
  }
}
