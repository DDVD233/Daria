// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'for_you_reselect_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A monotonically increasing signal asking the "For You" explore feed to scroll
/// back to the top and refresh.
///
/// It is bumped from two unrelated places — re-tapping the "For You" tab inside
/// the explore page, and re-tapping the already-selected Explore destination in
/// the home shell's bottom navigation bar — so a plain counter (rather than a
/// callback) lets both trigger the refresh without holding a reference to the
/// list. `ExploreRecommendations` listens for changes.

@ProviderFor(ForYouReselect)
final forYouReselectProvider = ForYouReselectFamily._();

/// A monotonically increasing signal asking the "For You" explore feed to scroll
/// back to the top and refresh.
///
/// It is bumped from two unrelated places — re-tapping the "For You" tab inside
/// the explore page, and re-tapping the already-selected Explore destination in
/// the home shell's bottom navigation bar — so a plain counter (rather than a
/// callback) lets both trigger the refresh without holding a reference to the
/// list. `ExploreRecommendations` listens for changes.
final class ForYouReselectProvider
    extends $NotifierProvider<ForYouReselect, int> {
  /// A monotonically increasing signal asking the "For You" explore feed to scroll
  /// back to the top and refresh.
  ///
  /// It is bumped from two unrelated places — re-tapping the "For You" tab inside
  /// the explore page, and re-tapping the already-selected Explore destination in
  /// the home shell's bottom navigation bar — so a plain counter (rather than a
  /// callback) lets both trigger the refresh without holding a reference to the
  /// list. `ExploreRecommendations` listens for changes.
  ForYouReselectProvider._({
    required ForYouReselectFamily super.from,
    required Account super.argument,
  }) : super(
         retry: null,
         name: r'forYouReselectProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$forYouReselectHash();

  @override
  String toString() {
    return r'forYouReselectProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ForYouReselect create() => ForYouReselect();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ForYouReselectProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$forYouReselectHash() => r'08cb3b92a13ced83032980af7727614bef8ba34c';

/// A monotonically increasing signal asking the "For You" explore feed to scroll
/// back to the top and refresh.
///
/// It is bumped from two unrelated places — re-tapping the "For You" tab inside
/// the explore page, and re-tapping the already-selected Explore destination in
/// the home shell's bottom navigation bar — so a plain counter (rather than a
/// callback) lets both trigger the refresh without holding a reference to the
/// list. `ExploreRecommendations` listens for changes.

final class ForYouReselectFamily extends $Family
    with $ClassFamilyOverride<ForYouReselect, int, int, int, Account> {
  ForYouReselectFamily._()
    : super(
        retry: null,
        name: r'forYouReselectProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A monotonically increasing signal asking the "For You" explore feed to scroll
  /// back to the top and refresh.
  ///
  /// It is bumped from two unrelated places — re-tapping the "For You" tab inside
  /// the explore page, and re-tapping the already-selected Explore destination in
  /// the home shell's bottom navigation bar — so a plain counter (rather than a
  /// callback) lets both trigger the refresh without holding a reference to the
  /// list. `ExploreRecommendations` listens for changes.

  ForYouReselectProvider call(Account account) =>
      ForYouReselectProvider._(argument: account, from: this);

  @override
  String toString() => r'forYouReselectProvider';
}

/// A monotonically increasing signal asking the "For You" explore feed to scroll
/// back to the top and refresh.
///
/// It is bumped from two unrelated places — re-tapping the "For You" tab inside
/// the explore page, and re-tapping the already-selected Explore destination in
/// the home shell's bottom navigation bar — so a plain counter (rather than a
/// callback) lets both trigger the refresh without holding a reference to the
/// list. `ExploreRecommendations` listens for changes.

abstract class _$ForYouReselect extends $Notifier<int> {
  late final _$args = ref.$arg as Account;
  Account get account => _$args;

  int build(Account account);
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
    return element.handleCreate(ref, () => build(_$args));
  }
}
