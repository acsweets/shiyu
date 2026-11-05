import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'sticker_cat_pose.dart';
import 'sticker_character.dart';
import 'sticker_palette.dart';

/// 保存窗口分组与外观，不改变 Rust 业务设置。
class StickerLayout extends ChangeNotifier {
  StickerLayout({this.directory});

  /// 本机外观目录，测试可指定隔离目录。
  Directory? directory;

  /// 每项倒计时的稳定 ID 和名称。
  static const Map<String, String> titles = <String, String>{
    'work': '距离下班',
    'holiday': '距离放假',
    'payday': '距离发薪',
    'retirement': '距离退休',
  };

  /// 仅用于效果预览的固定示例。
  static const Map<String, String> examples = <String, String>{
    'work': '00天 02小时 36分 18秒',
    'holiday': '02天 06小时 15分 00秒',
    'payday': '10天 00小时 00分 00秒',
    'retirement': '8459天 02小时 36分 18秒',
  };

  /// 保证单张贴纸和窗口操作始终可用。
  static const Size minimum = Size(260, 146);

  /// 提示文字的字号范围，旧布局沿用原来的字号。
  static const int minTitleSize = 10;
  static const int maxTitleSize = 24;
  static const int defaultTitleSize = 13;

  /// 当前是否展示示例。
  bool preview = true;

  /// 所有窗口共用的当前色系。
  StickerPalette _palette = StickerPalette.macaron;

  /// 所有浮窗共用的标题字号。
  int _titleSize = defaultTitleSize;

  /// 主指标带猫猫，并负责打开设置。
  String main = 'work';

  /// 当前开启的倒计时。
  Set<String> enabled = titles.keys.toSet();

  /// 每项只归属一个窗口槽位，空槽位可用于拆分。
  final Map<String, int> _groups = _separateGroups();

  /// 各窗口上次保存的桌面位置与尺寸。
  final Map<int, Rect> _bounds = <int, Rect>{};

  /// 隐藏标题的窗口槽位。
  final Set<int> _hiddenTitles = <int>{};

  /// 隐藏的窗口槽位，保留其成员和几何信息。
  final Set<int> _hiddenGroups = <int>{};

  /// 编号图片只覆盖同一窗口槽位。
  final Map<StickerCatPose, StickerCharacter> _characters =
      <StickerCatPose, StickerCharacter>{};

  /// 保留旧版主窗口角色图的替换方式。
  StickerCharacter? _mainCharacter;

  /// 磁盘状态加载完成后启用编辑。
  bool ready = false;

  /// 外观读取或写入异常。
  bool writeFailed = false;

  /// 同名角色图重新加载时更新缓存。
  int assetRevision = 0;

  /// 串行保存，避免较早的布局覆盖新布局。
  Future<void> _writes = Future<void>.value();

  /// 释放后不再发送更新。
  bool _disposed = false;

  int get mainGroup => groupOf(main);
  StickerPalette get palette => _palette;
  int get titleSize => _titleSize;
  int groupOf(String id) => _groups[id]!;
  bool showsTitle(int group) => !_hiddenTitles.contains(group);
  bool showsGroup(int group) => !_hiddenGroups.contains(group);
  Rect? boundsOf(int group) => _bounds[group];

  StickerCharacter? characterOf(int group) =>
      _characters[StickerCatPose.values[group]] ??
      (group == mainGroup ? _mainCharacter : null);

  List<String> members(int group) => titles.keys
      .where((String id) => enabled.contains(id) && groupOf(id) == group)
      .toList();

  Set<int> get activeGroups => enabled.map(groupOf).toSet();

  bool get hasVisibleGroups => activeGroups.any(showsGroup);

  static Map<String, int> _separateGroups() => <String, int>{
    for (int index = 0; index < titles.length; index++)
      titles.keys.elementAt(index): index,
  };

