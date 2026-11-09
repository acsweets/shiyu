import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show AsyncCallback;
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../features/desktop_stickers/data/sticker_layout.dart';
import '../../features/retirement/application/retirement_controller.dart';
import '../../features/retirement/data/holiday_repository.dart';
import 'desktop_bridge.dart';
import 'desktop_options.dart';
import 'desktop_window_bounds.dart';

typedef WindowVisibilityChanged = void Function(bool visible);

/// 托盘保持独立可用。隐藏与全屏抑制分开保存，解除抑制后恢复原状态。
class FloatingWindowController with TrayListener, WindowListener {
  FloatingWindowController(this.onVisibilityChanged, {this.business});

  final WindowVisibilityChanged onVisibilityChanged;
  final RetirementController? business;
  bool initialized = false;
  WindowVisibilityChanged? onGroupVisibility;
  VoidCallback? openSettings;
  AsyncCallback? closeGroups;

  DesktopOptions _options = const DesktopOptions();
  bool _requestedVisible = true;
  bool _mainVisible = true;
  bool _fullscreen = false;
  bool _closing = false;
  bool visibilityShortcutOk = false;
  bool amountShortcutOk = true;
  bool startupSupported = false;
  bool startupEnabled = false;
  Future<void> _visibilityQueue = Future<void>.value();
  ({
    bool visible,
    bool locked,
    bool paused,
    bool hidden,
    HolidayUpdate holiday,
  })?
  _lastMenu;

  bool get visible =>
      _requestedVisible && (!_fullscreen || _options.coverFullscreen);

  Future<void> initialize({
    bool showMain = true,
    DesktopOptions options = const DesktopOptions(),
  }) async {
    _mainVisible = showMain;
    _options = options;
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow();
    await windowManager.setTitle('时余');
    trayManager.addListener(this);
    await trayManager.setIcon(
      Platform.isWindows ? 'assets/brand/tray.ico' : 'assets/brand/tray.png',
    );
    await _refreshMenu();
    visibilityShortcutOk = await desktopFlag('visibilityShortcut', true);
    amountShortcutOk =
        options.amountShortcut.isEmpty ||
        await desktopFlag('amountShortcut', options.amountShortcut);
    await readStartup();
    _fullscreen = Platform.isWindows && await desktopFlag('desktopFullscreen');
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
    await windowManager.setAsFrameless();
    await windowManager.setBackgroundColor(Colors.transparent);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setMinimumSize(StickerLayout.minimum);
    await windowManager.setSize(const Size(280, 172));
    await windowManager.setSkipTaskbar(true);
    await _applyNativeOptions(options);
    initialized = true;
    business?.addListener(_businessChanged);
    await show();
  }

  Future<void> readStartup() async {
    startupSupported = await desktopFlag('startupSupported');
    startupEnabled = startupSupported && await desktopFlag('startupEnabled');
  }

  Future<bool> setStartup(bool enabled) async {
    if (!startupSupported || !await desktopFlag('startupSet', enabled)) {
      return false;
    }
    await readStartup();
    return startupEnabled == enabled;
  }

  Future<bool> applyOptions(
    DesktopOptions value, {
    bool retryShortcut = false,
  }) async {
    final DesktopOptions previous = _options;
    final bool shortcutChanged =
        value.amountShortcut != previous.amountShortcut ||
        (retryShortcut && !amountShortcutOk && value.amountShortcut.isNotEmpty);
    if (shortcutChanged &&
        !await desktopFlag('amountShortcut', value.amountShortcut)) {
      return false;
    }
    try {
      await _applyNativeOptions(value);
    } catch (_) {
      if (shortcutChanged) {
        await desktopFlag('amountShortcut', previous.amountShortcut);
      }
      await _applyNativeOptions(previous);
      return false;
    }
    _options = value;
    if (shortcutChanged) amountShortcutOk = true;
    await _updateVisibility();
    await _refreshMenu();
    return true;
  }

  Future<void> _applyNativeOptions(DesktopOptions value) async {
    await windowManager.setIgnoreMouseEvents(value.clickThrough);
    if (Platform.isMacOS) {
      await windowManager.setVisibleOnAllWorkspaces(
        value.coverFullscreen,
        visibleOnFullScreen: value.coverFullscreen,
      );
    }
  }

  Future<void> show() async {
    _requestedVisible = true;
    await _updateVisibility(focus: true);
    await _refreshMenu();
  }

  Future<void> hide() async {
    _requestedVisible = false;
    await _updateVisibility();
    await _refreshMenu();
  }

  Future<void> toggleVisibility() => _requestedVisible ? hide() : show();

  Future<void> setSystemFullscreen(bool fullscreen) async {
    if (_fullscreen == fullscreen) return;
    _fullscreen = fullscreen;
    await _updateVisibility();
  }

