import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:misskey_dart/misskey_dart.dart' hide Clip;

import '../../model/account.dart';
import '../../provider/api/meta_notifier_provider.dart';
import '../../provider/proxied_image_url_provider.dart';
import '../../provider/server_url_notifier_provider.dart';
import '../../util/safe_parse_color.dart';
import 'image_widget.dart';

/// A compact instance (server) badge: a small solid pill with the instance's
/// favicon and name, sized to its content and clamped when the name is long.
class InstanceTickerWidget extends ConsumerWidget {
  const InstanceTickerWidget({
    super.key,
    required this.account,
    this.instance,
    this.host,
  });

  final Account account;
  final UserInstanceInfo? instance;
  final String? host;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = ref.watch(metaNotifierProvider(account.host)).value;
    final color =
        safeParseColor(
          instance != null ? instance?.themeColor : meta?.themeColor,
        ) ??
        const Color(0xff777777);
    final faviconUrl = instance?.faviconUrl;
    final proxiedUrl =
        instance != null && faviconUrl != null && account.host.isNotEmpty
        ? ref.watch(
            proxiedImageUrlProvider(account.host, faviconUrl, preview: true),
          )
        : faviconUrl;
    final style = DefaultTextStyle.of(context).style;
    final name = instance != null
        ? instance?.name ?? host ?? ''
        : meta?.name ?? account.host;
    final foreground = color.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;

    return Material(
      color: color,
      borderRadius: BorderRadius.circular(6.0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: account.host.isNotEmpty
            ? () => context.push('/$account/servers/${host ?? account.host}')
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (proxiedUrl != null || host == null) ...[
                ImageWidget(
                  height: style.fontSize! + 2.0,
                  url:
                      (proxiedUrl ??
                              ref
                                  .watch(
                                    serverUrlNotifierProvider(account.host),
                                  )
                                  .replace(pathSegments: ['favicon.ico']))
                          .toString(),
                ),
                const SizedBox(width: 4.0),
              ],
              Flexible(
                child: Text(
                  name,
                  style: style.copyWith(color: foreground, height: 1.0),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