  /// 初次拆分后按旧画布方位分散，用户可继续移动。
  Rect initialBounds(int group) {
    final int count = members(group).length;
    final double width = count > 1 ? 488 : 280;
    final double height = count > 2 ? 272 : 172;
    final Offset offset = switch (group) {
      0 => const Offset(160, 100),
      1 => const Offset(460, 80),
      2 => const Offset(100, 312),
      _ => const Offset(450, 300),
    };
    return offset & Size(width, height);
  }

  /// 兼容旧版外观设置，并将旧画布内位置转换为窗口初始位置。
  Future<void> load() async {
    try {
      directory ??= Directory(
        '${(await getApplicationSupportDirectory()).path}/shiyu/appearance',
      );
      final File file = File('${directory!.path}/layout.json');
      if (await file.exists() && await file.length() < 32768) {
        _restore(jsonDecode(await file.readAsString()) as Map<String, dynamic>);
      }
      await reloadCharacter();
    } catch (_) {
      writeFailed = true;
    } finally {
      ready = true;
      if (!_disposed) notifyListeners();
    }
  }

  void _restore(Map<String, dynamic> data) {
    final Object? version = data['version'];
    if (version != 1 && version != 2) return;
    _palette = StickerPalette.fromId(data['palette']);
    final Object? titleSize = data['titleSize'];
    if (titleSize is int) {
      _titleSize = titleSize.clamp(minTitleSize, maxTitleSize);
    }
    preview = data['preview'] is! bool || data['preview'] == true;
    final Object? candidate = data['main'];
    if (candidate is String && titles.containsKey(candidate)) main = candidate;
    final Object? items = data['enabled'];
    if (items is List<dynamic>) {
      enabled = items.whereType<String>().where(titles.containsKey).toSet();
    }
    enabled.add(main);
    if (version == 1) {
      _migratePositions(data['positions']);
      return;
    }
    final Object? groups = data['groups'];
    if (groups is Map<String, dynamic>) {
      for (final String id in titles.keys) {
        final Object? group = groups[id];
        if (group is int && group >= 0 && group < titles.length) {
          _groups[id] = group;
        }
      }
    }
    final Object? bounds = data['bounds'];
    if (bounds is Map<String, dynamic>) {
      for (int group = 0; group < titles.length; group++) {
        final Rect? rect = decodeBounds(bounds['$group']);
        if (rect != null) _bounds[group] = rect;
      }
    }
    final Object? hidden = data['hiddenTitles'];
    if (hidden is List<dynamic>) {
      _hiddenTitles.addAll(hidden.whereType<int>());
    }
    final Object? hiddenGroups = data['hiddenGroups'];
    if (hiddenGroups is List<dynamic>) {
      _hiddenGroups.addAll(hiddenGroups.whereType<int>());
    }
  }

  void _migratePositions(Object? positions) {
    if (positions is! Map<String, dynamic>) return;
    for (final String id in titles.keys) {
      final Object? pair = positions[id];
      if (pair is List<dynamic> && pair.length == 2 && pair.every(_finite)) {
        final int group = groupOf(id);
        final Offset position = Offset(
          (pair[0] as num).toDouble(),
          (pair[1] as num).toDouble(),
        );
        _bounds[group] =
            (position + const Offset(20, 36)) & initialBounds(group).size;
      }
    }
  }

  static bool _finite(Object? value) => value is num && value.isFinite;

  static Rect? decodeBounds(Object? value) {
    if (value is! List<dynamic> || value.length != 4 || !value.every(_finite)) {
      return null;
    }
    return Rect.fromLTWH(
      (value[0] as num).toDouble(),
      (value[1] as num).toDouble(),
      (value[2] as num).clamp(minimum.width, 4096).toDouble(),
      (value[3] as num).clamp(minimum.height, 4096).toDouble(),
    );
  }

  static List<double> encodeBounds(Rect rect) => <double>[
    rect.left,
    rect.top,
    rect.width,
    rect.height,
  ];

