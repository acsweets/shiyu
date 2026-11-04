import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/settings_store.dart';
import '../domain/core_gateway.dart';
import '../domain/retirement_snapshot.dart';
import '../../../platform/widgets/widget_bridge.dart';

class RetirementController extends ChangeNotifier {
  RetirementController({
    required this.core,
    required this.store,
    required this.widgets,
  });

  /// 可替换的共享核心调用入口。
  final CoreGateway core;

  /// 当前平台原子设置存储。
  final SettingsStore store;

  /// 原生组件刷新适配器。
  final WidgetBridge widgets;

  /// 已通过 Rust 校验的设置，未保存的表单不修改此值。
  Map<String, dynamic> settings = <String, dynamic>{};

  /// 最近一次来自真实 Rust 的快照。
  RetirementSnapshot? snapshot;

  /// 可本地化的错误类型，禁止放置配置原值。
  String? problem;

  /// 写入期间禁用提交，防止临时文件相互覆盖。
  bool saving = false;

  /// 损坏或未来版本的文件只读保留，避免用默认设置覆盖未知内容。
  bool editingBlocked = false;

  /// 界面可见期间的刷新计时器。
  Timer? _timer;

  /// 串行刷新链，保存操作可以等待自己的新快照，而不是读到旧 tick。
  Future<void> _queuedRefresh = Future<void>.value();

  /// 已释放的控制器不再通知视图。
  bool _disposed = false;

  /// 设置修订号，用来丢弃过期的异步结果。
  int _revision = 0;

  String? get retirementDate => settings['retirement_date'] as String?;
  String get timeZone => settings['time_zone'] as String? ?? 'Asia/Shanghai';

  /// 读取已有设置并校验，失败时不静默覆盖用户文件。
  Future<void> initialize() async {
    settings = jsonDecode(await core.defaults()) as Map<String, dynamic>;
    try {
      final String? stored = await store.read();
      if (stored != null) {
        final Map<String, dynamic> result =
            jsonDecode(await core.validate(stored)) as Map<String, dynamic>;
        if (result['ok'] != true) {
          problem = 'invalid_settings';
          editingBlocked = true;
        } else {
          settings = result['settings'] as Map<String, dynamic>;
        }
      }
    } catch (_) {
      problem = 'storage';
      editingBlocked = true;
    }
    await refresh();
  }

  /// 每次以当前绝对时间重算，而非累加过去的 tick。
  Future<void> refresh() async {
    if (_disposed) return;
    final Future<void> previous = _queuedRefresh;
    final Completer<void> completion = Completer<void>();
    _queuedRefresh = completion.future;
    await previous;
    try {
      await _refreshOnce();
    } finally {
      completion.complete();
    }
  }

  Future<void> _refreshOnce() async {
    if (_disposed) return;
    final int revision = _revision;
    try {
      final Map<String, dynamic> result = jsonDecode(
        await core.compute(
          jsonEncode(settings),
          DateTime.now().millisecondsSinceEpoch,
        ),
      ) as Map<String, dynamic>;
      if (!_disposed && revision == _revision) {
        if (result['ok'] == true) {
          snapshot = RetirementSnapshot.fromJson(
            result['snapshot'] as Map<String, dynamic>,
          );
        } else {
          problem = 'invalid_settings';
        }
      }
    } catch (_) {
      if (!_disposed) problem = 'core';
    } finally {
      if (!_disposed) notifyListeners();
    }
  }

  /// 先校验，再落盘，最后请求系统组件刷新；失败不覆盖合法配置。
  Future<bool> save(String? date, String zone) async {
    if (saving || editingBlocked) return false;
    saving = true;
    problem = null;
    notifyListeners();
    try {
      final Map<String, dynamic> proposed = <String, dynamic>{
        ...settings,
        'retirement_date': date,
        'time_zone': zone.trim(),
      };
      final Map<String, dynamic> result = jsonDecode(
        await core.validate(jsonEncode(proposed)),
      ) as Map<String, dynamic>;
      if (result['ok'] != true) {
        problem = 'invalid_settings';
        return false;
      }
      final Map<String, dynamic> validated =
          result['settings'] as Map<String, dynamic>;
      await store.write(jsonEncode(validated));
      settings = validated;
      _revision++;
      await refresh();
      try {
        await widgets.refresh();
      } catch (_) {
        problem = 'widget_refresh';
      }
      return true;
    } catch (_) {
      problem = 'storage';
      return false;
    } finally {
      saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  void _tick(Timer timer) {
    unawaited(refresh());
  }

  void setVisible(bool visible) {
    _timer?.cancel();
    if (visible && !_disposed) {
      unawaited(refresh());
      _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
