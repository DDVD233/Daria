import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart' show closeInAppWebView;

import '../../i18n/strings.g.dart';
import '../../provider/miauth_notifier_provider.dart';
import '../../util/copy_text.dart';
import '../../util/show_toast.dart';
import '../dialog/message_dialog.dart';

class AuthenticatePage extends HookConsumerWidget {
  const AuthenticatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final miAuthState = ref.watch(miAuthNotifierProvider);
    final completed = useRef(false);
    final checking = useRef(false);

    // Completes the login once the user has authorized in the browser: logs in
    // and navigates home. This runs automatically (polled and on resume) so
    // closing the web page lands on the timeline instead of leaving the user on
    // this page. [showError] is set only for the manual fallback action so the
    // background polling stays quiet.
    Future<void> complete({bool showError = false}) async {
      if (completed.value || checking.value) return;
      checking.value = true;
      try {
        final result = await ref.read(miAuthNotifierProvider.notifier).check();
        if (!context.mounted) return;
        if (result.success) {
          completed.value = true;
          // Dismiss the in-app browser the auth page was opened in (iOS), so the
          // user doesn't have to close it by hand. A no-op when none is open.
          unawaited(closeInAppWebView());
          if (result.added case final added?) {
            showToast(
              context: context,
              message: added ? t.aria.accountAdded : t.aria.accessTokenUpdated,
            );
          }
          context.go('/home');
        } else if (showError) {
          await showMessageDialog(context, t.misskey.loginFailed);
        }
      } finally {
        checking.value = false;
      }
    }

    useEffect(() {
      final timer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => unawaited(complete()),
      );
      return timer.cancel;
    }, []);
    useOnAppLifecycleStateChange((_, current) {
      if (current == AppLifecycleState.resumed) {
        unawaited(complete());
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(t.misskey.authenticationRequiredToContinue),
        actions: [
          PopupMenuButton<void>(
            itemBuilder: (context) => [
              if (miAuthState != null)
                PopupMenuItem(
                  onTap: () =>
                      copyToClipboard(context, miAuthState.url.toString()),
                  child: Text(t.misskey.copyLink),
                ),
              PopupMenuItem(
                onTap: () => unawaited(complete(showError: true)),
                child: Text(t.aria.authenticated),
              ),
            ],
          ),
        ],
      ),
      body: const Center(child: CircularProgressIndicator.adaptive()),
    );
  }
}
