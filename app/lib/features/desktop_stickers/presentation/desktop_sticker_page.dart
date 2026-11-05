import 'dart:async';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../../platform/desktop/floating_window_controller.dart';
import '../../retirement/application/retirement_controller.dart';
import '../application/sticker_group_view.dart';
import '../application/sticker_settings_host.dart';
import '../application/sticker_settings_state.dart';
import '../application/sticker_windows.dart';
import '../data/sticker_layout.dart';
import 'countdown_sticker.dart';
import 'settings/sticker_settings.dart';

class DesktopStickerPage extends StatefulWidget {
  const DesktopStickerPage({
    required this.controller,
    required this.window,
    this.layout,
    super.key,
  });

  /// 主引擎的业务快照。
  final RetirementController controller;

  /// 托盘、快捷键和主窗控制。
  final FloatingWindowController window;

  /// 可选的测试外观配置。
  final StickerLayout? layout;

  @override
  State<DesktopStickerPage> createState() => _DesktopStickerPageState();
}

class _DesktopStickerPageState extends State<DesktopStickerPage>
    with WindowListener {
  /// 持久化分组。
  late final StickerLayout _layout;

  /// 原生子窗协调器。
  StickerWindows? _windows;

  /// 记录实际应用到主窗的分组。
  int? _appliedGroup;

  /// 在原生操作完成后保存几何信息。
  Timer? _boundsTimer;

  /// 独立设置窗的主引擎入口。
  late final StickerSettingsHost _settingsHost;

  /// 正在恢复窗口尺寸。
  bool _applyingBounds = false;

  /// 多窗口启动异常时仍保留主窗及设置入口。
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _layout = widget.layout ?? StickerLayout();
    _settingsHost = StickerSettingsHost(
      layout: _layout,
      controller: widget.controller,
      resetBounds: _resetBounds,
      resize: _resizeWindow,
      windowFailed: _windowFailed,
    );
    _layout.addListener(_layoutChanged);
    widget.controller.addListener(_rebuild);
    widget.controller.setVisible(true);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    if (!_layout.ready) await _layout.load();
    if (!mounted || !widget.window.initialized) return;
    windowManager.addListener(this);
    final StickerWindows windows = StickerWindows(
      layout: _layout,
      controller: widget.controller,
      settings: _settingsHost,
      reportFailure: _reportFailure,
    );
    _windows = windows;
    windows.setVisible(widget.window.visible);
    widget.window.onGroupVisibility = windows.setVisible;
    widget.window.openSettings = _openSettings;
    widget.window.closeGroups = _closeGroups;
    try {
      await _applyMainBounds();
      await WidgetsBinding.instance.endOfFrame;
      await widget.window.applyInitialVisibility();
      if (mounted) await windows.start();
    } catch (_) {
      _reportFailure();
    }
  }

  void _reportFailure() {
    if (mounted && !_failed) setState(() => _failed = true);
  }

  bool _windowFailed() => _failed;

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _layoutChanged() {
    _rebuild();
    _windows?.sync();
    unawaited(_syncMainVisibility());
    if (_appliedGroup != _layout.mainGroup) unawaited(_applyMainBounds());
  }

  /// 显示开关只作用于主浮窗，设置窗有自己的生命周期。
  Future<void> _syncMainVisibility() async {
    if (!widget.window.initialized) return;
    await widget.window.setMainVisible(_layout.showsGroup(_layout.mainGroup));
  }

  Future<void> _applyMainBounds() async {
    if (!widget.window.initialized || _applyingBounds) return;
    _applyingBounds = true;
    _boundsTimer?.cancel();
    final int group = _layout.mainGroup;
    try {
      await windowManager.setBounds(
        _layout.boundsOf(group) ?? _layout.initialBounds(group),
      );
      _appliedGroup = group;
    } finally {
      _applyingBounds = false;
    }
  }

  void _scheduleBounds() {
    if (_applyingBounds || _appliedGroup == null) return;
    _boundsTimer?.cancel();
    _boundsTimer = Timer(const Duration(milliseconds: 180), _captureBounds);
  }

  Future<void> _captureBounds() async {
    final int? group = _appliedGroup;
    if (!mounted || group == null || _applyingBounds) return;
    final Rect bounds = await windowManager.getBounds();
    if (mounted && group == _appliedGroup && !_applyingBounds) {
      _layout.saveBounds(group, bounds);
    }
  }

  @override
  void onWindowMove() => _scheduleBounds();
  @override
  void onWindowResize() => _scheduleBounds();

  void _openSettings() => unawaited(_settings());

  /// 正常桌面环境只打开独立设置窗。
  Future<void> _settings() async {
    if (!mounted || !_layout.ready) return;
    if (widget.window.initialized) {
      try {
        await _windows?.openSettings();
      } catch (_) {
        _reportFailure();
      }
      return;
    }
    final StickerSettingsSession session = StickerSettingsSession(
      _settingsHost.snapshot(),
      _settingsHost.read,
      _settingsHost.dispatch,
    );
    try {
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) => _settingsDialog(context, session),
      );
    } finally {
      session.dispose();
    }
  }

  Widget _settingsDialog(
    BuildContext context,
    StickerSettingsSession session,
  ) => Dialog(
    insetPadding: const EdgeInsets.all(12),
    clipBehavior: Clip.antiAlias,
    child: SizedBox(
      width: 940,
      height: 660,
      child: StickerSettings(
        session: session,
        onClose: () => Navigator.of(context).pop(),
      ),
    ),
  );

  void _resizeWindow(int group, int step) {
    final Rect current =
        _layout.boundsOf(group) ?? _layout.initialBounds(group);
    final Rect bounds = StickerLayout.decodeBounds(<double>[
      current.left,
      current.top,
      current.width + 120 * step,
      current.height + 72 * step,
    ])!;
    _layout.saveBounds(group, bounds);
    if (group == _layout.mainGroup) {
      unawaited(_applyMainBounds());
    } else {
      _windows?.applyBounds(group, bounds);
    }
  }

  void _resetBounds() {
    _layout.reset();
    unawaited(_applyMainBounds());
    _windows?.resetBounds();
  }

  Future<void> _closeGroups() async {
    await _captureBounds();
    await _windows?.close();
    await _layout.flush();
  }

  @override
  void dispose() {
    _boundsTimer?.cancel();
    windowManager.removeListener(this);
    widget.window.closeGroups = null;
    widget.window.openSettings = null;
    widget.window.onGroupVisibility = null;
    widget.controller.setVisible(false);
    widget.controller.removeListener(_rebuild);
    _layout.removeListener(_layoutChanged);
    final StickerWindows? windows = _windows;
    if (windows != null) unawaited(windows.close());
    if (widget.layout == null) _layout.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StickerGroupSurface(
    view: StickerGroupView.fromLayout(
      _layout,
      widget.controller,
      _layout.mainGroup,
      true,
    ),
    onSettings: _openSettings,
  );
}
