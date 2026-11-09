import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../platform/widgets/widget_bridge.dart';
import '../data/holiday_repository.dart';
import '../data/settings_repository.dart';
import '../data/settings_store.dart';
import '../domain/core_gateway.dart';
import '../domain/retirement_snapshot.dart';

typedef RuntimeClock = DateTime Function();
typedef PersistSettings = Future<SettingsValues?> Function();

class RetirementController extends ChangeNotifier {
  RetirementController({
    required this.core,
    required this.store,
    required this.widgets,
    SettingsRepository? repository,
    this.holidays,
    RuntimeClock? now,
  }) : _repository =
           repository ?? SettingsRepository(core: core, primary: store),
       _now = now ?? DateTime.now;

  /// 可替换的共享核心调用入口。
  final CoreGateway core;

  /// 当前平台原子设置存储。
  final SettingsStore store;

  /// 原生组件刷新适配器。
  final WidgetBridge widgets;

  /// 只读的本地节假日入口。
  final HolidayRepository? holidays;

  /// 版本化配置、备份和损坏恢复。
  final SettingsRepository _repository;

  /// 每次读取当前墙钟，测试可注入跳变时间。
  final RuntimeClock _now;

  /// 已通过 Rust 校验的设置。
  SettingsValues settings = <String, dynamic>{};

  /// 最近一次真实快照。
  RetirementSnapshot? snapshot;

  /// 可本地化的错误类型。
  String? problem;

  /// 写入期间禁用提交。
  bool saving = false;

  /// 损坏或未来版本的原件只读保留。
  bool editingBlocked = false;

  /// 当前只读配置有可校验的备份。
  bool canRestoreBackup = false;
  bool _fresh = false;

  /// 已校验的地区数据和更新结果供设置窗显示。
  HolidaySelection? holidayData;
  HolidayUpdate holidayUpdate = HolidayUpdate.idle;
  String _holidayJson = '{}';
  Future<HolidayUpdate>? _holidayTask;
  Future<void> _widgetQueue = Future<void>.value();

  /// 一次性整秒计时器。
  Timer? _timer;

  /// 当前界面、系统和用户暂停状态。
  bool _visible = false;
  bool _suspended = false;
  bool _paused = false;

  /// 使旧定时链退出，避免暂停或恢复后重复计时。
  int _generation = 0;

  /// 显式刷新按序，定时链每次等待上一帧。
  Future<void> _queuedRefresh = Future<void>.value();

  /// 已释放的控制器不再通知视图。
  bool _disposed = false;

  /// 设置修订号，用来丢弃过期的异步结果。
  int _revision = 0;

  String? get retirementDate => settings['retirement_date'] as String?;
  String get timeZone => settings['time_zone'] as String? ?? 'Asia/Shanghai';
  String get holidayRegion => settings['region'] as String? ?? 'CN';
  List<SettingsIssue> get settingsIssues => _repository.issues;
  SettingsValues get displaySettings =>
      settings['display'] as SettingsValues? ?? <String, dynamic>{};
  String? get preferredLocale => displaySettings['locale'] as String?;
  bool get needsOnboarding {
    final bool? completed = displaySettings['onboarding_completed'] as bool?;
    return !editingBlocked &&
        (completed == false || (_fresh && completed == null));
  }

  bool get paused => _paused;

  /// 读入主配置或只读备份，再执行首次快照。
  Future<void> initialize() async {
    final LoadedSettings loaded = await _repository.load();
    settings = loaded.values;
    _fresh = loaded.fresh;
    editingBlocked = loaded.problem != null;
    canRestoreBackup = loaded.canRestore;
    problem = loaded.problem;
    await reloadHolidays(syncWidgets: false);
  }

  /// 更新本地假日输入，供导入和地区变化后立即重算。
  Future<void> reloadHolidays({
    bool refreshWidgets = false,
    bool syncWidgets = true,
  }) async {
    final int revision = _revision;
    HolidaySelection? loaded;
    try {
      loaded = await holidays?.read(holidayRegion);
    } catch (_) {
      // 文件缺失或无法读取时按核心周工作日规则降级。
    }
    if (_disposed || revision != _revision) return;
    holidayData = loaded;
    _holidayJson = loaded?.pack.coreJson ?? '{}';
    await refresh();
    if (_active && revision == _revision) _restartTicker(refreshed: true);
    if (syncWidgets && revision == _revision) {
      await synchronizeWidgets(refresh: refreshWidgets);
    }
  }

