import 'package:misskey_dart/misskey_dart.dart';

import '../extension/note_extension.dart';

/// A timeline note together with thread-connector flags describing whether a
/// gray line should be drawn through its avatar to the note above
/// ([connectTop]) and/or below ([connectBottom]) it.
class DisplayNote {
  const DisplayNote({
    required this.note,
    this.connectTop = false,
    this.connectBottom = false,
  });

  final Note note;

  /// Whether this note's parent is rendered directly above it (connected).
  final bool connectTop;

  /// Whether this note has a reply rendered directly below it (connected).
  final bool connectBottom;

  /// The first member of a thread (a thread root or a standalone note) is the
  /// note that has nothing connected above it.
  bool get isThreadStart => !connectTop;
}

/// Reorders a newest-first list of timeline [notes] so that reply chains that
/// are fully present within the list are grouped into Twitter-style threads.
///
/// A thread is a chain `root -> ... -> leaf` where each note is a reply to the
/// previous one and both ends are present in [notes]. Members are emitted
/// oldest (root) first so the thread reads top-to-bottom, and the whole thread
/// is positioned at its newest (leaf) note's position in the feed. Notes that
/// are not part of any chain are returned as single-element threads, preserving
/// the original newest-first ordering.
///
/// When a note has several replies present in the list (a tree), only the
/// single longest descendant chain is threaded onto it; the other branches are
/// re-emitted as their own threads/standalone notes. Renotes are never threaded.
List<DisplayNote> orderTimelineForThreads(List<Note> notes) {
  if (notes.length < 2) {
    return [for (final note in notes) DisplayNote(note: note)];
  }

  final byId = {for (final note in notes) note.id: note};

  // A note can be chained only if it is a genuine note (not a pure renote).
  bool isChainable(Note note) => !note.isRenote;

  // The id of [note]'s parent, but only when that parent is present in the list
  // and both notes are chainable.
  String? presentParentId(Note note) {
    final replyId = note.replyId;
    if (replyId == null || !isChainable(note)) {
      return null;
    }
    final parent = byId[replyId];
    if (parent == null || !isChainable(parent)) {
      return null;
    }
    return replyId;
  }

  // Build present parent -> children edges.
  final children = <String, List<Note>>{};
  for (final note in notes) {
    final parentId = presentParentId(note);
    if (parentId != null) {
      (children[parentId] ??= <Note>[]).add(note);
    }
  }

  // Length (in notes) of the longest descendant chain starting at [note].
  // Replies always have a larger id than their parent, so the child graph is
  // acyclic and this terminates.
  final lengthCache = <String, int>{};
  int longestLen(Note note) {
    final cached = lengthCache[note.id];
    if (cached != null) {
      return cached;
    }
    var best = 1;
    for (final child in children[note.id] ?? const <Note>[]) {
      final len = 1 + longestLen(child);
      if (len > best) {
        best = len;
      }
    }
    return lengthCache[note.id] = best;
  }

  // Roots are chainable-or-not notes whose parent is not present; each starts a
  // thread (which may be a single standalone note).
  final queue = [
    for (final note in notes)
      if (presentParentId(note) == null) note,
  ];

  final visited = <String>{};
  final chains = <List<Note>>[];
  for (var i = 0; i < queue.length; i++) {
    final root = queue[i];
    if (visited.contains(root.id)) {
      continue;
    }
    final chain = <Note>[];
    Note? node = root;
    while (node != null && !visited.contains(node.id)) {
      visited.add(node.id);
      chain.add(node);
      final kids = children[node.id];
      if (kids == null || kids.isEmpty) {
        break;
      }
      // Extend the thread through the child with the longest descendant chain
      // (ties broken by smallest id for determinism); re-queue the rest.
      Note? best;
      var bestLen = -1;
      for (final kid in kids) {
        if (visited.contains(kid.id)) {
          continue;
        }
        final len = longestLen(kid);
        if (len > bestLen ||
            (len == bestLen && best != null && kid.id.compareTo(best.id) < 0)) {
          bestLen = len;
          best = kid;
        }
      }
      for (final kid in kids) {
        if (kid != best && !visited.contains(kid.id)) {
          queue.add(kid);
        }
      }
      node = best;
    }
    if (chain.isNotEmpty) {
      chains.add(chain);
    }
  }

  // Position each thread at its newest (leaf) note and emit members root->leaf.
  chains.sort((a, b) => b.last.id.compareTo(a.last.id));
  return [
    for (final chain in chains)
      for (final (index, note) in chain.indexed)
        DisplayNote(
          note: note,
          connectTop: index > 0,
          connectBottom: index < chain.length - 1,
        ),
  ];
}
