import 'package:flutter/material.dart';

import 'settings_paper.dart';

/// 手机端沿用桌面白底和陶土色，控制尺寸按触屏调整。
final ThemeData mobilePaperTheme = SettingsPaper.theme.copyWith(
  appBarTheme: const AppBarThemeData(
    backgroundColor: SettingsPaper.surface,
    foregroundColor: SettingsPaper.ink,
    surfaceTintColor: Colors.transparent,
    scrolledUnderElevation: 0,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: SettingsPaper.ink,
      fontSize: 24,
      fontWeight: FontWeight.w700,
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(0, 50),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 50),
      foregroundColor: SettingsPaper.ink,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      side: const BorderSide(color: SettingsPaper.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  snackBarTheme: SettingsPaper.theme.snackBarTheme.copyWith(
    behavior: SnackBarBehavior.floating,
  ),
);