  Future<void> synchronizeWidgets({bool refresh = true}) {
    if (!widgets.supported || _disposed) return Future<void>.value();
    final int revision = _revision;
    _widgetQueue = _widgetQueue.then(
      (void _) => _publishWidgets(revision, refresh),
    );
    return _widgetQueue;
  }

  Future<void> _publishWidgets(int revision, bool refreshWidgets) async {
    if (_disposed || revision != _revision) return;
    try {
      final String? calendar = holidayData?.pack.widgetJson;
      final bool changed =
          calendar != null && await widgets.writeCalendar(calendar);
      if (changed || refreshWidgets) await widgets.refresh();
      if (!_disposed && revision == _revision && problem == 'widget_refresh') {
        problem = null;
        notifyListeners();
      }
    } catch (_) {
      if (!_disposed && revision == _revision && problem == null) {
        problem = 'widget_refresh';
        notifyListeners();
      }
    }
  }

  Future<HolidayUpdate> checkHolidayUpdates({bool silent = false}) =>
      _holidayTask ?? _updateHolidays(holidays?.check, silent: silent);

  Future<HolidayUpdate> importHolidayPack(String raw) async {
    final HolidayRepository? repository = holidays;
    final String region = holidayRegion;
    while (_holidayTask != null) {
      await _holidayTask;
    }
    return _updateHolidays(
      repository == null ? null : () => repository.importPack(region, raw),
    );
  }

  Future<HolidayUpdate> _updateHolidays(
    Future<HolidayUpdate> Function()? action, {
    bool silent = false,
  }) {
    if (action == null || _disposed) {
      return Future<HolidayUpdate>.value(HolidayUpdate.failed);
    }
    return _holidayTask = _runHolidayUpdate(action, silent);
  }

  Future<HolidayUpdate> _runHolidayUpdate(
    Future<HolidayUpdate> Function() action,
    bool silent,
  ) async {
    if (!silent) {
      holidayUpdate = HolidayUpdate.checking;
      notifyListeners();
    }
    HolidayUpdate result = HolidayUpdate.failed;
    try {
      result = await action();
      if (!_disposed && result == HolidayUpdate.updated) await reloadHolidays();
    } catch (_) {
      result = HolidayUpdate.failed;
    } finally {
      _holidayTask = null;
      if (!_disposed) {
        holidayUpdate = silent && result != HolidayUpdate.updated
            ? HolidayUpdate.idle
            : result;
        notifyListeners();
      }
    }
    return result;
  }

  /// 每次以当前绝对时间重算。
  Future<void> refresh() => _enqueueRefresh();

  Future<void> _enqueueRefresh([int? generation]) {
    _queuedRefresh = _queuedRefresh.then((void _) => _refreshOnce(generation));
    return _queuedRefresh;
  }

  Future<void> _refreshOnce(int? generation) async {
    if (!_canRefresh(generation)) return;
    final int revision = _revision;
    try {
      final int now = _now().millisecondsSinceEpoch;
      // 主文件异常时，旧备份的金额可见性可能落后于当前用户偏好。
      final String rawSettings = jsonEncode(
        editingBlocked
            ? <String, dynamic>{...settings, 'hide_amount': true}
            : settings,
      );
      SettingsValues result = await _compute(rawSettings, now, _holidayJson);
      if (result['ok'] != true && _holidayJson != '{}') {
        result = await _compute(rawSettings, now, '{}');
      }
      if (!_canRefresh(generation) || revision != _revision) return;
      if (result['ok'] == true) {
        snapshot = RetirementSnapshot.fromJson(
          result['snapshot'] as SettingsValues,
        );
        if (problem == 'core') problem = null;
      } else if (!editingBlocked) {
        problem = 'core';
      }
    } catch (_) {
      if (_canRefresh(generation) && revision == _revision && !editingBlocked) {
        problem = 'core';
      }
    } finally {
      if (_canRefresh(generation) && revision == _revision) notifyListeners();
    }
  }

  bool _canRefresh(int? generation) =>
      !_disposed && (generation == null || generation == _generation);

  Future<SettingsValues> _compute(
    String raw,
    int now,
    String holidayJson,
  ) async =>
      jsonDecode(await core.compute(raw, now, holidayJson: holidayJson))
          as SettingsValues;

