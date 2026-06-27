import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/account.dart';
import 'shared_preferences_provider.dart';

part 'active_account_notifier_provider.g.dart';

/// The account the user has explicitly switched to in the account switcher menu.
///
/// This is a pointer that lives alongside the (stable, user-ordered) account
/// list in [AccountsNotifier] rather than reordering it — Twitter-style, the
/// account order stays put while the "current" account moves independently.
/// [currentAccount] reads this and falls back to the first account when it is
/// `null` or no longer present (e.g. the active account was logged out).
@Riverpod(keepAlive: true)
class ActiveAccountNotifier extends _$ActiveAccountNotifier {
  @override
  Account? build() {
    final value = ref.watch(sharedPreferencesProvider).getString(_key);
    return value != null ? Account.fromString(value) : null;
  }

  static const _key = 'activeAccount';

  Future<void> select(Account account) async {
    state = account;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_key, account.toString());
  }

  Future<void> clear() async {
    state = null;
    await ref.read(sharedPreferencesProvider).remove(_key);
  }
}
