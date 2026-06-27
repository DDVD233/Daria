import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinycolor2/tinycolor2.dart';

import '../constant/builtin_misskey_colors.g.dart';
import '../model/misskey_colors.dart';
import 'dynamic_color_provider.dart';
import 'general_settings_notifier_provider.dart';
import 'installed_misskey_colors_provider.dart';

part 'misskey_colors_provider.g.dart';

/// dvd.chat brand accent. Applied on top of whichever light/dark theme is
/// active so the primary colour is always the instance orange.
const _brandAccent = Color(0xFFE36649);

/// Factory-default light/dark builtin theme ids (mirror the `@Default` values
/// in `GeneralSettings`). On Android a fresh install still has one of these
/// stored, so they are treated as a request for wallpaper-based Dynamic Color.
const _defaultLightThemeId = 'a58a0abb-ff8c-476a-8dec-0ad7837e7e96';
const _defaultDarkThemeId = '66e7e5a9-cd43-42cd-837d-12f47841fa34';

@riverpod
MisskeyColors misskeyColors(Ref ref, Brightness brightness) {
  final resolved = _resolveMisskeyColors(ref, brightness);
  // On Android, honour the selected theme as-is so wallpaper-based Material You
  // (and any other picked theme) drives the accent colour. The dvd.chat brand
  // orange is only forced on the other platforms.
  final colors = defaultTargetPlatform == TargetPlatform.android
      ? resolved
      : _applyBrandAccent(resolved);
  // Use a near-black foreground in light mode so post text and usernames read
  // as black rather than washed-out grey.
  return brightness == Brightness.light
      ? colors.copyWith(fg: const Color(0xFF1A1A1A))
      : colors;
}

/// Overrides the accent and every accent-derived colour with [_brandAccent],
/// using the same derivations as `compileTheme` so gradients/shades stay
/// consistent, while keeping the selected theme's background/foreground.
MisskeyColors _applyBrandAccent(MisskeyColors colors) {
  return colors.copyWith(
    accent: _brandAccent,
    accentDarken: _brandAccent.darken(),
    accentLighten: _brandAccent.lighten(),
    accentedBg: _brandAccent.withValues(alpha: 0.15),
    buttonGradateA: _brandAccent,
    buttonGradateB: _brandAccent.spin(20),
    mention: _brandAccent,
    mentionMe: _brandAccent,
    driveFolderBg: _brandAccent.withValues(alpha: 0.3),
  );
}

MisskeyColors _resolveMisskeyColors(Ref ref, Brightness brightness) {
  final themeId = ref.watch(
    generalSettingsNotifierProvider.select(
      (settings) => switch (brightness) {
        Brightness.light => settings.lightThemeId,
        Brightness.dark => settings.darkThemeId,
      },
    ),
  );
  // On Android, a fresh install (theme still at the factory default) defaults
  // to wallpaper-based Dynamic Color.
  final resolvedThemeId =
      defaultTargetPlatform == TargetPlatform.android &&
          themeId ==
              (brightness == Brightness.light
                  ? _defaultLightThemeId
                  : _defaultDarkThemeId)
      ? (brightness == Brightness.light
            ? lightDynamicColorThemeId
            : darkDynamicColorThemeId)
      : themeId;
  if (resolvedThemeId
      case lightDynamicColorThemeId || darkDynamicColorThemeId) {
    final colors = ref.watch(dynamicColorProvider(brightness));
    if (colors != null) {
      return colors;
    }
  }
  final colors = builtinMisskeyColors.firstWhereOrNull(
    (colors) => colors.id == resolvedThemeId,
  );
  if (colors != null) {
    return colors;
  }
  final installedMisskeyColors = ref.watch(installedMisskeyColorsProvider);
  return installedMisskeyColors.firstWhereOrNull(
        (colors) => colors.id == resolvedThemeId,
      ) ??
      builtinMisskeyColors.firstWhere(
        (colors) => switch (brightness) {
          Brightness.light => !colors.isDark,
          Brightness.dark => colors.isDark,
        },
      );
}
