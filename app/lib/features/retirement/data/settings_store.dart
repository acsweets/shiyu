import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../platform/widgets/widget_bridge.dart';

abstract interface class SettingsStore {
  Future<String?> read();
  Future<void> write(String json);
}

class LocalSettingsStore implements SettingsStore {
  LocalSettingsStore(this.directory, {this.fileName = 'settings.json'});

  /// 仅保存在当前用户应用数据目录，测试可传入临时目录。
  final Directory directory;

  /// 备份与原件使用同一套文件写入规则。
  final String fileName;

  File get _file => File('${directory.path}/$fileName');

  @override
  Future<String?> read() async {
    final File file = _file;
    if (!await file.exists()) return null;
    if (await file.length() > 128 * 1024) {
      throw const FileSystemException('settings_too_large');
    }
    return file.readAsString();
  }

  /// 使用同卷独立暂存目录，避免不同实例共用临时文件。
  @override
  Future<void> write(String json) async {
    await directory.create(recursive: true);
    final Directory staging = await directory.createTemp('.settings-write-');
    try {
      final File temporary = await File('${staging.path}/data').create();
      if (Platform.isMacOS || Platform.isLinux) {
        final ProcessResult result = await Process.run('chmod', <String>[
          '600',
          temporary.path,
        ]);
        if (result.exitCode != 0) {
          throw const FileSystemException('settings_permissions');
        }
      }
      await temporary.writeAsString(json, flush: true);
      await temporary.rename(_file.path);
    } finally {
      try {
        final File temporary = File('${staging.path}/data');
        if (await temporary.exists()) await temporary.delete();
        await staging.delete();
      } on FileSystemException {
        // 清理失败不能把已经完成的原子写入报告为失败。
      }
    }
  }
}

class SharedSettingsStore implements SettingsStore {
  SharedSettingsStore(this.bridge);

  /// Android 私有文件或 iOS App Group 的原生存储适配器。
  final WidgetBridge bridge;
  @override
  Future<String?> read() => bridge.readSettings();
  @override
  Future<void> write(String json) => bridge.writeSettings(json);
}

Future<SettingsStore> createSettingsStore(WidgetBridge bridge) async {
  if (bridge.supported) return SharedSettingsStore(bridge);
  final Directory directory = await getApplicationSupportDirectory();
  return LocalSettingsStore(Directory('${directory.path}/shiyu'));
}
