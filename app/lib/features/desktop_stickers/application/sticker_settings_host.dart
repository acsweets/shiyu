import 'dart:convert';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/services.dart';

import '../../retirement/application/retirement_controller.dart';
import '../data/sticker_layout.dart';
import '../data/sticker_palette.dart';
import 'sticker_group_view.dart';
import 'sticker_settings_state.dart';

typedef StickerWindowResize = void Function(int group, int step);
typedef StickerWindowFailure = bool Function();

/// 主引擎承接设置读写，并维护一个可重复使用的独立原生窗。
class StickerSettingsHost {
  StickerSettingsHost({
    required this.layout,
    required this.controller,
    required this.resetBounds,
    required this.resize,
    required this.windowFailed,
  });

  /// 主引擎的外观配置。
  final StickerLayout layout;

  /// 主引擎的业务设置与快照。
  final RetirementController controller;

  /// 将复位结果同步到原生窗口。
  final VoidCallback resetBounds;

  /// 调整一个原生窗口的大小。
  final StickerWindowResize resize;

  /// 获取实时窗口异常状态。
  final StickerWindowFailure windowFailed;

  /// 设置窗关闭时隐藏，保留导航状态供再次打开。
  WindowController? _window;

  /// 避免快速点击时重复创建。
  bool _opening = false;

  /// 应用退出后停止创建和接受写入。
  bool _closed = false;

  /// 最近一次移动的起点，用于立即撤销。
  ({String id, int origin, int destination})? _lastMove;

  StickerSettingsState snapshot() => StickerSettingsState(<String, Object?>{
    'mainGroup': layout.mainGroup,
    'main': layout.main,
    'preview': layout.preview,
    'palette': layout.palette.name,
    'titleSize': layout.titleSize,
    'groups': layout.activeGroups.toList()..sort(),
    'enabled': layout.enabled.toList(),
    'retirementDate': controller.retirementDate,
    'timeZone': controller.timeZone,
    'editingBlocked': controller.editingBlocked,
    'canRestore': controller.canRestoreBackup,
    'paused': controller.paused,
    'windowFailed': windowFailed(),
    'writeFailed': layout.writeFailed,
    'windows': <Map<Object?, Object?>>[
      for (int group = 0; group < StickerLayout.titles.length; group++)
        StickerGroupView.fromLayout(
          layout,
          controller,
          group,
          layout.showsGroup(group),
        ).data,
    ],
  });

  Future<StickerSettingsState> read() async => snapshot();

  Future<void> open(WindowController owner) async {
    if (_closed || _opening) return;
    _opening = true;
    try {
      final WindowController? existing = _window;
      if (existing == null) {
        final WindowController created = await WindowController.create(
          WindowConfiguration(
            arguments: jsonEncode(<String, Object>{
              'settings': true,
              'owner': owner.windowId,
            }),
          ),
        );
        _window = created;
        if (_closed) await created.hide();
      } else {
        try {
          await existing.invokeMethod<void>('focus');
        } on WindowChannelException {
          if (await _isCurrent(existing)) return;
          _window = null;
        }
      }
    } finally {
      _opening = false;
    }
    if (!_closed && _window == null) await open(owner);
  }

  Future<bool> _isCurrent(WindowController window) async {
    final List<WindowController> windows = await WindowController.getAll();
    return windows.any(
      (WindowController item) => item.windowId == window.windowId,
    );
  }

  Future<void> close() async {
    _closed = true;
    final WindowController? window = _window;
    if (window == null) return;
    try {
      await window.invokeMethod<void>('destroy');
    } on WindowChannelException {
      // 原生设置窗可能仍在启动或已被系统销毁。
    }
  }

  /// 解析设置窗请求，业务校验和持久化统一走现有控制器。
  Future<Object?> handle(MethodCall call) async {
    if (_closed) return null;
    if (call.method == 'settings.read') return snapshot().data;
    final Map<Object?, Object?> request =
        call.arguments as Map<Object?, Object?>;
    final StickerSettingsReply reply = await dispatch(
      StickerSetting.values.byName(request['action'] as String),
      (request['arguments'] as Map<Object?, Object?>).cast<String, Object?>(),
    );
    return reply.data;
  }

  Future<StickerSettingsReply> dispatch(
    StickerSetting action,
    Map<String, Object?> args,
  ) async {
    String? message;
    bool canUndo = false;
    switch (action) {
      case StickerSetting.palette:
        layout.setPalette(StickerPalette.fromId(args['value']));
      case StickerSetting.titleSize:
        layout.setTitleSize(args['value'] as int);
      case StickerSetting.groupVisible:
        layout.setGroupVisible(args['group'] as int, args['value'] as bool);
      case StickerSetting.titleVisible:
        layout.setTitleVisible(args['group'] as int, args['value'] as bool);
      case StickerSetting.move:
        message = _move(args['id'] as String, args['target'] as int?);
        canUndo = message != null;
      case StickerSetting.undoMove:
        message = _undoMove();
      case StickerSetting.resize:
        resize(args['group'] as int, args['step'] as int);
      case StickerSetting.resetBounds:
        resetBounds();
        message = '已恢复窗口位置和大小';
      case StickerSetting.preview:
        layout.setPreview(args['value'] as bool);
      case StickerSetting.main:
        layout.setMain(args['value'] as String);
      case StickerSetting.enabled:
        layout.toggle(args['id'] as String, args['value'] as bool);
      case StickerSetting.retirement:
        final bool saved = await controller.save(
          args['date'] as String?,
          args['zone'] as String,
        );
        message = saved ? '已保存退休设置' : '保存失败，请检查日期、IANA 时区和存储状态';
      case StickerSetting.restoreBackup:
        final bool restored = await controller.restoreBackup();
        message = restored ? '已恢复备份，原配置已另存' : '备份恢复失败';
      case StickerSetting.pause:
        controller.setPaused(args['value'] as bool);
      case StickerSetting.openAssets:
        message = await _openAssets();
      case StickerSetting.reloadAssets:
        await layout.reloadCharacter();
        message = '已重新载入猫猫素材';
    }
    return StickerSettingsReply(snapshot(), message: message, canUndo: canUndo);
  }

  String? _move(String id, int? target) {
    final int origin = layout.groupOf(id);
    layout.assign(id, target);
    final int destination = layout.groupOf(id);
    if (destination == origin) return null;
    _lastMove = (id: id, origin: origin, destination: destination);
    return '「${StickerLayout.titles[id]}」已移到窗口 ${destination + 1}';
  }

  String? _undoMove() {
    final ({String id, int origin, int destination})? move = _lastMove;
    _lastMove = null;
    if (move == null || layout.groupOf(move.id) != move.destination) {
      return null;
    }
    layout.assign(move.id, move.origin);
    return '已撤销移动';
  }

  Future<String?> _openAssets() async {
    final Directory? directory = layout.directory;
    if (directory == null) return '素材目录尚未就绪';
    try {
      await directory.create(recursive: true);
      final ProcessResult result = await Process.run(
        Platform.isWindows ? 'explorer.exe' : 'open',
        <String>[directory.path],
      );
      return result.exitCode == 0 || Platform.isWindows ? null : '无法打开素材目录';
    } catch (_) {
      return '无法打开素材目录';
    }
  }
}
