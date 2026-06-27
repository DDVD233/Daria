import 'package:aria/util/group_notes_into_threads.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_dart/misskey_dart.dart';

import '../test_util/dummy_note.dart';

Note note(String id, {String? replyId, String? renoteId, String userId = 'u'}) {
  return dummyNote.copyWith(
    id: id,
    replyId: replyId,
    renoteId: renoteId,
    userId: userId,
  );
}

List<String> ids(List<DisplayNote> notes) => [for (final n in notes) n.note.id];

/// `t` = connectTop, `b` = connectBottom for each display note, e.g. `.tb`.
List<String> flags(List<DisplayNote> notes) => [
  for (final n in notes)
    '${n.connectTop ? 't' : '.'}${n.connectBottom ? 'b' : '.'}',
];

void main() {
  group('orderTimelineForThreads', () {
    test('returns standalone notes unchanged (newest-first preserved)', () {
      final result = orderTimelineForThreads([note('c'), note('b'), note('a')]);
      expect(ids(result), ['c', 'b', 'a']);
      expect(flags(result), ['..', '..', '..']);
    });

    test('threads a linear chain oldest-first with connectors', () {
      // a <- b <- c, given newest-first.
      final result = orderTimelineForThreads([
        note('c', replyId: 'b'),
        note('b', replyId: 'a'),
        note('a'),
      ]);
      expect(ids(result), ['a', 'b', 'c']);
      expect(flags(result), ['.b', 'tb', 't.']);
    });

    test('keeps only the longest chain at a branch, re-emits the rest', () {
      // a has children b and c; c has child d -> thread a-c-d, b standalone.
      final result = orderTimelineForThreads([
        note('d', replyId: 'c'),
        note('c', replyId: 'a'),
        note('b', replyId: 'a'),
        note('a'),
      ]);
      expect(ids(result), ['a', 'c', 'd', 'b']);
      expect(flags(result), ['.b', 'tb', 't.', '..']);
    });

    test('positions a thread by its newest (leaf) note', () {
      // Unrelated note "b" sits between a and c by id, but the a<-c thread is
      // positioned by leaf c and so floats above b.
      final result = orderTimelineForThreads([
        note('c', replyId: 'a'),
        note('b'),
        note('a'),
      ]);
      expect(ids(result), ['a', 'c', 'b']);
      expect(flags(result), ['.b', 't.', '..']);
    });

    test('never threads renotes', () {
      // "b" is a pure renote of "a"; "c" replies to that renote.
      final result = orderTimelineForThreads([
        note('c', replyId: 'b'),
        note('b', renoteId: 'a'),
        note('a'),
      ]);
      expect(ids(result), ['c', 'b', 'a']);
      expect(flags(result), ['..', '..', '..']);
    });

    test('threads a chain spanning multiple authors', () {
      final result = orderTimelineForThreads([
        note('c', replyId: 'b', userId: 'u3'),
        note('b', replyId: 'a', userId: 'u2'),
        note('a', userId: 'u1'),
      ]);
      expect(ids(result), ['a', 'b', 'c']);
      expect(flags(result), ['.b', 'tb', 't.']);
    });

    test('handles an empty list', () {
      expect(orderTimelineForThreads([]), isEmpty);
    });
  });
}