  Future<void> setMainVisible(bool visible) async {
    if (_mainVisible == visible) return;
    _mainVisible = visible;
    await _updateVisibility();
  }

  Future<void> applyInitialVisibility() => _updateVisibility();

  Future<void> reopen() async {
    await show();
    openSettings?.call();
  }

  Future<void> _updateVisibility({bool focus = false}) {
    onVisibilityChanged(visible);
    onGroupVisibility?.call(visible);
    _visibilityQueue = _visibilityQueue.then(
      (void _) => _applyVisibility(focus),
    );
    return _visibilityQueue;
  }

  Future<void> _applyVisibility(bool focus) async {
    if (!initialized || _closing) return;
    try {
      if (visible && _mainVisible) {
        await DesktopWindowBounds.show(
          inactive: !focus || _options.clickThrough,
        );
      } else {
        await windowManager.hide();
      }
    } on Exception {
      // 窗口关闭与显隐请求可能同时到达，后续仍可从托盘重试。
    }
  }

  Future<void> toggleAmount() async {
    final RetirementController? state = business;
    if (state == null) return;
    await state.setAmountHidden(state.settings['hide_amount'] == false);
  }

  void _businessChanged() => unawaited(_refreshMenu());

  Future<void> _refreshMenu() async {
    final bool locked = _options.clickThrough;
    final bool paused = business?.paused == true;
    final bool hidden = business?.settings['hide_amount'] != false;
    final HolidayUpdate holiday = business?.holidayUpdate ?? HolidayUpdate.idle;
    final ({
      bool visible,
      bool locked,
      bool paused,
      bool hidden,
      HolidayUpdate holiday,
    })
    state = (
      visible: _requestedVisible,
      locked: locked,
      paused: paused,
      hidden: hidden,
      holiday: holiday,
    );
    if (_closing || state == _lastMenu) return;
    _lastMenu = state;
    await trayManager.setContextMenu(
      Menu(
        items: <MenuItem>[
          MenuItem(
            key: 'toggle',
            label: _requestedVisible ? '隐藏浮窗 / Hide' : '显示浮窗 / Show',
          ),
          MenuItem(key: 'settings', label: '设置 / Settings'),
          MenuItem.separator(),
          MenuItem(
            key: 'amount',
            label: hidden ? '显示金额 / Show amounts' : '隐藏金额 / Hide amounts',
          ),
          MenuItem(
            key: 'pause',
            label: paused ? '恢复刷新 / Resume' : '暂停刷新 / Pause',
          ),
          MenuItem(
            key: 'lock',
            label: locked ? '解除点击穿透 / Unlock' : '锁定点击穿透 / Lock',
          ),
          MenuItem(key: 'holidays', label: _holidayLabel(holiday)),
          MenuItem.separator(),
          MenuItem(key: 'exit', label: '退出 / Exit'),
        ],
      ),
    );
  }

  String _holidayLabel(HolidayUpdate status) => switch (status) {
    HolidayUpdate.checking => '正在检查节假日… / Checking…',
    HolidayUpdate.updated ||
    HolidayUpdate.latest => '节假日数据已更新 / Holidays up to date',
    HolidayUpdate.failed ||
    HolidayUpdate.rejected => '检查节假日失败，点击重试 / Retry holiday check',
    HolidayUpdate.idle => '检查节假日 / Check holidays',
  };

  Future<bool> Function(bool locked)? setClickThrough;

  @override
  void onWindowClose() => unawaited(hide());

  @override
  void onTrayIconMouseDown() {
    if (Platform.isMacOS) {
      unawaited(trayManager.popUpContextMenu());
    } else {
      unawaited(show());
    }
  }

  @override
  void onTrayIconRightMouseDown() => unawaited(trayManager.popUpContextMenu());

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'toggle':
        unawaited(toggleVisibility());
      case 'settings':
        openSettings?.call();
      case 'amount':
        unawaited(toggleAmount());
      case 'pause':
        business?.setPaused(!(business?.paused ?? false));
      case 'lock':
        unawaited(setClickThrough?.call(!_options.clickThrough));
      case 'holidays':
        unawaited(_checkHolidays());
      case 'exit':
        unawaited(_exit());
    }
  }

  Future<void> _checkHolidays() async {
    await business?.checkHolidayUpdates();
  }

  Future<void> _exit() async {
    await dispose();
    await windowManager.destroy();
  }

  Future<void> dispose() async {
    if (_closing) return;
    _closing = true;
    business?.removeListener(_businessChanged);
    await _visibilityQueue;
    await closeGroups?.call();
    initialized = false;
    await desktopFlag('visibilityShortcut', false);
    await desktopFlag('amountShortcut', '');
    await trayManager.destroy();
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    await windowManager.setPreventClose(false);
  }
}
