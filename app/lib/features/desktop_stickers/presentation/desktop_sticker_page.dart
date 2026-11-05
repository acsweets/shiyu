import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/services.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import '../../../platform/desktop/floating_window_controller.dart';
import '../../../platform/desktop/desktop_placement.dart';
import '../../../platform/desktop/desktop_window_bounds.dart';
import '../../../platform/desktop/desktop_bridge.dart';
import '../../retirement/application/retirement_controller.dart';
import '../application/sticker_group_view.dart';
import '../application/sticker_metric_selection.dart';
import '../application/sticker_settings_host.dart';
import '../application/sticker_settings_state.dart';
import '../application/sticker_windows.dart';
import '../data/sticker_layout.dart';
import '../data/sticker_mode.dart';
import 'countdown_sticker.dart';
import 'settings/sticker_settings.dart';

class DesktopStickerPage extends StatefulWidget {
  const DesktopStickerPage({
    required this.controller,
    required this.window,
    this.layout,
    this.onboarding = false,
    this.startupPack,
    super.key,
  });

  /// 主引擎的业务快照。
  final RetirementController controller;

  /// 托盘、快捷键和主窗控制。
  final FloatingWindowController window;

  /// 可选的测试外观配置。
  final StickerLayout? layout;
  final bool onboarding;
  final String? startupPack;

  @override
  State<DesktopStickerPage> createState() => _DesktopStickerPageState();
}

