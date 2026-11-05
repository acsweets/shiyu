import 'package:flutter/material.dart';

/// 设置窗统一使用白色底面、粗体和少量陶土色强调。
abstract final class SettingsPaper {
  static const Color surface = Colors.white;
  static const Color ink = Color(0xFF332B26);
  static const Color muted = Color(0xFF6D5D52);
  static const Color line = Color(0xFFE6E0DB);
  static const Color accent = Color(0xFF854A39);
  static const Color selection = Color(0xFFF8EEEA);
  static const Color hover = Color(0xFFF7F4F2);

  /// 内容标题与正文的字号分别设置，字重共用这一档。
  static const TextStyle _bold = TextStyle(fontWeight: FontWeight.w700);

  /// 标题和正文共享左右对齐线。
  static const double contentInset = 32;

  static final BorderRadius corners = BorderRadius.circular(9);

  static final ThemeData theme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: surface,
    colorScheme: const ColorScheme.light(
      primary: accent,
      onPrimary: Colors.white,
      secondary: accent,
      secondaryContainer: selection,
      onSecondaryContainer: ink,
      surface: surface,
      surfaceTint: Colors.transparent,
      surfaceContainerLowest: surface,
      surfaceContainerLow: surface,
      surfaceContainer: surface,
      surfaceContainerHigh: surface,
      surfaceContainerHighest: surface,
      onSurface: ink,
      onSurfaceVariant: muted,
      outline: line,
      outlineVariant: line,
    ),
    textTheme: const TextTheme(
      displayLarge: _bold,
      displayMedium: _bold,
      displaySmall: _bold,
      headlineLarge: _bold,
      headlineMedium: _bold,
      headlineSmall: _bold,
      titleLarge: _bold,
      titleMedium: _bold,
      titleSmall: _bold,
      bodyLarge: _bold,
      bodyMedium: _bold,
      bodySmall: _bold,
      labelLarge: _bold,
      labelMedium: _bold,
      labelSmall: _bold,
    ),
    dividerTheme: const DividerThemeData(color: line, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surface,
      contentTextStyle: _bold.copyWith(color: ink, fontSize: 14),
      actionTextColor: accent,
      shape: RoundedRectangleBorder(
        borderRadius: corners,
        side: const BorderSide(color: line),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 38),
        shape: RoundedRectangleBorder(borderRadius: corners),
      ).copyWith(side: WidgetStateProperty.resolveWith(_focusBorder)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style:
          OutlinedButton.styleFrom(
            minimumSize: const Size(0, 38),
            backgroundColor: surface,
            foregroundColor: ink,
            shape: RoundedRectangleBorder(borderRadius: corners),
          ).copyWith(
            side: WidgetStateProperty.resolveWith(_outline),
            overlayColor: WidgetStateProperty.resolveWith(_overlay),
          ),
    ),
    menuButtonTheme: MenuButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll<Size>(Size(0, 38)),
        shape: WidgetStatePropertyAll<OutlinedBorder>(
          RoundedRectangleBorder(borderRadius: corners),
        ),
        overlayColor: WidgetStateProperty.resolveWith(_overlay),
        side: WidgetStateProperty.resolveWith(_focusBorder),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: surface,
      isDense: true,
      border: OutlineInputBorder(borderRadius: corners),
      enabledBorder: OutlineInputBorder(
        borderRadius: corners,
        borderSide: const BorderSide(color: line),
      ),
    ),
  );

  static Color? _overlay(Set<WidgetState> states) {
    if (states.contains(WidgetState.pressed)) return selection;
    if (states.contains(WidgetState.focused) ||
        states.contains(WidgetState.hovered)) {
      return hover;
    }
    return null;
  }

  static BorderSide _focusBorder(Set<WidgetState> states) =>
      states.contains(WidgetState.focused)
      ? const BorderSide(color: accent, width: 2)
      : BorderSide.none;

  static BorderSide _outline(Set<WidgetState> states) =>
      states.contains(WidgetState.focused)
      ? const BorderSide(color: accent, width: 2)
      : const BorderSide(color: line);
}
