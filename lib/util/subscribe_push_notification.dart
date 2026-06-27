import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:misskey_dart/misskey_dart.dart';
import 'package:unifiedpush/unifiedpush.dart';
import 'package:unifiedpush_ui/unifiedpush_ui.dart';
import 'package:webpush_encryption/webpush_encryption.dart';

import '../constant/web_push_proxy_url.dart';
import '../i18n/strings.g.dart';
import '../model/account.dart';
import '../provider/api/i_notifier_provider.dart';
import '../provider/api/meta_notifier_provider.dart';
import '../provider/apns_push_connector_provider.dart';
import '../provider/dio_provider.dart';
import '../provider/push_subscription_notifier_provider.dart';
import '../provider/server_url_notifier_provider.dart';
import '../provider/token_provider.dart';
import '../provider/unified_push_endpoint_notifier_provider.dart';
import '../provider/user_ids_notifier_provider.dart';
import '../view/dialog/message_dialog.dart';
import '../view/dialog/sw_register_dialog.dart';
import 'future_with_dialog.dart';

/// Subscribes [account] to push notifications.
///
/// Registration is attempted first against the token-callable
/// `sw/register-token` endpoint, which lets the app subscribe with its own
/// access token (one tap, no web session). Stock Misskey/Sharkey only exposes
/// the `secure` `sw/register`, which an access token may not call; for those
/// servers, when [allowAiScriptFallback] is true, the legacy AiScript
/// [SwRegisterDialog] is shown instead.
///
/// When [allowAiScriptFallback] is false (e.g. the automatic post-login
/// subscription) any failure — including a missing token endpoint or a denied
/// permission — resolves silently without surfacing a dialog.
///
/// Returns whether the account ended up subscribed.
Future<bool> subscribePushNotification(
  WidgetRef ref,
  Account account, {
  bool allowAiScriptFallback = true,
}) async {
  if (ref.read(pushSubscriptionNotifierProvider(account)) != null) {
    return true;
  }

  final i = await ref.read(iNotifierProvider(account).future);
  if (i == null || !ref.context.mounted) return false;
  await ref.read(userIdsNotifierProvider.notifier).add(account, i.id);
  if (!ref.context.mounted) return false;

  final String endpoint;
  ({String auth, String publicKey})? publicKeySet;

  // Request permissions and get the endpoint and the token.
  if (defaultTargetPlatform == TargetPlatform.android) {
    final result = await futureWithDialog(
      ref.context,
      FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission(),
    );
    if (!ref.context.mounted) return false;
    if (!(result ?? false)) {
      if (allowAiScriptFallback) {
        await showMessageDialog(ref.context, t.misskey.permissionDeniedError);
      }
      return false;
    }

    final meta = await futureWithDialog(
      ref.context,
      ref.read(metaNotifierProvider(account.host).future),
    );
    if (meta == null) return false;

    if (!ref.context.mounted) return false;
    final instances = [account.toString()];
    await UnifiedPushUi(
      context: ref.context,
      instances: instances,
      unifiedPushFunctions: _UnifiedPushFunctions(vapid: meta.swPublickey),
      showNoDistribDialog: true,
      onNoDistribDialogDismissed: () {},
    ).registerAppWithDialog();
    if (!ref.context.mounted) return false;
    final completer = Completer<PushEndpoint>();
    final sub = ref.listenManual(
      unifiedPushEndpointNotifierProvider(account.toString()),
      (_, endpoint) => endpoint != null ? completer.complete(endpoint) : null,
      fireImmediately: true,
    );
    final unifiedPushEndpoint = await futureWithDialog(
      ref.context,
      completer.future.timeout(const Duration(seconds: 10)),
    );
    sub.close();
    if (unifiedPushEndpoint == null) return false;
    endpoint = unifiedPushEndpoint.url;
    if (unifiedPushEndpoint.pubKeySet case final pubKeySet?) {
      publicKeySet = (auth: pubKeySet.auth, publicKey: pubKeySet.pubKey);
    }
  } else {
    final connector = ref.read(apnsPushConnectorProvider);
    final result = await futureWithDialog(
      ref.context,
      connector.requestNotificationPermissions(),
    );
    if (!ref.context.mounted) return false;
    if (!(result ?? false)) {
      if (allowAiScriptFallback) {
        await showMessageDialog(ref.context, t.misskey.permissionDeniedError);
      }
      return false;
    }

    final completer = Completer<String>();

    void callback() {
      if (connector.token.value case final token? when !completer.isCompleted) {
        completer.complete(token);
      }
    }

    callback();
    connector.token.addListener(callback);
    final apnsToken = await futureWithDialog(
      ref.context,
      completer.future.timeout(const Duration(seconds: 10)),
    );
    connector.token.removeListener(callback);
    if (apnsToken == null) return false;
    endpoint = '$webPushProxyUrl/apns/$account/$apnsToken';
  }

  WebPushKeySet? keySet;
  final SwRegisterRequest request;
  if (publicKeySet case (:final auth, :final publicKey)) {
    request = SwRegisterRequest(
      endpoint: endpoint,
      auth: auth,
      publickey: publicKey,
    );
  } else {
    keySet = await WebPushKeySet.newKeyPair();
    request = SwRegisterRequest(
      endpoint: endpoint,
      auth: keySet.publicKey.auth,
      publickey: keySet.publicKey.p256dh,
    );
  }
  if (!ref.context.mounted) return false;

  // Register the endpoint and keys with the server. Prefer the token-callable
  // endpoint; fall back to the AiScript dialog only when allowed.
  var response = await _registerWithToken(ref, account, request);
  if (response == null && allowAiScriptFallback && ref.context.mounted) {
    response = await showDialog<SwRegisterResponse>(
      context: ref.context,
      builder: (context) =>
          SwRegisterDialog(account: account, request: request),
    );
  }

  if (!ref.context.mounted || response == null) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await UnifiedPush.unregister(account.toString());
      ref
          .read(
            unifiedPushEndpointNotifierProvider(account.toString()).notifier,
          )
          .remove();
    }
    return false;
  }

  // Subscribe and save the endpoint.
  await futureWithDialog(
    ref.context,
    ref
        .read(pushSubscriptionNotifierProvider(account).notifier)
        .subscribe(keySet: keySet, response: response),
  );

  if (defaultTargetPlatform == TargetPlatform.android) {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await flutterLocalNotificationsPlugin?.createNotificationChannelGroup(
      AndroidNotificationChannelGroup(account.toString(), account.toString()),
    );
  }
  return true;
}

