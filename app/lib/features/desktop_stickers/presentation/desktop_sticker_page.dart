import 'dart:async';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../../platform/desktop/floating_window_controller.dart';
import '../../retirement/application/retirement_controller.dart';
import '../application/sticker_group_view.dart';
import '../application/sticker_windows.dart';
import '../data/sticker_layout.dart';
import 'countdown_sticker.dart';
import 'sticker_settings.dart';

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

  /// 设置打开时主窗临时变大，禁止覆盖贴纸尺寸。
  bool _settingsOpen = false;

  /// 正在恢复窗口尺寸。
  bool _applyingBounds = false;

  /// 多窗口启动异常时仍保留主窗及设置入口。
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _layout = widget.layout ?? StickerLayout();
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
      openSettings: _settings,
      reportFailure: _reportFailure,
    );
    _windows = windows;
    widget.window.onGroupVisibility = windows.setVisible;
    widget.window.closeGroups = _closeGroups;
    try {
      await _applyMainBounds();
      if (mounted) await windows.start();
    } catch (_) {
      _reportFailure();
    }
  }

  void _reportFailure() {
    if (mounted && !_failed) setState(() => _failed = true);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _layoutChanged() {
    _rebuild();
    _windows?.sync();
    if (_settingsOpen) return;
    if (_appliedGroup != _layout.mainGroup) unawaited(_applyMainBounds());
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
    if (_settingsOpen || _applyingBounds || _appliedGroup == null) return;
    _boundsTimer?.cancel();
    _boundsTimer = Timer(const Duration(milliseconds: 180), _captureBounds);
  }

  Future<void> _captureBounds() async {
    final int? group = _appliedGroup;
    if (!mounted || group == null || _settingsOpen || _applyingBounds) return;
    final Rect bounds = await windowManager.getBounds();
    if (mounted &&
        group == _appliedGroup &&
        !_settingsOpen &&
        !_applyingBounds) {
      _layout.saveBounds(group, bounds);
    }
  }

  @override
  void onWindowMove() => _scheduleBounds();
  @override
  void onWindowResize() => _scheduleBounds();

  void _openSettings() => unawaited(_settings());
  void _hide() => unawaited(widget.window.hide());

  /// 在主窗中临时打开可读尺寸的设置，关闭后恢复当前分组。
  Future<void> _settings() async {
    if (_settingsOpen || !mounted || !_layout.ready) return;
    await _captureBounds();
    if (!mounted || _settingsOpen) return;
    _settingsOpen = true;
    _boundsTimer?.cancel();
    try {
      if (widget.window.initialized) {
        await widget.window.show();
        await windowManager.setMinimumSize(const Size(420, 420));
        await windowManager.setSize(const Size(470, 650));
        await windowManager.center();
      }
      if (mounted) {
        await showDialog<void>(context: context, builder: _settingsDialog);
      }
    } finally {
      if (widget.window.initialized) {
        await windowManager.setMinimumSize(StickerLayout.minimum);
        await _applyMainBounds();
      }
      _settingsOpen = false;
      _windows?.sync();
    }
  }

  Widget _settingsDialog(BuildContext context) => StickerSettings(
    layout: _layout,
    controller: widget.controller,
    resetWindowBounds: _resetBounds,
    resizeWindow: _resizeWindow,
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
    _windows?.applyBounds(group, bounds);
  }

  void _resetBounds() {
    _layout.reset();
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
  Widget build(BuildContext context) => Stack(
    children: <Widget>[
      StickerGroupSurface(
        view: StickerGroupView.fromLayout(
          _layout,
          widget.controller,
          _layout.mainGroup,
          true,
        ),
        onSettings: _openSettings,
        onHide: _hide,
      ),
      if (_failed || _layout.writeFailed)
        Positioned(
          bottom: 6,
          left: 16,
          child: Text(
            _failed ? '部分浮窗未能打开' : '窗口布局未能保存',
            style: const TextStyle(fontSize: 11, color: Colors.red),
          ),
        ),
    ],
  );
}
