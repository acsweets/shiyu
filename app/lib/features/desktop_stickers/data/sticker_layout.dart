import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// 外观偏好与业务设置分开保存，示例时间永远不写入业务配置。
class StickerLayout extends ChangeNotifier {
  StickerLayout({this.directory});

  /// 测试可传入独立目录。
  Directory? directory;

  /// 固定设计画布，窗口缩放时整组等比适配。
  static const Size canvas = Size(760, 560);

  /// 稳定的指标标识与中文标题。
  static const Map<String, String> titles = <String, String>{
    'work': '距离下班',
    'holiday': '距离放假',
    'payday': '距离发薪',
    'retirement': '距离退休',
  };

  /// 仅供观察版式的静态示例，不冒充业务计算。
  static const Map<String, String> examples = <String, String>{
    'work': '00天 02小时 36分 18秒',
    'holiday': '02天 06小时 15分 00秒',
    'payday': '10天 00小时 00分 00秒',
    'retirement': '8459天 02小时 36分 18秒',
  };

  /// 首次展示效果预览，界面始终标明示例。
  bool preview = true;

  /// 用户指定的主指标。
  String main = 'work';

  /// 开启的外围贴纸。
  Set<String> enabled = <String>{'work', 'holiday', 'payday', 'retirement'};

  /// 每张贴纸在设计画布内的位置。
  Map<String, Offset> positions = defaults();

  /// 可选的本地替换角色。
  File? character;

  /// 文件读取完成前不允许拖动，防止覆盖旧布局。
  bool ready = false;

  /// 外观文件写入失败时显示提示。
  bool writeFailed = false;

  /// 图片刷新版本，用于清除旧图缓存。
  int assetRevision = 0;

  /// 串行落盘，拖动事件不会互相覆盖。
  Future<void> _writes = Future<void>.value();

  /// 释放后不再通知。
  bool _disposed = false;

  static Map<String, Offset> defaults() => <String, Offset>{
    'work': const Offset(212, 148),
    'holiday': const Offset(466, 58),
    'payday': const Offset(28, 400),
    'retirement': const Offset(462, 400),
  };

  /// 从本机应用目录恢复排布，不修改 Rust 设置。
  Future<void> load() async {
    try {
      directory ??= Directory(
        '${(await getApplicationSupportDirectory()).path}/shiyu/appearance',
      );
      final File file = File('${directory!.path}/layout.json');
      if (await file.exists() && await file.length() < 32768) {
        final Map<String, dynamic> data =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        if (data['version'] == 1) {
          preview = data['preview'] as bool? ?? true;
          final String candidate = data['main'] as String? ?? 'work';
          if (titles.containsKey(candidate)) main = candidate;
          final List<dynamic>? items = data['enabled'] as List<dynamic>?;
          if (items != null) {
            enabled = items
                .whereType<String>()
                .where(titles.containsKey)
                .toSet();
          }
          enabled.add(main);
          final Map<String, dynamic> saved =
              data['positions'] as Map<String, dynamic>? ?? <String, dynamic>{};
          for (final String id in titles.keys) {
            final List<dynamic>? xy = saved[id] as List<dynamic>?;
            if (xy != null && xy.length == 2 && xy.every(_finite)) {
              positions[id] = constrain(
                id,
                Offset((xy[0] as num).toDouble(), (xy[1] as num).toDouble()),
              );
            }
          }
        }
      }
      await reloadCharacter();
    } catch (_) {
      writeFailed = true;
    } finally {
      ready = true;
      if (!_disposed) notifyListeners();
    }
  }

  static bool _finite(dynamic value) => value is num && value.isFinite;
  Size size(String id) =>
      id == main ? const Size(336, 230) : const Size(252, 120);
  Offset constrain(String id, Offset point) => Offset(
    point.dx.clamp(8, canvas.width - size(id).width - 8).toDouble(),
    point.dy.clamp(48, canvas.height - size(id).height - 24).toDouble(),
  );
  /// 在画布边界内移动单张贴纸。
  void move(String id, Offset delta) {
    if (!ready) return;
    positions[id] = constrain(id, positions[id]! + delta);
    notifyListeners();
  }

  /// 主项保持开启，其余贴纸可以自由开关。
  void toggle(String id, bool value) {
    if (id == main) return;
    if (value) {
      enabled.add(id);
    } else {
      enabled.remove(id);
    }
    persist();
    notifyListeners();
  }

  void setPreview(bool value) {
    preview = value;
    persist();
    notifyListeners();
  }

  /// 更换主项并复用主贴纸的位置。
  void setMain(String id) {
    if (main == id) return;
    final Offset center = positions[main]!;
    positions[main] = positions[id]!;
    main = id;
    enabled.add(id);
    positions[id] = constrain(id, center);
    for (final String item in titles.keys) {
      positions[item] = constrain(item, positions[item]!);
    }
    persist();
    notifyListeners();
  }

  /// 恢复默认位置但保留指标开关。
  void reset() {
    positions = defaults();
    for (final String id in titles.keys) {
      positions[id] = constrain(id, positions[id]!);
    }
    persist();
    notifyListeners();
  }

  /// 只在拖动结束落盘；失败不影响当前画布。
  void persist() {
    final Directory? folder = directory;
    if (!ready || folder == null) return;
    final String json = jsonEncode(<String, dynamic>{
      'version': 1,
      'preview': preview,
      'main': main,
      'enabled': enabled.toList(),
      'positions': positions.map(_encodePosition),
    });
    _writes = _writes.then((_) => _write(folder, json));
  }

  MapEntry<String, List<double>> _encodePosition(String id, Offset value) =>
      MapEntry<String, List<double>>(id, <double>[value.dx, value.dy]);
  Future<void> _write(Directory folder, String json) async {
    try {
      await folder.create(recursive: true);
      final File temporary = File('${folder.path}/layout.json.tmp');
      await temporary.writeAsString(json, flush: true);
      await temporary.rename('${folder.path}/layout.json');
    } catch (_) {
      writeFailed = true;
      if (!_disposed) notifyListeners();
    }
  }

  /// 读取用户覆盖图，缺失或解码失败由视图回退内置猫猫。
  Future<void> reloadCharacter() async {
    final Directory? folder = directory;
    if (folder == null) return;
    final File file = File('${folder.path}/character.png');
    character = await file.exists() && await file.length() <= 8 * 1024 * 1024
        ? file
        : null;
    if (character != null) await FileImage(character!).evict();
    assetRevision++;
    if (!_disposed) notifyListeners();
  }

  /// 供测试等待拖动落盘完成。
  Future<void> flush() => _writes;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
