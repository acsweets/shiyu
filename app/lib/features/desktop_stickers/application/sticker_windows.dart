import 'dart:async';
import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../retirement/application/retirement_controller.dart';
import '../data/sticker_layout.dart';
import 'sticker_group_view.dart';
import 'sticker_metric_selection.dart';
import 'sticker_settings_host.dart';

/// 主引擎拥有分组与 Rust 快照，每个外围槽位对应一个系统窗口。
class StickerWindows {
  StickerWindows({
    required this.layout,
    required this.controller,
    required this.settings,
    required this.reportFailure,
  });

  /// 所有分组与外观偏好的唯一写入方。
  final StickerLayout layout;

  /// 主窗口业务快照。
  final RetirementController controller;

  /// 独立设置窗的请求和生命周期。
  final StickerSettingsHost settings;

  /// 窗口初始化失败时交给设置界面提示。
  final VoidCallback reportFailure;

  /// 当前有效的窗口令牌，避免关闭中的子窗写入复用槽位。
  final Map<int, int> _tokens = <int, int>{};

  /// 已创建的子窗口。
  final Map<int, WindowController> _children = <int, WindowController>{};

  /// 注册跨窗请求的主窗口。
  WindowController? _owner;

  /// 窗口打开与关闭按顺序执行。
  Future<void> _pending = Future<void>.value();

  /// 下一子窗的唯一令牌。
  int _sequence = 0;

  /// 全局显隐状态。
  bool _visible = true;

  /// 防止关闭途中继续创建窗口。
  bool _closed = false;

  /// 让设置入口等待主窗口通道完成注册。
  final Completer<void> _ready = Completer<void>();

  Future<void> start() async {
    try {
      final WindowController owner = await WindowController.fromCurrentEngine();
      if (_closed) return;
      await owner.setWindowMethodHandler(_handle);
      if (_closed) {
        await owner.setWindowMethodHandler(null);
        return;
      }
      _owner = owner;
      sync();
    } finally {
      if (!_ready.isCompleted) _ready.complete();
    }
  }

  Future<void> openSettings() async {
    await _ready.future;
    final WindowController? owner = _owner;
    if (!_closed && owner != null) await settings.open(owner);
  }

  /// 根据分组增减子窗口，已有窗口继续读取当前分组。
  void sync() {
    if (_closed || _owner == null) return;
    _pending = _pending.then(_reconcile).catchError(_failed);
  }

  void _failed(Object error, StackTrace stack) {
    debugPrint('贴纸窗口同步失败: $error');
    if (!_closed) reportFailure();
  }

  Set<int> get _wanted =>
      StickerMetricSelection(layout, controller).activeGroups
        ..remove(layout.mainGroup);

  Future<void> _reconcile(void _) async {
    if (_closed) return;
    final Set<int> wanted = _wanted;
    for (final int group in _children.keys.toList()) {
      if (wanted.contains(group)) continue;
      _tokens.remove(group);
      final WindowController child = _children.remove(group)!;
      await _hide(child);
    }
    for (final int group in wanted) {
      if (_closed || _children.containsKey(group)) {
        continue;
      }
      final int token = ++_sequence;
      _tokens[group] = token;
      try {
        _children[group] = await WindowController.create(
          WindowConfiguration(
            arguments: jsonEncode(<String, Object>{
              'owner': _owner!.windowId,
              'group': group,
              'token': token,
            }),
          ),
        );
      } catch (_) {
        _tokens.remove(group);
        rethrow;
      }
    }
  }

  Future<void> _hide(WindowController child) async {
    try {
      await child.hide();
    } on PlatformException {
      // 子窗可能已自行关闭。
    }
  }

  Future<void> _setBounds(WindowController child, Rect bounds) async {
    try {
      await child.invokeMethod<void>(
        'bounds',
        StickerLayout.encodeBounds(bounds),
      );
    } on WindowChannelException {
      // 未就绪的子窗会在启动时读取同一份已保存的位置。
    }
  }

  void applyBounds(int group, Rect bounds) {
    final WindowController? child = _children[group];
    if (child != null) unawaited(_setBounds(child, bounds));
  }

  void resetBounds() {
    for (final int group in _children.keys) {
      applyBounds(group, layout.initialBounds(group));
    }
  }

  void setVisible(bool visible) {
    _visible = visible;
  }

  Future<Object?> _handle(MethodCall call) async {
    if (call.method == 'settings.read' || call.method == 'settings.change') {
      return settings.handle(call);
    }
    final Map<Object?, Object?> request =
        call.arguments as Map<Object?, Object?>;
    final int group = request['group'] as int;
    if (_closed || _tokens[group] != request['token']) {
      return null;
    }
    final bool wanted = _wanted.contains(group);
    if (!wanted && call.method != 'view') return false;
    switch (call.method) {
      case 'view':
        final Rect? bounds = StickerLayout.decodeBounds(request['bounds']);
        if (wanted && bounds != null) layout.saveBounds(group, bounds);
        return StickerGroupView.fromLayout(
          layout,
          controller,
          group,
          _visible && wanted && layout.showsGroup(group),
        ).data;
      case 'hide':
        layout.setGroupVisible(group, false);
        return true;
      case 'toggle_mode':
        settings.toggleMode();
        return true;
      default:
        throw MissingPluginException(call.method);
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    if (!_ready.isCompleted) _ready.complete();
    _tokens.clear();
    await settings.close();
    await _pending;
    for (final WindowController child in _children.values) {
      await _hide(child);
    }
    _children.clear();
    await _owner?.setWindowMethodHandler(null);
  }
}
