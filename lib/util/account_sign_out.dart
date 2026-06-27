import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../model/account.dart';
import '../provider/accounts_notifier_provider.dart';
import '../provider/push_subscription_notifier_provider.dart';
import 'future_with_dialog.dart';

/// Signs [account] out: unsubscribes its push subscription, then removes it from
/// the account list (which also drops the active-account pointer if it referred
/// to this account). Shared by the More tab and the account switcher menu's
/// logout view. Navigation (e.g. to `/login` when no accounts remain) is left to
/// the caller.
Future<void> logOutAccount(
  BuildContext context,
  WidgetRef ref,
  Account account,
) async {
  final pushNotifier = ref.read(
    pushSubscriptionNotifierProvider(account).notifier,
  );
  await futureWithDialog(context, pushNotifier.unsubscribe().then((_) => true));
  await ref.read(accountsNotifierProvider.notifier).remove(account);
}
