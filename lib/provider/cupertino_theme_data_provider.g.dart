// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cupertino_theme_data_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A [CupertinoThemeData] derived from the same [MisskeyColors] and font
/// settings that drive [themeData], so Cupertino widgets used on iOS pick up the
/// instance's accent, background and typography. Injected below the
/// [MaterialApp] (see `main.dart`) so `CupertinoTheme.of` resolves app-wide on
/// iOS while the app itself stays a [MaterialApp].

@ProviderFor(cupertinoThemeData)
final cupertinoThemeDataProvider = CupertinoThemeDataFamily._();

/// A [CupertinoThemeData] derived from the same [MisskeyColors] and font
/// settings that drive [themeData], so Cupertino widgets used on iOS pick up the
/// instance's accent, background and typography. Injected below the
/// [MaterialApp] (see `main.dart`) so `CupertinoTheme.of` resolves app-wide on
/// iOS while the app itself stays a [MaterialApp].

final class CupertinoThemeDataProvider
    extends
        $FunctionalProvider<
          CupertinoThemeData,
          CupertinoThemeData,
          CupertinoThemeData
        >
    with $Provider<CupertinoThemeData> {
  /// A [CupertinoThemeData] derived from the same [MisskeyColors] and font
  /// settings that drive [themeData], so Cupertino widgets used on iOS pick up the
  /// instance's accent, background and typography. Injected below the
  /// [MaterialApp] (see `main.dart`) so `CupertinoTheme.of` resolves app-wide on
  /// iOS while the app itself stays a [MaterialApp].
  CupertinoThemeDataProvider._({
    required CupertinoThemeDataFamily super.from,
    required Brightness super.argument,
  }) : super(
         retry: null,
         name: r'cupertinoThemeDataProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cupertinoThemeDataHash();

  @override
  String toString() {
    return r'cupertinoThemeDataProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<CupertinoThemeData> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CupertinoThemeData create(Ref ref) {
    final argument = this.argument as Brightness;
    return cupertinoThemeData(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CupertinoThemeData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CupertinoThemeData>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CupertinoThemeDataProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cupertinoThemeDataHash() =>
    r'fe927fcef686246641c1d832188d0bfaf2e5f03a';

/// A [CupertinoThemeData] derived from the same [MisskeyColors] and font
/// settings that drive [themeData], so Cupertino widgets used on iOS pick up the
/// instance's accent, background and typography. Injected below the
/// [MaterialApp] (see `main.dart`) so `CupertinoTheme.of` resolves app-wide on
/// iOS while the app itself stays a [MaterialApp].

final class CupertinoThemeDataFamily extends $Family
    with $FunctionalFamilyOverride<CupertinoThemeData, Brightness> {
  CupertinoThemeDataFamily._()
    : super(
        retry: null,
        name: r'cupertinoThemeDataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A [CupertinoThemeData] derived from the same [MisskeyColors] and font
  /// settings that drive [themeData], so Cupertino widgets used on iOS pick up the
  /// instance's accent, background and typography. Injected below the
  /// [MaterialApp] (see `main.dart`) so `CupertinoTheme.of` resolves app-wide on
  /// iOS while the app itself stays a [MaterialApp].

  CupertinoThemeDataProvider call(Brightness brightness) =>
      CupertinoThemeDataProvider._(argument: brightness, from: this);

  @override
  String toString() => r'cupertinoThemeDataProvider';
}
