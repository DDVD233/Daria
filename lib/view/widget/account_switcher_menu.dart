import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../../model/account.dart';
import '../../provider/accounts_notifier_provider.dart';
import '../../provider/active_account_notifier_provider.dart';
import '../../provider/api/i_notifier_provider.dart';
import '../../provider/current_account_provider.dart';
import '../../util/account_sign_out.dart';
import 'account_popover.dart';
import 'user_avatar.dart';

/// Opens the Twitter-style account switcher anchored to [anchorContext]'s render
/// box (the profile avatar button).
Future<void> showAccountSwitcher(
  BuildContext context,
  BuildContext anchorContext,
) {
  final box = anchorContext.findRenderObject() as RenderBox?;
  final anchor = box != null && box.hasSize
      ? box.localToGlobal(Offset.zero) & box.size
      : Rect.fromLTWH(0.0, MediaQuery.viewPaddingOf(context).top, 0.0, 0.0);
  return showAnchoredPopover<void>(
    context,
    anchor: anchor,
    builder: (context) => const AccountSwitcherMenu(),
  );
}

enum _Mode { accounts, logout }

class AccountSwitcherMenu extends HookConsumerWidget {
  const AccountSwitcherMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = useState(_Mode.accounts);

    return Material(
      type: MaterialType.card,
      elevation: 8.0,
      borderRadius: BorderRadius.circular(12.0),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: switch (mode.value) {
          _Mode.accounts => _AccountsView(
            onLogout: () => mode.value = _Mode.logout,
          ),
          _Mode.logout => _LogoutView(
            onBack: () => mode.value = _Mode.accounts,
          ),
        },
      ),
    );
  }
}

class _AccountsView extends ConsumerWidget {
  const _AccountsView({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsNotifierProvider);
    final current = ref.watch(currentAccountProvider);
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                for (final account in accounts)
                  _AccountRow(
                    account: account,
                    active: account == current,
                    onTap: () {
                      unawaited(
                        ref
                            .read(activeAccountNotifierProvider.notifier)
                            .select(account),
                      );
                      context.pop();
                    },
                  ),
              ],
            ),
          ),
          const Divider(height: 0.0),
          ListTile(
            leading: const Icon(Icons.add),
            title: Text(t.misskey.addAccount),
            onTap: () {
              context.pop();
              unawaited(context.push('/login'));
            },
          ),
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text(
              t.misskey.logout,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends ConsumerWidget {
  const _AccountRow({
    required this.account,
    required this.active,
    required this.onTap,
  });

  final Account account;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i = ref.watch(iNotifierProvider(account)).value;
    final theme = Theme.of(context);

    return ListTile(
      selected: active,
      leading: i != null
          ? UserAvatar(account: account, user: i, size: 36.0)
          : const Icon(Icons.account_circle, size: 36.0),
      title: Text(
        account.host,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textDirection: TextDirection.ltr,
      ),
      subtitle: account.username != null
          ? Text(
              '@${account.username}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.ltr,
            )
          : null,
      trailing: active
          ? Icon(Icons.check, color: theme.colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}

class _LogoutView extends HookConsumerWidget {
  const _LogoutView({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsNotifierProvider);
    final selected = useState<Account?>(null);
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            dense: true,
            leading: const Icon(Icons.arrow_back),
            title: Text(t.misskey.logout),
            onTap: onBack,
          ),
          const Divider(height: 0.0),
          Flexible(
            child: RadioGroup<Account>(
              groupValue: selected.value,
              onChanged: (value) => selected.value = value,
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  for (final account in accounts)
                    RadioListTile<Account>(
                      value: account,
                      title: Text(
                        account.toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              onPressed: selected.value != null
                  ? () => unawaited(_confirm(context, ref, selected.value!))
                  : null,
              icon: const Icon(Icons.logout),
              label: Text(t.misskey.logout),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    WidgetRef ref,
    Account account,
  ) async {
    final router = GoRouter.of(context);
    await logOutAccount(context, ref, account);
    if (!context.mounted) return;
    context.pop();
    if (ref.read(accountsNotifierProvider).isEmpty) {
      router.go('/login');
    }
  }
}
