import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show AsyncCallback;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../features/desktop_stickers/data/sticker_layout.dart';

typedef WindowVisibilityChanged = void Function(bool visible);

/// 退休倒计时最小浮窗：先创建恢复入口，再隐藏任务栏，避免不可操作状态。
class FloatingWindowController with TrayListener, WindowListener {
  FloatingWindowController(this.onVisibilityChanged);

  /// 隐藏时停止 UI 刷新，重新显示后立即重算。
  final WindowVisibilityChanged onVisibilityChanged;

  /// 原生窗口已完成初始化。
  bool initialized = false;

  /// 同步所有子窗的显隐。
  WindowVisibilityChanged? onGroupVisibility;

  /// 主浮窗隐藏时仍可从托盘进入设置。
  VoidCallback? openSettings;

  /// 快捷键控制的全局显隐，独立于各窗自己的开关。
  bool _visible = true;

  /// 主窗当前可见，设置打开时可以临时覆盖。
  bool _mainVisible = true;

  bool get visible => _visible;

  /// 退出前回收子窗并等待布局保存。
  AsyncCallback? closeGroups;

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
  Future<void> initialize({bool showMain = true}) async {
    _mainVisible = showMain;
    await windowManager.ensureInitialized();
    // 初始化 Windows 任务栏 COM 对象后，才可设置隐藏任务栏。
    await windowManager.waitUntilReadyToShow();
    await windowManager.setTitle('时余');
    trayManager.addListener(this);
    await trayManager.setIcon(
      Platform.isWindows ? 'assets/brand/tray.ico' : 'assets/brand/tray.png',
    );
    await trayManager.setContextMenu(
      Menu(
        items: <MenuItem>[
          MenuItem(key: 'show', label: '显示已开启的浮窗 / Show'),
          MenuItem(key: 'settings', label: '设置 / Settings'),
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
    await windowManager.setMinimumSize(StickerLayout.minimum);
    await windowManager.setSize(const Size(280, 172));
    await windowManager.setSkipTaskbar(true);
    initialized = true;
    await show();
  }

  Future<void> setExpanded(bool expanded) => windowManager.setSize(
    expanded ? const Size(460, 640) : const Size(280, 172),
  );
  Future<void> drag() => windowManager.startDragging();

  /// 全局显示时仍遵循主窗的单独开关。
  Future<void> show() async {
    _visible = true;
    onVisibilityChanged(true);
    onGroupVisibility?.call(true);
    if (_mainVisible) {
      await windowManager.show();
      if (_visible && _mainVisible) await windowManager.focus();
    }
  }

  Future<void> hide() async {
    _visible = false;
    onVisibilityChanged(false);
    onGroupVisibility?.call(false);
    await windowManager.hide();
  }

  /// 更新主窗开关，不影响其他窗口或业务时钟。
  Future<void> setMainVisible(bool visible) async {
    if (_mainVisible == visible) return;
    _mainVisible = visible;
    if (!_visible) return;
    if (visible) {
      await windowManager.show();
    } else {
      await windowManager.hide();
    }
  }

  /// Windows 的首帧由 Runner 显示，主窗关闭时在初始化后隐藏。
  Future<void> applyInitialVisibility() async {
    if (!_visible || !_mainVisible) await windowManager.hide();
  }

  Future<void> _toggle(HotKey key) async {
    if (_visible) {
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
    if (menuItem.key == 'settings') openSettings?.call();
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
    await closeGroups?.call();
    initialized = false;
    await hotKeyManager.unregister(_hotKey);
    await trayManager.destroy();
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    await windowManager.setPreventClose(false);
  }
}