/// Whether [account]'s server exposes the token-callable `sw/register-token`
/// endpoint, i.e. whether one-tap push registration (without the AiScript
/// fallback) is possible.
Future<bool> isPushRegisterTokenSupported(
  WidgetRef ref,
  Account account,
) async {
  final token = ref.read(tokenProvider(account));
  if (token == null) return false;
  try {
    // The required push params are omitted on purpose: a server that has the
    // endpoint answers with a param error (non-404), while a server without it
    // answers `NO_SUCH_ENDPOINT` (404). No subscription is created either way.
    await ref
        .read(dioProvider)
        .postUri<Map<String, dynamic>>(
          _registerTokenUri(ref, account),
          data: <String, dynamic>{'i': token},
          options: Options(contentType: Headers.jsonContentType),
        );
    return true;
  } on DioException catch (e) {
    return e.response != null && e.response!.statusCode != 404;
  } on Exception catch (_) {
    return false;
  }
}

/// Registers via the token-callable `sw/register-token` endpoint, returning the
/// parsed response, or null when the endpoint is unavailable or the call fails.
Future<SwRegisterResponse?> _registerWithToken(
  WidgetRef ref,
  Account account,
  SwRegisterRequest request,
) async {
  final token = ref.read(tokenProvider(account));
  if (token == null) return null;
  try {
    final response = await ref
        .read(dioProvider)
        .postUri<Map<String, dynamic>>(
          _registerTokenUri(ref, account),
          data: <String, dynamic>{'i': token, ...request.toJson()}
            ..removeWhere((_, value) => value == null),
          options: Options(contentType: Headers.jsonContentType),
        );
    final data = response.data;
    return data == null ? null : SwRegisterResponse.fromJson(data);
  } catch (_) {
    return null;
  }
}

Uri _registerTokenUri(WidgetRef ref, Account account) {
  final serverUrl = ref.read(serverUrlNotifierProvider(account.host));
  return serverUrl.replace(
    pathSegments: [
      ...serverUrl.pathSegments.where((segment) => segment.isNotEmpty),
      'api',
      'sw',
      'register-token',
    ],
  );
}

class _UnifiedPushFunctions implements UnifiedPushFunctions {
  const _UnifiedPushFunctions({this.vapid});

  final String? vapid;

  @override
  Future<String?> getDistributor() {
    return UnifiedPush.getDistributor();
  }

  @override
  Future<List<String>> getDistributors() {
    return UnifiedPush.getDistributors();
  }

  @override
  Future<void> registerApp(String instance) {
    return UnifiedPush.register(instance: instance, vapid: vapid);
  }

  @override
  Future<void> saveDistributor(String distributor) {
    return UnifiedPush.saveDistributor(distributor);
  }
}
