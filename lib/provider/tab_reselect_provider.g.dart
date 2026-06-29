// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tab_reselect_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A monotonically increasing signal asking the scrollable view identified by
/// [slot] to react to its owning tab being re-selected: scroll to the top, or,
/// if already at the top, refresh.
///
/// A plain counter (rather than a callback) lets the home shell, the per-tab
/// pages and the list views coordinate without holding references to one
/// another. See [ReselectSlot] for the slot vocabulary.

@ProviderFor(TabReselect)
final tabReselectProvider = TabReselectFamily._();

/// A monotonically increasing signal asking the scrollable view identified by
/// [slot] to react to its owning tab being re-selected: scroll to the top, or,
/// if already at the top, refresh.
///
/// A plain counter (rather than a callback) lets the home shell, the per-tab
/// pages and the list views coordinate without holding references to one
/// another. See [ReselectSlot] for the slot vocabulary.
final class TabReselectProvider extends $NotifierProvider<TabReselect, int> {
  /// A monotonically increasing signal asking the scrollable view identified by
  /// [slot] to react to its owning tab being re-selected: scroll to the top, or,
  /// if already at the top, refresh.
  ///
  /// A plain counter (rather than a callback) lets the home shell, the per-tab
  /// pages and the list views coordinate without holding references to one
  /// another. See [ReselectSlot] for the slot vocabulary.
  TabReselectProvider._({
    required TabReselectFamily super.from,
    required (Account, String) super.argument,
  }) : super(
         retry: null,
         name: r'tabReselectProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tabReselectHash();

  @override
  String toString() {
    return r'tabReselectProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  TabReselect create() => TabReselect();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TabReselectProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tabReselectHash() => r'a6d86f31a19817fd0a93a4d148bf7efc20aa5d88';

/// A monotonically increasing signal asking the scrollable view identified by
/// [slot] to react to its owning tab being re-selected: scroll to the top, or,
/// if already at the top, refresh.
///
/// A plain counter (rather than a callback) lets the home shell, the per-tab
/// pages and the list views coordinate without holding references to one
/// another. See [ReselectSlot] for the slot vocabulary.

final class TabReselectFamily extends $Family
    with $ClassFamilyOverride<TabReselect, int, int, int, (Account, String)> {
  TabReselectFamily._()
    : super(
        retry: null,
        name: r'tabReselectProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A monotonically increasing signal asking the scrollable view identified by
  /// [slot] to react to its owning tab being re-selected: scroll to the top, or,
  /// if already at the top, refresh.
  ///
  /// A plain counter (rather than a callback) lets the home shell, the per-tab
  /// pages and the list views coordinate without holding references to one
  /// another. See [ReselectSlot] for the slot vocabulary.

  TabReselectProvider call(Account account, String slot) =>
      TabReselectProvider._(argument: (account, slot), from: this);

  @override
  String toString() => r'tabReselectProvider';
}

/// A monotonically increasing signal asking the scrollable view identified by
/// [slot] to react to its owning tab being re-selected: scroll to the top, or,
/// if already at the top, refresh.
///
/// A plain counter (rather than a callback) lets the home shell, the per-tab
/// pages and the list views coordinate without holding references to one
/// another. See [ReselectSlot] for the slot vocabulary.

abstract class _$TabReselect extends $Notifier<int> {
  late final _$args = ref.$arg as (Account, String);
  Account get account => _$args.$1;
  String get slot => _$args.$2;

  int build(Account account, String slot);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
