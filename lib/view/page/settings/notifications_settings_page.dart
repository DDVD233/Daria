import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constant/max_content_width.dart';
import '../../../i18n/strings.g.dart';
import '../../../model/account.dart';
import '../../../provider/api/i_notifier_provider.dart';
import '../../../provider/api/meta_notifier_provider.dart';
import '../../../provider/push_subscription_notifier_provider.dart';
import '../../../util/future_with_dialog.dart';
import '../../../util/subscribe_push_notification.dart';
import '../../widget/account_settings_scaffold.dart';

class NotificationsSettingsPage extends ConsumerWidget {
  const NotificationsSettingsPage({super.key, required this.account});

  final Account account;

  Future<void> _unsubscribe(WidgetRef ref) {
    return futureWithDialog(
      ref.context,
      ref
          .read(pushSubscriptionNotifierProvider(account).notifier)
          .unsubscribe(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i = ref.watch(iNotifierProvider(account)).value;
    final endpoint = ref.watch(pushSubscriptionNotifierProvider(account));
    final meta = ref.watch(metaNotifierProvider(account.host)).value;
    final isPushNotificationSupported = switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => meta?.swPublickey != null,
      _ => false,
    };
    final theme = Theme.of(context);

    return AccountSettingsScaffold(
      account: account,
      appBar: AppBar(title: Text(t.misskey.notifications)),
      body: ListView(
        children: [
          const SizedBox(height: 16.0),
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              width: maxContentWidth,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                t.misskey.pushNotification,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              width: maxContentWidth,
              child: SwitchListTile.adaptive(
                title: Text(t.misskey.subscribePushNotification),
                value: endpoint != null,
                onChanged: endpoint != null
                    ? (_) => _unsubscribe(ref)
                    : i != null && isPushNotificationSupported
                    ? (_) async {
                        await subscribePushNotification(ref, account);
                      }
                    : null,
                tileColor: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: const Radius.circular(8.0),
                    bottom: Radius.circular(switch (defaultTargetPlatform) {
                      TargetPlatform.android || TargetPlatform.iOS => 0.0,
                      _ => 8.0,
                    }),
                  ),
                ),
              ),
            ),
          ),
          if (defaultTargetPlatform
              case TargetPlatform.android || TargetPlatform.iOS)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                width: maxContentWidth,
                child: ListTile(
                  title: Text(t.aria.openNotificationSettings),
                  trailing: const Icon(Icons.navigate_next),
                  onTap: () => AppSettings.openAppSettings(
                    type: AppSettingsType.notification,
                  ),
                  tileColor: theme.colorScheme.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(8.0),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      selectedDestination: AccountSettingsDestination.notifications,
    );
  }
}
