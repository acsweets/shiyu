import 'dart:convert';

import '../domain/core_gateway.dart';
import 'settings_store.dart';

typedef SettingsValues = Map<String, dynamic>;

/// 读入结果区分可用配置、只读回退与可恢复备份。
class LoadedSettings {
  const LoadedSettings(this.values, {this.problem, this.canRestore = false});

  /// 已经通过核心校验的配置。
  final SettingsValues values;

  /// 稳定错误类型，供页面显示。
  final String? problem;

  /// 是否存在可显式恢复的旧副本。
  final bool canRestore;
}

/// 在平台存储与核心之间处理迁移、备份和恢复。
class SettingsRepository {
  SettingsRepository({
    required this.core,
    required this.primary,
    this.backup,
    this.archive,
  });

  /// 核心负责配置字段与版本校验。
  final CoreGateway core;

  /// 桌面应用数据或移动共享容器中的主配置。
  final SettingsStore primary;

  /// 上一次有效写入之前的合法设置。
  final SettingsStore? backup;

  /// 显式恢复前保留的损坏主文件。
  final SettingsStore? archive;

  /// 最后一次成功读写的主文件内容。
  String? _persisted;

  /// 读入失败时保留的原始内容，未来版本不会进入恢复流程。
  String? _damaged;

  /// 已校验的备份，用于显式恢复。
  SettingsValues? _recovery;

  /// 加载合法主文件，遇损坏时允许用备份只读启动。
  Future<LoadedSettings> load() async {
    final SettingsValues defaults = _object(await core.defaults());
    _recovery = null;
    _damaged = null;
    try {
      final String? raw = await primary.read();
      _persisted = raw;
      if (raw == null) return LoadedSettings(defaults);
      final int? version = _version(raw);
      if (version != null && version > 1) {
        return LoadedSettings(defaults, problem: 'future_settings');
      }
      final SettingsValues? values = await _validated(raw, version: version);
      if (values != null) {
        if (version == 0) {
          await _write(values);
        }
        return LoadedSettings(values);
      }
      _damaged = raw;
      final String? previous = await backup?.read();
      if (previous != null && archive != null) {
        _recovery = await _validated(previous, version: _version(previous));
      }
      return LoadedSettings(
        _recovery ?? defaults,
        problem: 'invalid_settings',
        canRestore: _recovery != null,
      );
    } catch (_) {
      return LoadedSettings(defaults, problem: 'storage');
    }
  }

  /// 校验完整候选配置，备份当前原文后原子替换。
  Future<SettingsValues?> save(SettingsValues proposed) async {
    final SettingsValues? values = await _validated(jsonEncode(proposed));
    if (values != null) await _write(values);
    return values;
  }

  /// 恢复前保留坏文件。若期间已有其它写入，保留现有文件。
  Future<SettingsValues?> restoreBackup() async {
    final SettingsValues? recovered = _recovery;
    final String? damaged = _damaged;
    final SettingsStore? damagedArchive = archive;
    if (recovered == null || damaged == null || damagedArchive == null) {
      return null;
    }
    await _checkUnchanged();
    await damagedArchive.write(damaged);
    final String raw = jsonEncode(recovered);
    await primary.write(raw);
    _persisted = raw;
    _damaged = null;
    _recovery = null;
    return recovered;
  }

  Future<void> _write(SettingsValues values) async {
    await _checkUnchanged();
    final String? previous = _persisted;
    if (previous != null) await backup?.write(previous);
    final String raw = jsonEncode(values);
    await primary.write(raw);
    _persisted = raw;
    if (previous == null) {
      try {
        await backup?.write(raw);
      } catch (_) {
        // 首次写入已经成功，下次保存仍可备份现有合法主文件。
      }
    }
  }

  Future<void> _checkUnchanged() async {
    if (await primary.read() != _persisted) {
      throw StateError('settings_changed');
    }
  }

  Future<SettingsValues?> _validated(String raw, {int? version}) async {
    final String candidate = version == 0
        ? jsonEncode(<String, dynamic>{..._object(raw), 'schema_version': 1})
        : raw;
    final SettingsValues reply = _object(await core.validate(candidate));
    return reply['ok'] == true ? reply['settings'] as SettingsValues : null;
  }

  int? _version(String raw) {
    try {
      final Object? version = _object(raw)['schema_version'];
      return version is int ? version : null;
    } catch (_) {
      return null;
    }
  }

  SettingsValues _object(String raw) => jsonDecode(raw) as SettingsValues;
}
