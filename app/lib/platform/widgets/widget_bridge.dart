import 'dart:io';

import 'package:flutter/services.dart';

/// 只负责共享数据与系统刷新请求，业务值始终由 Rust 计算。
class WidgetBridge {
  /// 原生共享设置和组件控制通道。
  static const MethodChannel _channel = MethodChannel('shiyu/widgets');

  bool get supported => Platform.isAndroid || Platform.isIOS;
  bool get offersPin => Platform.isAndroid;

  /// 原生小组件独立读取的外观配置。
  Future<String?> readAppearance() =>
      _channel.invokeMethod<String>('readAppearance');

  /// 原子写入外观并请求刷新已添加的小组件。
  Future<void> writeAppearance(String json) =>
      _channel.invokeMethod<void>('writeAppearance', json);

  Future<String?> readSettings() =>
      _channel.invokeMethod<String>('readSettings');
  Future<void> writeSettings(String json) =>
      _channel.invokeMethod<void>('writeSettings', json);
  Future<void> refresh() async {
    if (supported) await _channel.invokeMethod<void>('refresh');
  }

  Future<bool> pin() async {
    if (!offersPin) return false;
    return await _channel.invokeMethod<bool>('pin') ?? false;
  }
}
