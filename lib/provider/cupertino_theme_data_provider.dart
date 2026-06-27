import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'general_settings_notifier_provider.dart';
import 'misskey_colors_provider.dart';

part 'cupertino_theme_data_provider.g.dart';

/// A [CupertinoThemeData] derived from the same [MisskeyColors] and font
/// settings that drive [themeData], so Cupertino widgets used on iOS pick up the
/// instance's accent, background and typography. Injected below the
/// [MaterialApp] (see `main.dart`) so `CupertinoTheme.of` resolves app-wide on
/// iOS while the app itself stays a [MaterialApp].
@riverpod
CupertinoThemeData cupertinoThemeData(Ref ref, Brightness brightness) {
  final colors = ref.watch(misskeyColorsProvider(brightness));
  final (fontSize, fontFamily, height) = ref.watch(
    generalSettingsNotifierProvider.select(
      (settings) =>
          (settings.fontSize, settings.fontFamily, settings.lineHeight),
    ),
  );

  TextStyle base = const TextStyle();
  if (fontFamily != null) {
    try {
      base = GoogleFonts.getFont(fontFamily);
    } catch (_) {
      base = TextStyle(fontFamily: fontFamily);
    }
  }

  return CupertinoThemeData(
    brightness: brightness,
    primaryColor: colors.accent,
    primaryContrastingColor: colors.fgOnAccent,
    scaffoldBackgroundColor: colors.bg,
    // Translucent so [CupertinoNavigationBar]/[CupertinoTabBar] render their
    // native backdrop blur instead of an opaque bar.
    barBackgroundColor: colors.panel.withValues(alpha: 0.8),
    applyThemeToAll: true,
    textTheme: CupertinoTextThemeData(
      primaryColor: colors.accent,
      textStyle: base.copyWith(
        color: colors.fg,
        fontSize: fontSize,
        height: height,
      ),
      navTitleTextStyle: base.copyWith(
        color: colors.fg,
        fontSize: fontSize + 2.0,
        fontWeight: FontWeight.w600,
      ),
      navLargeTitleTextStyle: base.copyWith(
        color: colors.fg,
        fontSize: 32.0,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