  /// 空槽位会继承拆出前窗口附近的起始位置。
  void assign(String id, int? target) {
    final int current = groupOf(id);
    if (target == null) {
      if (_groups.values.where((int group) => group == current).length == 1) {
        return;
      }
      final int preferred = titles.keys.toList().indexOf(id);
      target = _groups.containsValue(preferred)
          ? List<int>.generate(
              titles.length,
              _groupIndex,
            ).firstWhere((int group) => !_groups.containsValue(group))
          : preferred;
      final Rect source = boundsOf(current) ?? initialBounds(current);
      _bounds[target] ??=
          (source.topLeft + const Offset(32, 32)) & const Size(280, 172);
      _hiddenGroups.remove(target);
    }
    if (target == current) return;
    _groups[id] = target;
    _changed();
  }

  static int _groupIndex(int index) => index;

  void setTitleVisible(int group, bool value) {
    if (value) {
      _hiddenTitles.remove(group);
    } else {
      _hiddenTitles.add(group);
    }
    _changed();
  }

  void saveBounds(int group, Rect rect) {
    if (!ready || _bounds[group] == rect) return;
    _bounds[group] = rect;
    persist();
  }

  void toggle(String id, bool value) {
    if (id == main) return;
    if (value) {
      enabled.add(id);
    } else {
      enabled.remove(id);
    }
    _changed();
  }

  /// 只改变窗口显隐，分组中的倒计时继续保持启用。
  void setGroupVisible(int group, bool value) {
    final bool changed = value
        ? _hiddenGroups.remove(group)
        : _hiddenGroups.add(group);
    if (changed) _changed();
  }

  void setPreview(bool value) {
    preview = value;
    _changed();
  }

  /// 保存配色并让主窗口和子窗口读取新颜色。
  void setPalette(StickerPalette value) {
    if (_palette == value) return;
    _palette = value;
    _changed();
  }

  /// 保存字号并同步给所有浮窗。
  void setTitleSize(int size) {
    final int clamped = size.clamp(minTitleSize, maxTitleSize);
    if (_titleSize == clamped) return;
    _titleSize = clamped;
    _changed();
  }

  void setMain(String id) {
    if (main == id) return;
    main = id;
    enabled.add(id);
    _changed();
  }

  /// 复位窗口位置与尺寸，保留分组和标题选项。
  void reset() {
    for (final int group in activeGroups) {
      _bounds[group] = initialBounds(group);
    }
    _changed();
  }

  void _changed() {
    persist();
    notifyListeners();
  }

  void persist() {
    final Directory? folder = directory;
    if (!ready || folder == null) return;
    final String json = jsonEncode(<String, dynamic>{
      'version': 2,
      'preview': preview,
      'palette': _palette.name,
      'titleSize': _titleSize,
      'main': main,
      'enabled': enabled.toList(),
      'groups': _groups,
      'bounds': _bounds.map(_encodeGroupBounds),
      'hiddenTitles': _hiddenTitles.toList(),
      'hiddenGroups': _hiddenGroups.toList(),
    });
    _writes = _writes.then((_) => _write(folder, json));
  }

  MapEntry<String, List<double>> _encodeGroupBounds(int group, Rect rect) =>
      MapEntry<String, List<double>>('$group', encodeBounds(rect));

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

  /// 缺失或无法解码时由视图回退到内置猫猫。
  Future<void> reloadCharacter() async {
    final Directory? folder = directory;
    if (folder == null) return;
    final Map<StickerCatPose, StickerCharacter> characters =
        <StickerCatPose, StickerCharacter>{};
    for (final StickerCatPose pose in StickerCatPose.values) {
      final StickerCharacter? character = await StickerCharacter.read(
        File('${folder.path}/${pose.overrideFileName}'),
      );
      if (character != null) characters[pose] = character;
    }
    final StickerCharacter? main = await StickerCharacter.read(
      File('${folder.path}/${StickerCatPose.sitting.fileName}'),
    );
    _characters
      ..clear()
      ..addAll(characters);
    _mainCharacter = main;
    assetRevision++;
    if (!_disposed) notifyListeners();
  }

  /// 关闭前等待最后一次位置保存。
  Future<void> flush() => _writes;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
