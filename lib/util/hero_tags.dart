import '../model/account.dart';

/// Stable [Hero] tags so list avatars/thumbnails animate into their detail
/// view. Kept in one place to guarantee the source and destination tags match.

/// Tag for a user's avatar within [account]'s context.
String userAvatarHeroTag(Account account, String userId) =>
    'avatar:$account:$userId';

/// Tag for a note's attached file (image/video) thumbnail.
String noteFileHeroTag(String noteId, String fileId) =>
    'note-file:$noteId:$fileId';
