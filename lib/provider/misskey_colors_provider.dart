import 'package:collection/collection.dart';
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

@riverpod
MisskeyColors misskeyColors(Ref ref, Brightness brightness) {
  final colors = _applyBrandAccent(_resolveMisskeyColors(ref, brightness));
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
  if (themeId case lightDynamicColorThemeId || darkDynamicColorThemeId) {
    final colors = ref.watch(dynamicColorProvider(brightness));
    if (colors != null) {
      return colors;
    }
  }
  final colors = builtinMisskeyColors.firstWhereOrNull(
    (colors) => colors.id == themeId,
  );
  if (colors != null) {
    return colors;
  }
  final installedMisskeyColors = ref.watch(installedMisskeyColorsProvider);
  return installedMisskeyColors.firstWhereOrNull(
        (colors) => colors.id == themeId,
      ) ??
      builtinMisskeyColors.firstWhere(
        (colors) => switch (brightness) {
          Brightness.light => !colors.isDark,
          Brightness.dark => colors.isDark,
        },
      );
}
