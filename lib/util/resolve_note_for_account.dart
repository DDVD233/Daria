import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:misskey_dart/misskey_dart.dart';

import '../model/account.dart';
import '../provider/api/misskey_provider.dart';
import '../provider/notes_notifier_provider.dart';
import '../provider/server_url_notifier_provider.dart';

/// Resolves [note] to the id it has on [target]'s server, so it can be renoted
/// or reacted to from an account other than the one its timeline belongs to.
///
/// - Same server as [source]: the id is already valid, returned as-is.
/// - [target] is on the note's origin server: use the id from the note's remote
///   URL directly (no round-trip).
/// - Otherwise: resolve the note's canonical URI via `ap/show` on [target] and
///   warm [target]'s note cache with the returned object.
///
/// Mirrors the cross-account note handling in `note_sheet.dart`. Throws when the
/// note cannot be resolved (e.g. a stricter remote server); callers should wrap
/// the action in `futureWithDialog` to surface the error.
Future<String> resolveNoteIdFor(
  WidgetRef ref, {
  required Account source,
  required Account target,
  required Note note,
}) async {
  if (target.host == source.host) {
    return note.id;
  }
  final remoteUrl = note.url ?? note.uri;
  final remoteNoteId = remoteUrl?.pathSegments.lastOrNull;
  if (target.host == note.user.host && remoteNoteId != null) {
    return remoteNoteId;
  }
  final localUrl = ref
      .read(serverUrlNotifierProvider(source.host))
      .replace(pathSegments: ['notes', note.id]);
  final response = await ref
      .read(misskeyProvider(target))
      .ap
      .show(ApShowRequest(uri: (remoteUrl ?? localUrl).toString()));
  if (response.type != 'Note') {
    throw Exception('Could not resolve note on ${target.host}');
  }
  try {
    ref
        .read(notesNotifierProvider(target).notifier)
        .add(Note.fromJson(response.object));
  } catch (_) {}
  return response.object['id'] as String;
}