  /// 退休表单只覆盖自己的字段，其余设置完整保留。
  Future<bool> save(String? date, String zone) =>
      saveSettings(<String, dynamic>{
        ...settings,
        'retirement_date': date,
        'time_zone': zone.trim(),
      });

  /// 顶层设置只更新应用语言，其余显示偏好保持原样。
  Future<bool> setPreferredLocale(String? locale) =>
      saveSettings(<String, dynamic>{
        ...settings,
        'display': <String, dynamic>{...displaySettings, 'locale': locale},
      });

  /// 快捷键与设置开关共用同一金额遮蔽状态。
  Future<bool> setAmountHidden(bool hidden) =>
      saveSettings(<String, dynamic>{...settings, 'hide_amount': hidden});

  /// 后续设置页通过同一校验与持久化入口提交完整候选。
  Future<bool> saveSettings(SettingsValues candidate) async {
    if (editingBlocked) return false;
    return _persist(() => _repository.save(candidate));
  }

  Future<bool> importSettings(String raw) async {
    if (editingBlocked) return false;
    return _persist(() => _repository.importSettings(raw));
  }

  Future<bool> changeCountdown(SettingsValues change) async {
    if (editingBlocked) return false;
    return _persist(
      () => _repository.changeCountdown(
        settings,
        change,
        _now().millisecondsSinceEpoch,
      ),
    );
  }

  /// 临时查看单独计算，原快照和共享设置始终保持原金额遮蔽。
  Future<SettingsValues?> peekSalary() async {
    if (editingBlocked) return null;
    final int revision = _revision;
    final SettingsValues reply = await _compute(
      jsonEncode(<String, dynamic>{...settings, 'hide_amount': false}),
      _now().millisecondsSinceEpoch,
      _holidayJson,
    );
    if (_disposed || revision != _revision || reply['ok'] != true) return null;
    final SettingsValues snapshot = reply['snapshot'] as SettingsValues;
    return snapshot['salary'] as SettingsValues?;
  }

  /// 只有用户显式恢复时才替换主配置。
  Future<bool> restoreBackup() async {
    if (!canRestoreBackup) return false;
    return _persist(_repository.restoreBackup);
  }

  Future<bool> _persist(PersistSettings action) async {
    if (_disposed || saving) return false;
    saving = true;
    problem = null;
    notifyListeners();
    try {
      final SettingsValues? saved = await action();
      if (saved == null) {
        problem = 'invalid_settings';
        return false;
      }
      settings = saved;
      editingBlocked = false;
      canRestoreBackup = false;
      _revision++;
      await reloadHolidays(refreshWidgets: true);
      return true;
    } catch (_) {
      problem = 'storage';
      return false;
    } finally {
      saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  void setVisible(bool visible) {
    if (_visible == visible) return;
    _visible = visible;
    _restartTicker();
  }

  void setPaused(bool paused) {
    if (_paused == paused) return;
    _paused = paused;
    _restartTicker();
    if (!_disposed) notifyListeners();
  }

  void setSystemSuspended(bool suspended) {
    if (_suspended == suspended) return;
    _suspended = suspended;
    _restartTicker();
  }

  /// 时间跳变使旧计时器失效，按新墙钟重新对齐。
  void clockChanged() => _restartTicker();

  bool get _active => !_disposed && _visible && !_paused && !_suspended;

  void _restartTicker({bool refreshed = false}) {
    _timer?.cancel();
    _generation++;
    if (!_active) return;
    if (refreshed) {
      _scheduleNextTick(_generation);
    } else {
      unawaited(_tick(_generation));
    }
  }

  Future<void> _tick(int generation) async {
    await _enqueueRefresh(generation);
    if (!_active || generation != _generation) return;
    _scheduleNextTick(generation);
  }

  /// 刚保存的活动目标需要立即切回逐秒节奏。
  void _scheduleNextTick(int generation) {
    final int now = _now().millisecondsSinceEpoch;
    final RetirementSnapshot? current = snapshot;
    final int cap = current?.changesEverySecond == false
        ? 60000
        : 1000 - now % 1000;
    final int? boundary = current?.nextChangeAtMillis;
    final int delay = boundary == null || boundary <= now
        ? cap
        : (boundary - now).clamp(1, cap);
    _timer = Timer(
      Duration(milliseconds: delay),
      () => unawaited(_tick(generation)),
    );
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