class _DesktopStickerPageState extends State<DesktopStickerPage>
    with WindowListener, ScreenListener {
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
  bool _boundsPending = false;

  /// 多窗口启动异常时仍保留主窗及设置入口。
  bool _failed = false;
  Set<int> _activeSlots = <int>{};
  DesktopPlacement? _placement;

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
      changeMode: _changeMode,
      window: widget.window,
    );
    _layout.addListener(_layoutChanged);
    widget.controller.addListener(_rebuild);
    _syncTickerVisibility();
    if (widget.window.initialized) {
      desktopPackChannel.setMethodCallHandler(_receivePack);
    }
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    if (!_layout.ready) await _layout.load();
    if (!mounted || !widget.window.initialized) return;
    _syncTickerVisibility();
    windowManager.addListener(this);
    screenRetriever.addListener(this);
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
    widget.window.setClickThrough = _settingsHost.setClickThrough;
    widget.window.closeGroups = _closeGroups;
    try {
      await _loadScreens();
      await _applyMainBounds();
      await WidgetsBinding.instance.endOfFrame;
      await widget.window.applyInitialVisibility();
      if (mounted) await windows.start();
      if (mounted && widget.startupPack != null) {
        await _showPackResult(widget.startupPack);
      }
      if (mounted && widget.onboarding && widget.controller.needsOnboarding) {
        await _settings();
      }
    } catch (_) {
      _reportFailure();
    }
  }

  Future<void> _loadScreens() async {
    try {
      final DesktopPlacement placement = await DesktopPlacement.read();
      if (!mounted) return;
      _placement = placement;
      _windows?.placement = placement;
    } catch (_) {
      // 显示器服务不可用时保留最近的原生位置。
    }
  }

  Future<void> _receivePack(MethodCall call) async {
    if (call.method == 'install') await _showPackResult(call.arguments);
  }

  Future<void> _showPackResult(Object? source) async {
    final String message = await _settingsHost.installSkin(source);
    if (!mounted) return;
    await widget.window.reopen();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void onScreenEvent(String eventName) => unawaited(_restoreScreens());

  Future<void> _restoreScreens() async {
    await _loadScreens();
    if (!mounted) return;
    final DesktopPlacement? placement = _placement;
    if (placement == null) return;
    for (final int group in _selection.activeGroups) {
      if (group == _layout.mainGroup) continue;
      final PlacedWindow result = placement.restore(
        _view(group).initialBounds,
        _layout.anchorOf(group),
      );
      _layout.saveBounds(group, result.bounds, anchor: result.anchor);
      _windows?.applyBounds(group, result.bounds);
    }
    await _applyMainBounds();
  }

  void _reportFailure() {
    if (mounted && !_failed) setState(() => _failed = true);
  }

  bool _windowFailed() => _failed;

  void _rebuild() {
    if (!mounted) return;
    final Set<int> slots = _selection.activeGroups;
    if (!setEquals(slots, _activeSlots)) {
      _activeSlots = slots;
      _windows?.sync();
    }
    _syncTickerVisibility();
    setState(() {});
  }

  StickerMetricSelection get _selection =>
      StickerMetricSelection(_layout, widget.controller);

  void _layoutChanged() {
    _rebuild();
    _windows?.sync();
    unawaited(_syncMainVisibility());
    if (_appliedGroup != _layout.mainGroup) unawaited(_applyMainBounds());
  }

  void _syncTickerVisibility() {
    widget.controller.setVisible(
      widget.window.visible && _selection.hasVisibleMetrics,
    );
  }

  /// 显示开关只作用于主浮窗，设置窗有自己的生命周期。
  Future<void> _syncMainVisibility() async {
    if (!widget.window.initialized) return;
    await widget.window.setMainVisible(_layout.showsGroup(_layout.mainGroup));
  }

  Future<void> _applyMainBounds() async {
    if (!widget.window.initialized) return;
    _boundsPending = true;
    if (_applyingBounds) return;
    _applyingBounds = true;
    _boundsTimer?.cancel();
    try {
      while (_boundsPending && mounted) {
        _boundsPending = false;
        final int group = _layout.mainGroup;
        final Rect desired = _view(group).initialBounds;
        final PlacedWindow? placed = _placement?.restore(
          desired,
          _layout.anchorOf(group),
        );
        await DesktopWindowBounds.write(placed?.bounds ?? desired);
        if (placed != null && mounted) {
          _layout.saveBounds(group, placed.bounds, anchor: placed.anchor);
        }
        _appliedGroup = group;
      }
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
    final Rect bounds = await DesktopWindowBounds.read();
    if (mounted && group == _appliedGroup && !_applyingBounds) {
      final PlacedWindow? placed = _placement?.capture(
        bounds,
        snap: _layout.desktop.snap,
      );
      _layout.saveBounds(
        group,
        placed?.bounds ?? bounds,
        anchor: placed?.anchor,
      );
      if (placed != null && placed.bounds != bounds) {
        await _applyMainBounds();
      }
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
    final Rect current = _view(group).initialBounds;
    final double scale = _layout.anchorOf(group)?.scale ?? 1;
    final Rect bounds = StickerLayout.decodeBounds(<double>[
      current.left,
      current.top,
      (current.width + 120 * step * scale).clamp(
        StickerLayout.minimum.width * scale,
        4096,
      ),
      (current.height + 72 * step * scale).clamp(
        StickerLayout.minimum.height * scale,
        4096,
      ),
    ])!;
    _layout.saveBounds(group, bounds);
    if (group == _layout.mainGroup) {
      unawaited(_applyMainBounds());
    } else {
      _windows?.applyBounds(group, bounds);
    }
  }

  void _changeMode(StickerMode mode) {
    if (mode == _layout.mode) return;
    _layout.setMode(mode);
    for (final int group in _selection.activeGroups) {
      final Rect bounds = _layout.modeBounds(
        group,
        _selection.group(group).length,
      );
      _layout.saveBounds(group, bounds);
      if (group != _layout.mainGroup) _windows?.applyBounds(group, bounds);
    }
    unawaited(_applyMainBounds());
  }

  void _resetBounds() {
    _layout.reset(groups: _selection.activeGroups);
    unawaited(_restoreScreens());
  }

  Future<void> _closeGroups() async {
    await _captureBounds();
    await _windows?.close();
    await _layout.flush();
  }

  @override
  void dispose() {
    _boundsTimer?.cancel();
    if (widget.window.initialized) {
      desktopPackChannel.setMethodCallHandler(null);
    }
    windowManager.removeListener(this);
    screenRetriever.removeListener(this);
    widget.window.closeGroups = null;
    widget.window.openSettings = null;
    widget.window.onGroupVisibility = null;
    widget.window.setClickThrough = null;
    widget.controller.setVisible(false);
    widget.controller.removeListener(_rebuild);
    _layout.removeListener(_layoutChanged);
    final StickerWindows? windows = _windows;
    if (windows != null) unawaited(windows.close());
    if (widget.layout == null) _layout.dispose();
    super.dispose();
  }

  StickerGroupView _view(int group) =>
      StickerGroupView.fromLayout(_layout, widget.controller, group, true);

  @override
  Widget build(BuildContext context) => StickerGroupSurface(
    view: _view(_layout.mainGroup),
    onSettings: _openSettings,
    onToggleMode: _settingsHost.toggleMode,
  );
}
