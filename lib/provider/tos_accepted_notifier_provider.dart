import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'shared_preferences_provider.dart';

part 'tos_accepted_notifier_provider.g.dart';

/// Whether the user has accepted the dvd.chat Terms of Service and Privacy
/// Policy. Shown once on first login; persisted so it is not shown again.
@Riverpod(keepAlive: true)
class TosAcceptedNotifier extends _$TosAcceptedNotifier {
  @override
  bool build() {
    return ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;
  }

  static const _key = 'tosAccepted';

  Future<void> accept() async {
    await ref.read(sharedPreferencesProvider).setBool(_key, true);
    state = true;
  }
}
