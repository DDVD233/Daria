import 'package:aria/model/id.dart';
import 'package:aria/model/tab_settings.dart';
import 'package:aria/util/group_notes_into_threads.dart';
import 'package:aria/view/widget/timeline_list_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_dart/misskey_dart.dart';

import '../../test_util/dummy_note.dart';

Note createDummyNote(int day, [int hour = 0]) {
  return dummyNote.copyWith(
    id: Id(
      method: IdGenMethod.aidx,
      date: DateTime(2025, 1, day, hour),
    ).toString(),
  );
}

/// Standalone (unthreaded) display notes for the given days, newest-first.
List<DisplayNote> createDummyDisplayNotes(int end, int start) {
  return List.generate(
    end - start,
    (i) => DisplayNote(note: createDummyNote(end - i)),
  );
}

void main() {
  group('computeNewNotesDividerIndex', () {
    final widget = TimelineListView(tabSettings: TabSettings.dummy());

    group(
      'should return null if the last viewed note is newer than the latest note',
      () {
        test('both', () {
          final result = widget.computeNewNotesDividerIndex(
            lastViewedNoteId: createDummyNote(21).id,
            nextDisplay: createDummyDisplayNotes(20, 10),
            previousDisplay: createDummyDisplayNotes(10, 0),
          );
          expect(result, isNull);
        });

        test('next', () {
          final result = widget.computeNewNotesDividerIndex(
            lastViewedNoteId: createDummyNote(21).id,
            nextDisplay: createDummyDisplayNotes(20, 10),
            previousDisplay: const [],
          );
          expect(result, isNull);
        });

        test('previous', () {
          final result = widget.computeNewNotesDividerIndex(
            lastViewedNoteId: createDummyNote(11).id,
            nextDisplay: const [],
            previousDisplay: createDummyDisplayNotes(10, 0),
          );
          expect(result, isNull);
        });

        test('none', () {
          final result = widget.computeNewNotesDividerIndex(
            lastViewedNoteId: createDummyNote(1).id,
            nextDisplay: const [],
            previousDisplay: const [],
          );
          expect(result, isNull);
        });
      },
    );

    group(
      'should return null if the last viewed note is the same as the latest note',
      () {
        test('both', () {
          final result = widget.computeNewNotesDividerIndex(
            lastViewedNoteId: createDummyNote(20).id,
            nextDisplay: createDummyDisplayNotes(20, 10),
            previousDisplay: createDummyDisplayNotes(10, 0),
          );
          expect(result, isNull);
        });

        test('next', () {
          final result = widget.computeNewNotesDividerIndex(
            lastViewedNoteId: createDummyNote(20).id,
            nextDisplay: createDummyDisplayNotes(20, 10),
            previousDisplay: const [],
          );
          expect(result, isNull);
        });

        test('previous', () {
          final result = widget.computeNewNotesDividerIndex(
            lastViewedNoteId: createDummyNote(10).id,
            nextDisplay: const [],
            previousDisplay: createDummyDisplayNotes(10, 0),
          );
          expect(result, isNull);
        });
      },
    );

    group(
      'should return index if the last viewed note is older than the latest '
      'note and newer than the oldest note',
      () {
        group('both', () {
          test(1, () {
            final result = widget.computeNewNotesDividerIndex(
              lastViewedNoteId: createDummyNote(19).id,
              nextDisplay: createDummyDisplayNotes(20, 10),
              previousDisplay: createDummyDisplayNotes(10, 0),
            );
            expect(result, 9);
          });

          test(2, () {
            final result = widget.computeNewNotesDividerIndex(
              lastViewedNoteId: createDummyNote(10, 1).id,
              nextDisplay: createDummyDisplayNotes(20, 10),
              previousDisplay: createDummyDisplayNotes(10, 0),
            );
            expect(result, 0);
          });

          test(3, () {
            final result = widget.computeNewNotesDividerIndex(
              lastViewedNoteId: createDummyNote(10).id,
              nextDisplay: createDummyDisplayNotes(20, 10),
              previousDisplay: createDummyDisplayNotes(10, 0),
            );
            expect(result, 0);
          });

          test(4, () {
            final result = widget.computeNewNotesDividerIndex(
              lastViewedNoteId: createDummyNote(9).id,
              nextDisplay: createDummyDisplayNotes(20, 10),
              previousDisplay: createDummyDisplayNotes(10, 0),
            );
            expect(result, -1);
          });
        });

        group('next', () {
          test(1, () {
            final result = widget.computeNewNotesDividerIndex(
              lastViewedNoteId: createDummyNote(19, 1).id,
              nextDisplay: createDummyDisplayNotes(20, 10),
              previousDisplay: const [],
            );
            expect(result, 9);
          });

          test(2, () {
            final result = widget.computeNewNotesDividerIndex(
              lastViewedNoteId: createDummyNote(11).id,
              nextDisplay: createDummyDisplayNotes(20, 10),
              previousDisplay: const [],
            );
            expect(result, 1);
          });
        });

        group('previous', () {
          test(1, () {
            final result = widget.computeNewNotesDividerIndex(
              lastViewedNoteId: createDummyNote(9, 1).id,
              nextDisplay: const [],
              previousDisplay: createDummyDisplayNotes(10, 0),
            );
            expect(result, -1);
          });

          test(2, () {
            final result = widget.computeNewNotesDividerIndex(
              lastViewedNoteId: createDummyNote(1, 1).id,
              nextDisplay: const [],
              previousDisplay: createDummyDisplayNotes(10, 0),
            );
            expect(result, -9);
          });
        });
      },
    );

    group('places the divider between whole threads, never inside one', () {
      // A thread [day12 -> day14] (positioned by its leaf, day14) sits between
      // standalone day20 and standalone day11.
      List<DisplayNote> nextWithThread() => [
        DisplayNote(note: createDummyNote(20)),
        DisplayNote(note: createDummyNote(12), connectBottom: true),
        DisplayNote(note: createDummyNote(14), connectTop: true),
        DisplayNote(note: createDummyNote(11)),
      ];

      test('boundary below a thread whose leaf is still new', () {
        // Last viewed day13: the thread leaf (day14) is newer, so the divider
        // lands above the next seen unit (day11), below the whole thread.
        final result = widget.computeNewNotesDividerIndex(
          lastViewedNoteId: createDummyNote(13).id,
          nextDisplay: nextWithThread(),
          previousDisplay: const [],
        );
        expect(result, 1);
      });

      test('boundary snaps above a thread whose leaf has been seen', () {
        // Last viewed day14 (the thread leaf): the divider snaps above the
        // thread root (day12) rather than between the two thread members.
        final result = widget.computeNewNotesDividerIndex(
          lastViewedNoteId: createDummyNote(14).id,
          nextDisplay: nextWithThread(),
          previousDisplay: const [],
        );
        expect(result, 3);
      });
    });
  });
}
