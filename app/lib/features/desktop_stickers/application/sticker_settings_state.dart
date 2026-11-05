import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../platform/desktop/desktop_options.dart';
import '../../retirement/application/holiday_status.dart';
import '../../retirement/application/settings_access.dart';
import '../../retirement/data/settings_repository.dart';
import '../data/sticker_mode.dart';
import '../data/sticker_palette.dart';
import 'sticker_group_view.dart';

enum StickerSetting {
  palette,
  titleSize,
  groupVisible,
  titleVisible,
  move,
  undoMove,
  resize,
  resetBounds,
  preview,
  main,
  enabled,
  retirement,
  restoreBackup,
  pause,
  mode,
  desktop,
  startup,
  holidayCheck,
  holidayImport,
  businessRead,
  businessSave,
  businessImport,
  businessCountdown,
  businessPeek,
  openAssets,
  reloadAssets,
}

typedef SettingsRead = Future<StickerSettingsState> Function();
typedef SettingsDispatch = Future<StickerSettingsReply> Function(
  StickerSetting action,
  Map<String, Object?> arguments,
);

/// 设置窗只读快照，所有写入仍由主引擎处理。
class StickerSettingsState {
  const StickerSettingsState(this.data);

  /// 原生窗口通道承载的快照。
  final Map<Object?, Object?> data;

  int get mainGroup => data['mainGroup'] as int;
  String get main => data['main'] as String;
  bool get preview => data['preview'] as bool;
  StickerPalette get palette => StickerPalette.fromId(data['palette']);
  int get titleSize => data['titleSize'] as int;
  List<int> get groups => (data['groups'] as List<Object?>).cast<int>();
  Set<String> get enabled =>
      (data['enabled'] as List<Object?>).cast<String>().toSet();
  String? get retirementDate => data['retirementDate'] as String?;
  String get timeZone => data['timeZone'] as String;
  bool get editingBlocked => data['editingBlocked'] as bool;
  bool get canRestore => data['canRestore'] == true;
  bool get paused => data['paused'] == true;
  StickerMode get mode => StickerMode.read(data['mode']);
  DesktopOptions get desktop => DesktopOptions.read(data['desktop']);
  bool get visibilityShortcutOk => data['visibilityShortcutOk'] == true;
  bool get amountShortcutOk => data['amountShortcutOk'] != false;
  bool get startupSupported => data['startupSupported'] == true;
  bool get startupEnabled => data['startupEnabled'] == true;
  HolidayStatus? get holidayStatus {
    final Object? raw = data['holidayStatus'];
    return raw is Map<Object?, Object?> ? HolidayStatus(raw) : null;
  }

  bool get windowFailed => data['windowFailed'] as bool;
  bool get writeFailed => data['writeFailed'] as bool;
  SettingsView? get business {
    final Object? raw = data['business'];
    return raw is Map<Object?, Object?> ? SettingsView(raw) : null;
  }

  StickerGroupView window(int group) => StickerGroupView(
    (data['windows'] as List<Object?>)[group] as Map<Object?, Object?>,
  );

  String groupLabel(int group) =>
      group == mainGroup ? '主窗口 · 窗口 ${group + 1}' : '窗口 ${group + 1}';

  String members(int group) {
    final StickerGroupView view = window(group);
    return view.values.keys.map(view.label).join('、');
  }
}

/// 单次设置操作返回的新快照和可选反馈。
class StickerSettingsReply {
  const StickerSettingsReply(
    this.state, {
    this.message,
    this.canUndo = false,
    this.privateSalary,
  });

  /// 操作后的配置。
  final StickerSettingsState state;

  /// 可以直接在界面中展示的结果。
  final String? message;

  /// 本次移动可撤销。
  final bool canUndo;
  final SettingsValues? privateSalary;

  factory StickerSettingsReply.fromData(Map<Object?, Object?> data) =>
      StickerSettingsReply(
        StickerSettingsState(data['state'] as Map<Object?, Object?>),
        message: data['message'] as String?,
        canUndo: data['canUndo'] as bool,
        privateSalary: (data['privateSalary'] as Map<Object?, Object?>?)
            ?.cast<String, dynamic>(),
      );

  Map<String, Object?> get data => <String, Object?>{
    'state': state.data,
    'message': message,
    'canUndo': canUndo,
    'privateSalary': privateSalary,
  };
}

/// 按顺序应用设置，避免较慢的请求覆盖滑块或菜单的后续修改。
class StickerSettingsSession extends ChangeNotifier {
  StickerSettingsSession(this.state, this.read, this.dispatch);

  /// 当前展示的配置。
  StickerSettingsState state;

  /// 读取主引擎最新状态。
  final SettingsRead read;

  /// 将修改交给主引擎。
  final SettingsDispatch dispatch;

  /// 所有设置读写共享同一队列。
  Future<void> _pending = Future<void>.value();

  /// 释放后忽略正在返回的结果。
  bool _closed = false;

  Future<StickerSettingsReply> send(
    StickerSetting action, [
    Map<String, Object?> arguments = const <String, Object?>{},
  ]) {
    final Future<StickerSettingsReply> next = _pending.then(
      (void _) => dispatch(action, arguments),
    );
    _pending = next.then<void>(_accept).catchError(_ignoreFailure);
    return next;
  }

  void change(
    StickerSetting action, [
    Map<String, Object?> arguments = const <String, Object?>{},
  ]) => unawaited(
    send(action, arguments).then<void>(_ignoreReply).catchError(_ignoreFailure),
  );

  void refresh() {
    _pending = _pending.then(_read).catchError(_ignoreFailure);
  }

  Future<void> _read(void _) async => _setState(await read());

  void _accept(StickerSettingsReply reply) => _setState(reply.state);

  void _setState(StickerSettingsState next) {
    if (_closed) return;
    state = next;
    notifyListeners();
  }

  void _ignoreReply(StickerSettingsReply reply) {}

  void _ignoreFailure(Object error, StackTrace stack) {
    debugPrint('设置窗口通讯失败');
  }

  @override
  void dispose() {
    _closed = true;
    super.dispose();
  }
}
