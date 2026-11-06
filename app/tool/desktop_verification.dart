import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:shiyu/features/desktop_stickers/data/sticker_layout.dart';
import 'package:shiyu/features/retirement/data/settings_store.dart';
import 'package:shiyu/main.dart';
import 'package:window_manager/window_manager.dart';

/// 验收入口使用独立目录和合成数据，避免覆盖正常安装的配置。
Future<void> main() async {
  final String? path = Platform.environment['SHIYU_VERIFY_DIRECTORY'];
  if ((!Platform.isWindows && !Platform.isMacOS) || path == null) {
    throw StateError('缺少桌面验证目录');
  }
  final Directory profile = Directory(path);
  if (!await File('${profile.path}/.shiyu-verification').exists()) {
    throw StateError('验证目录缺少标记文件');
  }
  await runShiyu(
    storage: LocalSettingsStore(profile),
    desktopLayout: StickerLayout(
      directory: Directory('${profile.path}/appearance'),
    ),
    checkHolidays: false,
    showOnboarding: false,
  );
  await WidgetsBinding.instance.endOfFrame;
  for (int attempt = 0; attempt < 100; attempt++) {
    if (await windowManager.isVisible()) {
      await File('${profile.path}/ready')
          .writeAsString(DateTime.now().toUtc().toIso8601String(), flush: true);
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  throw StateError('桌面窗口未显示');
}
