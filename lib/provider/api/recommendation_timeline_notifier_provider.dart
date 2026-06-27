import 'package:misskey_dart/misskey_dart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../model/account.dart';
import '../../model/pagination_state.dart';
import '../notes_notifier_provider.dart';
import 'misskey_provider.dart';

part 'recommendation_timeline_notifier_provider.g.dart';

/// dvd.chat's personalized "For You" recommendation feed
/// (`notes/recommendation-timeline`).
///
/// Unlike the other timelines this feed is not chronological: it has no
/// `sinceId`/`untilId` cursors and is paged purely by `offset` (the number of
/// notes already loaded). Refreshing (offset 0) rebuilds the ranking, so it
/// yields an entirely different set of notes each time.
@riverpod
class RecommendationTimelineNotifier extends _$RecommendationTimelineNotifier {
  @override
  Stream<PaginationState<Note>> build(Account account) async* {
    final response = await _fetchNotes();
    yield PaginationState.fromIterable(response);
    if (response.isNotEmpty && response.length < 10) {
      await loadMore();
    }
  }

  Future<Iterable<Note>> _fetchNotes({int? offset}) async {
    final response = await ref
        .read(misskeyProvider(account))
        .apiService
        .post<List<dynamic>>('notes/recommendation-timeline', {
          'limit': 15,
          'offset': offset,
        });
    final notes = response.map((e) => Note.fromJson(e as Map<String, Object?>));
    ref.read(notesNotifierProvider(account).notifier).addAll(notes);
    return notes;
  }

  Future<void> loadMore({bool skipError = false}) async {
    if (state.isLoading || (state.hasError && !skipError)) {
      return;
    }
    final value = skipError ? state.value : await future;
    if (value?.isLastLoaded ?? false) {
      return;
    }
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final response = await _fetchNotes(offset: value?.items.length);
      return PaginationState(
        items: [...?value?.items, ...response],
        isLastLoaded: response.isEmpty,
      );
    });
  }
}
