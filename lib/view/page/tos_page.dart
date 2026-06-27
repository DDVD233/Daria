import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constant/max_content_width.dart';
import '../../provider/accounts_notifier_provider.dart';
import '../../provider/tos_accepted_notifier_provider.dart';
import '../../util/subscribe_push_notification.dart';

/// First-login gate showing the dvd.chat Terms of Service and Privacy Policy.
/// The user must Agree to continue; Disagree exits the app and the page is
/// shown again on the next launch until accepted.
class TosPage extends ConsumerWidget {
  const TosPage({super.key});

  static final _url = WebUri('https://dvd.chat/@dvd/pages/TOS');

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    final router = GoRouter.of(context);
    final accounts = ref.read(accountsNotifierProvider);
    await ref.read(tosAcceptedNotifierProvider.notifier).accept();
    // Offer one-tap push registration for the signed-in account(s), but only
    // when the server supports the token-callable endpoint — otherwise skip
    // silently rather than surfacing the AiScript flow.
    for (final account in accounts) {
      if (account.isGuest) continue;
      try {
        if (!await isPushRegisterTokenSupported(ref, account)) continue;
        if (!context.mounted) break;
        await subscribePushNotification(
          ref,
          account,
          allowAiScriptFallback: false,
        );
      } on Exception catch (_) {
        // Best effort; never block entering the app on push setup.
      }
      if (!context.mounted) break;
    }
    router.go('/home');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ToS and Privacy Policy'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: InAppWebView(
                initialUrlRequest: URLRequest(url: _url),
                initialSettings: InAppWebViewSettings(
                  transparentBackground: true,
                ),
              ),
            ),
            const Divider(height: 1.0),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Center(
                child: SizedBox(
                  width: maxContentWidth,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => SystemNavigator.pop(),
                          child: const Text('Disagree'),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => unawaited(_accept(context, ref)),
                          child: const Text('Agree'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
