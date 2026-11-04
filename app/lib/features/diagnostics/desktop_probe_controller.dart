import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// M0 专用窗口验证入口，不在正常产品启动流程中创建托盘或快捷键。
class DesktopProbeController with TrayListener {
  /// 穿透恢复定时器，防止验证窗口永久不可操作。
  Timer? _restoreTimer;

  /// 只注销本探测程序注册的快捷键，不操作其他程序的注册项。
  final HotKey _visibilityHotKey = HotKey(
    key: PhysicalKeyboardKey.keyT,
    modifiers: <HotKeyModifier>[
      Platform.isMacOS ? HotKeyModifier.meta : HotKeyModifier.control,
      HotKeyModifier.shift,
    ],
    scope: HotKeyScope.system,
  );

  /// 注册原生窗口、系统入口和可恢复快捷键。
  Future<void> initialize() async {
    await windowManager.ensureInitialized();
    await windowManager.setSize(const Size(640, 560));
    trayManager.addListener(this);
    await trayManager.setIcon(
      Platform.isWindows
          ? 'assets/diagnostics/icon.ico'
          : 'assets/diagnostics/icon.png',
    );
    await trayManager.setContextMenu(
      Menu(
        items: <MenuItem>[
          MenuItem(key: 'restore', label: '恢复窗口 / Restore'),
          MenuItem(key: 'exit', label: '退出探测 / Exit'),
        ],
      ),
    );
    await hotKeyManager.register(
      _visibilityHotKey,
      keyDownHandler: _toggleVisibility,
    );
  }

  /// 开启短暂穿透，并在三秒后自动恢复。
  Future<void> testClickThrough() async {
    _restoreTimer?.cancel();
    _restoreTimer = Timer(const Duration(seconds: 3), restore);
    await windowManager.setIgnoreMouseEvents(true, forward: true);
  }

  /// 从托盘或定时器恢复鼠标交互并重新显示窗口。
  Future<void> restore() async {
    _restoreTimer?.cancel();
    await windowManager.setIgnoreMouseEvents(false);
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> makeFrameless() async {
    await windowManager.setAsFrameless();
    await windowManager.setBackgroundColor(Colors.transparent);
  }

  Future<void> toggleAlwaysOnTop() async {
    await windowManager.setAlwaysOnTop(!await windowManager.isAlwaysOnTop());
  }

  Future<void> _toggleVisibility(HotKey hotKey) async {
    if (await windowManager.isVisible()) {
      await windowManager.hide();
    } else {
      await restore();
    }
  }

  @override
  void onTrayIconMouseDown() {
    unawaited(restore());
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'restore') {
      unawaited(restore());
    } else if (menuItem.key == 'exit') {
      unawaited(_exit());
    }
  }

  /// 释放本次探测注册项后退出。
  Future<void> _exit() async {
    await dispose();
    await windowManager.destroy();
  }

  Future<void> dispose() async {
    _restoreTimer?.cancel();
    await windowManager.setIgnoreMouseEvents(false);
    await hotKeyManager.unregister(_visibilityHotKey);
    trayManager.removeListener(this);
    await trayManager.destroy();
  }
}
