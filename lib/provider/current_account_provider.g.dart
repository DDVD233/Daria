// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_account_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The account the app is currently acting as.
///
/// Follows the user-selectable pointer in [ActiveAccountNotifier] (the account
/// switcher menu), falling back to the first account in the list when nothing
/// is selected or the selected account is no longer present (e.g. it was logged
/// out). Returns `null` when no account exists yet (first launch / after sign
/// out), which the onboarding gate in the router uses to send the user to the
/// login page.

@ProviderFor(currentAccount)
final currentAccountProvider = CurrentAccountProvider._();

/// The account the app is currently acting as.
///
/// Follows the user-selectable pointer in [ActiveAccountNotifier] (the account
/// switcher menu), falling back to the first account in the list when nothing
/// is selected or the selected account is no longer present (e.g. it was logged
/// out). Returns `null` when no account exists yet (first launch / after sign
/// out), which the onboarding gate in the router uses to send the user to the
/// login page.

final class CurrentAccountProvider
    extends $FunctionalProvider<Account?, Account?, Account?>
    with $Provider<Account?> {
  /// The account the app is currently acting as.
  ///
  /// Follows the user-selectable pointer in [ActiveAccountNotifier] (the account
  /// switcher menu), falling back to the first account in the list when nothing
  /// is selected or the selected account is no longer present (e.g. it was logged
  /// out). Returns `null` when no account exists yet (first launch / after sign
  /// out), which the onboarding gate in the router uses to send the user to the
  /// login page.
  CurrentAccountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentAccountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentAccountHash();

  @$internal
  @override
  $ProviderElement<Account?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Account? create(Ref ref) {
    return currentAccount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Account? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Account?>(value),
    );
  }
}

String _$currentAccountHash() => r'ec72f4016527781a55d38aba75319405f67e0c28';
