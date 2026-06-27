// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_account_notifier_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The account the user has explicitly switched to in the account switcher menu.
///
/// This is a pointer that lives alongside the (stable, user-ordered) account
/// list in [AccountsNotifier] rather than reordering it — Twitter-style, the
/// account order stays put while the "current" account moves independently.
/// [currentAccount] reads this and falls back to the first account when it is
/// `null` or no longer present (e.g. the active account was logged out).

@ProviderFor(ActiveAccountNotifier)
final activeAccountNotifierProvider = ActiveAccountNotifierProvider._();

/// The account the user has explicitly switched to in the account switcher menu.
///
/// This is a pointer that lives alongside the (stable, user-ordered) account
/// list in [AccountsNotifier] rather than reordering it — Twitter-style, the
/// account order stays put while the "current" account moves independently.
/// [currentAccount] reads this and falls back to the first account when it is
/// `null` or no longer present (e.g. the active account was logged out).
final class ActiveAccountNotifierProvider
    extends $NotifierProvider<ActiveAccountNotifier, Account?> {
  /// The account the user has explicitly switched to in the account switcher menu.
  ///
  /// This is a pointer that lives alongside the (stable, user-ordered) account
  /// list in [AccountsNotifier] rather than reordering it — Twitter-style, the
  /// account order stays put while the "current" account moves independently.
  /// [currentAccount] reads this and falls back to the first account when it is
  /// `null` or no longer present (e.g. the active account was logged out).
  ActiveAccountNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeAccountNotifierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeAccountNotifierHash();

  @$internal
  @override
  ActiveAccountNotifier create() => ActiveAccountNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Account? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Account?>(value),
    );
  }
}

String _$activeAccountNotifierHash() =>
    r'b7829fd5eb86b2ca8cd4eeffb3b1c85b0b2cfef6';

/// The account the user has explicitly switched to in the account switcher menu.
///
/// This is a pointer that lives alongside the (stable, user-ordered) account
/// list in [AccountsNotifier] rather than reordering it — Twitter-style, the
/// account order stays put while the "current" account moves independently.
/// [currentAccount] reads this and falls back to the first account when it is
/// `null` or no longer present (e.g. the active account was logged out).

abstract class _$ActiveAccountNotifier extends $Notifier<Account?> {
  Account? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Account?, Account?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Account?, Account?>,
              Account?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
