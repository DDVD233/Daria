import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constant/builtin_misskey_colors.g.dart';
import '../model/misskey_colors.dart';
import 'dynamic_color_provider.dart';
import 'general_settings_notifier_provider.dart';
import 'installed_misskey_colors_provider.dart';

part 'misskey_colors_provider.g.dart';

/// Factory-default light/dark builtin theme ids — Mi Sushi Light / Mi Persimmon
/// Dark (mirror the `@Default` values in `GeneralSettings`). On Android a fresh
/// install has one of these stored, so they're treated as a request for
/// wallpaper-based Dynamic Color. The pre-1.5.6 defaults are included too so
/// users updating from those keep the wallpaper colours.
const _defaultLightThemeIds = {
  '213273e5-7d20-d5f0-6e36-1b6a4f67115c', // Mi Sushi Light (current default)
  'a58a0abb-ff8c-476a-8dec-0ad7837e7e96', // Mi Rainy Light (pre-1.5.6 default)
};
const _defaultDarkThemeIds = {
  'c503d768-7c70-4db2-a4e6-08264304bc8d', // Mi Persimmon Dark (current default)
  '66e7e5a9-cd43-42cd-837d-12f47841fa34', // Mi Ice Dark (pre-1.5.6 default)
};

@riverpod
MisskeyColors misskeyColors(Ref ref, Brightness brightness) {
  // Use whichever light/dark theme is selected as-is (wallpaper-based Material
  // You on Android, the picked/default Misskey theme elsewhere) — no brand
  // override.
  final colors = _resolveMisskeyColors(ref, brightness);
  // Use a near-black foreground in light mode so post text and usernames read
  // as black rather than washed-out grey.
  return brightness == Brightness.light
      ? colors.copyWith(fg: const Color(0xFF1A1A1A))
      : colors;
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
  // On Android, a fresh install (theme still at a factory default) defaults to
  // wallpaper-based Dynamic Color.
  final resolvedThemeId =
      defaultTargetPlatform == TargetPlatform.android &&
          (brightness == Brightness.light
                  ? _defaultLightThemeIds
                  : _defaultDarkThemeIds)
              .contains(themeId)
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
