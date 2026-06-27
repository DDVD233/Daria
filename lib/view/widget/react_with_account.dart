import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:misskey_dart/misskey_dart.dart' hide Clip;

import '../../i18n/strings.g.dart';
import '../../model/account.dart';
import '../../model/sound_settings.dart';
import '../../provider/accounts_notifier_provider.dart';
import '../../provider/misskey_sfx_notifier_provider.dart';
import '../../provider/note_notifier_provider.dart';
import '../../provider/notes_notifier_provider.dart';
import '../../util/future_with_dialog.dart';
import '../../util/resolve_note_for_account.dart';
import 'account_popover.dart';
import 'reaction_users_sheet.dart';

/// Long-press behaviour for a reaction with a fixed [emoji] (an existing
/// reaction chip, the like button, …).
///
/// With more than one usable account, opens the "react with account" picker
/// anchored at [at] and reacts to [note] with [emoji] as the chosen account
/// (resolving the note cross-server first). With a single account there is
/// nothing to pick, so it falls back to the existing "who reacted" sheet.
/// [source] is the account whose timeline the note belongs to and the default
/// selection. [title] labels the picker (e.g. "React with account" vs "Like
/// with account").
Future<void> reactWithAccountOrShowUsers(
  BuildContext context,
  WidgetRef ref, {
  required Account source,
  required Note note,
  required String emoji,
  required Offset at,
  String? title,
}) async {
  if (note.id.isEmpty) return;
  final candidates = ref
      .read(accountsNotifierProvider)
      .where((acct) => !note.localOnly || acct.host == source.host)
      .toList();
  if (candidates.length < 2) {
    unawaited(HapticFeedback.lightImpact());
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => ReactionUsersSheet(
        account: source,
        noteId: note.id,
        initialReaction: emoji,
      ),
      clipBehavior: Clip.antiAlias,
      isScrollControlled: true,
    );
    return;
  }
  final target = await selectAccountAt(
    context,
    at: at,
    current: source,
    candidates: candidates,
    title: title ?? t.aria.reactWithAccount,
  );
  if (target == null || !context.mounted) return;
  await _react(
    context,
    ref,
    source: source,
    target: target,
    note: note,
    emoji: emoji,
  );
}

/// Reacts to [note] with [emoji] as [target], resolving the note id on
/// [target]'s server when it differs from [source]. Shared by the fixed-emoji
/// path above and the add-reaction button's pick-then-react path.
Future<void> reactAs(
  BuildContext context,
  WidgetRef ref, {
  required Account source,
  required Account target,
  required Note note,
  required String emoji,
}) => _react(
  context,
  ref,
  source: source,
  target: target,
  note: note,
  emoji: emoji,
);

Future<void> _react(
  BuildContext context,
  WidgetRef ref, {
  required Account source,
  required Account target,
  required Note note,
  required String emoji,
}) async {
  unawaited(HapticFeedback.lightImpact());
  ref
      .read(misskeySfxNotifierProvider(OperationType.reaction).notifier)
      .play()
      .ignore();
  final ok = await futureWithDialog(context, () async {
    final noteId = await resolveNoteIdFor(
      ref,
      source: source,
      target: target,
      note: note,
    );
    await ref.read(notesNotifierProvider(target).notifier).react(noteId, emoji);
    return true;
  }(), overlay: false);
  if (ok != true || target == source) return;
  // Reacting as a different account creates the reaction on that account's
  // server; it won't show on the note rendered for [source] until it federates
  // back. Optimistically add it to the displayed note so the effect is visible
  // immediately. Not marked as [source]'s own reaction — it isn't.
  final current = ref.read(noteNotifierProvider(source, note.id));
  if (current != null) {
    ref
        .read(notesNotifierProvider(source).notifier)
        .add(
          current.copyWith(
            reactionCount: (current.reactionCount ?? 0) + 1,
            reactions: {
              ...current.reactions,
              emoji: (current.reactions[emoji] ?? 0) + 1,
            },
          ),
        );
  }
}
