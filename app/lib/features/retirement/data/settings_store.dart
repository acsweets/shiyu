import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../platform/widgets/widget_bridge.dart';

abstract interface class SettingsStore {
  Future<String?> read();
  Future<void> write(String json);
}

class LocalSettingsStore implements SettingsStore {
  LocalSettingsStore(this.directory);

  /// 仅保存在当前用户应用数据目录，测试可传入临时目录。
  final Directory directory;
  File get _file => File('${directory.path}/settings.json');

  @override
  Future<String?> read() async =>
      await _file.exists() ? _file.readAsString() : null;

  /// 同目录写临时文件后原子替换，失败时保留原文件。
  @override
  Future<void> write(String json) async {
    await directory.create(recursive: true);
    final File temporary = File('${_file.path}.tmp');
    await temporary.writeAsString(json, flush: true);
    await temporary.rename(_file.path);
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
