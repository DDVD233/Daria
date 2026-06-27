// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommendation_timeline_notifier_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// dvd.chat's personalized "For You" recommendation feed
/// (`notes/recommendation-timeline`).
///
/// Unlike the other timelines this feed is not chronological: it has no
/// `sinceId`/`untilId` cursors and is paged purely by `offset` (the number of
/// notes already loaded). Refreshing (offset 0) rebuilds the ranking, so it
/// yields an entirely different set of notes each time.

@ProviderFor(RecommendationTimelineNotifier)
final recommendationTimelineNotifierProvider =
    RecommendationTimelineNotifierFamily._();

/// dvd.chat's personalized "For You" recommendation feed
/// (`notes/recommendation-timeline`).
///
/// Unlike the other timelines this feed is not chronological: it has no
/// `sinceId`/`untilId` cursors and is paged purely by `offset` (the number of
/// notes already loaded). Refreshing (offset 0) rebuilds the ranking, so it
/// yields an entirely different set of notes each time.
final class RecommendationTimelineNotifierProvider
    extends
        $StreamNotifierProvider<
          RecommendationTimelineNotifier,
          PaginationState<Note>
        > {
  /// dvd.chat's personalized "For You" recommendation feed
  /// (`notes/recommendation-timeline`).
  ///
  /// Unlike the other timelines this feed is not chronological: it has no
  /// `sinceId`/`untilId` cursors and is paged purely by `offset` (the number of
  /// notes already loaded). Refreshing (offset 0) rebuilds the ranking, so it
  /// yields an entirely different set of notes each time.
  RecommendationTimelineNotifierProvider._({
    required RecommendationTimelineNotifierFamily super.from,
    required Account super.argument,
  }) : super(
         retry: null,
         name: r'recommendationTimelineNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recommendationTimelineNotifierHash();

  @override
  String toString() {
    return r'recommendationTimelineNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RecommendationTimelineNotifier create() => RecommendationTimelineNotifier();

  @override
  bool operator ==(Object other) {
    return other is RecommendationTimelineNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recommendationTimelineNotifierHash() =>
    r'f352d21d51af2005cbfc79851ee4a279b93ee7a9';

/// dvd.chat's personalized "For You" recommendation feed
/// (`notes/recommendation-timeline`).
///
/// Unlike the other timelines this feed is not chronological: it has no
/// `sinceId`/`untilId` cursors and is paged purely by `offset` (the number of
/// notes already loaded). Refreshing (offset 0) rebuilds the ranking, so it
/// yields an entirely different set of notes each time.

final class RecommendationTimelineNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          RecommendationTimelineNotifier,
          AsyncValue<PaginationState<Note>>,
          PaginationState<Note>,
          Stream<PaginationState<Note>>,
          Account
        > {
  RecommendationTimelineNotifierFamily._()
    : super(
        retry: null,
        name: r'recommendationTimelineNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// dvd.chat's personalized "For You" recommendation feed
  /// (`notes/recommendation-timeline`).
  ///
  /// Unlike the other timelines this feed is not chronological: it has no
  /// `sinceId`/`untilId` cursors and is paged purely by `offset` (the number of
  /// notes already loaded). Refreshing (offset 0) rebuilds the ranking, so it
  /// yields an entirely different set of notes each time.

  RecommendationTimelineNotifierProvider call(Account account) =>
      RecommendationTimelineNotifierProvider._(argument: account, from: this);

  @override
  String toString() => r'recommendationTimelineNotifierProvider';
}

/// dvd.chat's personalized "For You" recommendation feed
/// (`notes/recommendation-timeline`).
///
/// Unlike the other timelines this feed is not chronological: it has no
/// `sinceId`/`untilId` cursors and is paged purely by `offset` (the number of
/// notes already loaded). Refreshing (offset 0) rebuilds the ranking, so it
/// yields an entirely different set of notes each time.

abstract class _$RecommendationTimelineNotifier
    extends $StreamNotifier<PaginationState<Note>> {
  late final _$args = ref.$arg as Account;
  Account get account => _$args;

  Stream<PaginationState<Note>> build(Account account);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<PaginationState<Note>>, PaginationState<Note>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<PaginationState<Note>>,
                PaginationState<Note>
              >,
              AsyncValue<PaginationState<Note>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
