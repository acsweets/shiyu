import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

typedef WindowVisibilityChanged = void Function(bool visible);

/// 退休倒计时最小浮窗：先创建恢复入口，再隐藏任务栏，避免不可操作状态。
class FloatingWindowController with TrayListener, WindowListener {
  FloatingWindowController(this.onVisibilityChanged);

  /// 隐藏时停止 UI 刷新，重新显示后立即重算。
  final WindowVisibilityChanged onVisibilityChanged;

  /// 仅释放本程序注册的快捷键。
  final HotKey _hotKey = HotKey(
    key: PhysicalKeyboardKey.keyT,
    modifiers: <HotKeyModifier>[
      Platform.isMacOS ? HotKeyModifier.meta : HotKeyModifier.control,
      HotKeyModifier.shift,
    ],
    scope: HotKeyScope.system,
  );

  /// 注册恢复入口后再启用无边框和任务栏隐藏，保证浮窗始终可找回。
  Future<void> initialize() async {
    await windowManager.ensureInitialized();
    // 初始化 Windows 任务栏 COM 对象后，才可设置隐藏任务栏。
    await windowManager.waitUntilReadyToShow();
    await windowManager.setTitle('时余');
    trayManager.addListener(this);
    await trayManager.setIcon(
      Platform.isWindows
          ? 'assets/diagnostics/icon.ico'
          : 'assets/diagnostics/icon.png',
    );
    await trayManager.setContextMenu(
      Menu(
        items: <MenuItem>[
          MenuItem(key: 'show', label: '显示时余 / Show'),
          MenuItem(key: 'exit', label: '退出 / Exit'),
        ],
      ),
    );
    await hotKeyManager.register(_hotKey, keyDownHandler: _toggle);
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
    await windowManager.setAsFrameless();
    await windowManager.setBackgroundColor(Colors.transparent);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setMinimumSize(const Size(760, 560));
    await setExpanded(false);
    await windowManager.setSkipTaskbar(true);
    await show();
  }

  Future<void> setExpanded(bool expanded) =>
      windowManager.setSize(const Size(760, 560));
  Future<void> drag() => windowManager.startDragging();
  Future<void> show() async {
    await windowManager.show();
    await windowManager.focus();
    onVisibilityChanged(true);
  }

  Future<void> hide() async {
    await windowManager.hide();
    onVisibilityChanged(false);
  }

  Future<void> _toggle(HotKey key) async {
    if (await windowManager.isVisible()) {
      await hide();
    } else {
      await show();
    }
  }

  @override
  void onWindowClose() {
    unawaited(hide());
  }

  @override
  void onTrayIconMouseDown() {
    unawaited(show());
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show') {
      unawaited(show());
    }
    if (menuItem.key == 'exit') {
      unawaited(_exit());
    }
  }

  Future<void> _exit() async {
    await dispose();
    await windowManager.destroy();
  }

  /// 测试和退出时仅清理本窗口注册资源。
  Future<void> dispose() async {
    await hotKeyManager.unregister(_hotKey);
    await trayManager.destroy();
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    await windowManager.setPreventClose(false);
  }
}
