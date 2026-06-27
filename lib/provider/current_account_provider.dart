import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/account.dart';
import 'accounts_notifier_provider.dart';
import 'active_account_notifier_provider.dart';

part 'current_account_provider.g.dart';

/// The account the app is currently acting as.
///
/// Follows the user-selectable pointer in [ActiveAccountNotifier] (the account
/// switcher menu), falling back to the first account in the list when nothing
/// is selected or the selected account is no longer present (e.g. it was logged
/// out). Returns `null` when no account exists yet (first launch / after sign
/// out), which the onboarding gate in the router uses to send the user to the
/// login page.
@riverpod
Account? currentAccount(Ref ref) {
  final accounts = ref.watch(accountsNotifierProvider);
  if (accounts.isEmpty) return null;
  final active = ref.watch(activeAccountNotifierProvider);
  return active != null && accounts.contains(active) ? active : accounts.first;
}
