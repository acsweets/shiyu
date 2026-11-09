import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// 设置主浮窗和拆分浮窗的透明背景与无按钮边框。
Future<void> configureStickerWindowChrome() async {
  if (Platform.isMacOS) {
    // macOS 的 setAsFrameless 会将原生窗口设为不透明。
    await windowManager.setTitleBarStyle(
      TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    await windowManager.setHasShadow(false);
  } else {
    await windowManager.setAsFrameless();
  }
  await windowManager.setBackgroundColor(Colors.transparent);
}
