// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tos_accepted_notifier_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the user has accepted the dvd.chat Terms of Service and Privacy
/// Policy. Shown once on first login; persisted so it is not shown again.

@ProviderFor(TosAcceptedNotifier)
final tosAcceptedNotifierProvider = TosAcceptedNotifierProvider._();

/// Whether the user has accepted the dvd.chat Terms of Service and Privacy
/// Policy. Shown once on first login; persisted so it is not shown again.
final class TosAcceptedNotifierProvider
    extends $NotifierProvider<TosAcceptedNotifier, bool> {
  /// Whether the user has accepted the dvd.chat Terms of Service and Privacy
  /// Policy. Shown once on first login; persisted so it is not shown again.
  TosAcceptedNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tosAcceptedNotifierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tosAcceptedNotifierHash();

  @$internal
  @override
  TosAcceptedNotifier create() => TosAcceptedNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$tosAcceptedNotifierHash() =>
    r'4fda0adbf2e0eefaf612980f4da162834e4ecb1a';

/// Whether the user has accepted the dvd.chat Terms of Service and Privacy
/// Policy. Shown once on first login; persisted so it is not shown again.

abstract class _$TosAcceptedNotifier extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
