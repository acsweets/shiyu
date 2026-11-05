import 'dart:io';

import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

/// Windows 使用物理坐标跨屏，避免用出发屏幕的 DPI 解释目标屏幕位置。
class DesktopWindowBounds {
  static const MethodChannel _channel = MethodChannel('shiyu/placement');

  static Future<Rect> read() async {
    if (!Platform.isWindows) return windowManager.getBounds();
    final List<double> values = (await _channel.invokeListMethod<double>(
      'read',
    ))!;
    return Rect.fromLTWH(values[0], values[1], values[2], values[3]);
  }

  static Future<void> write(Rect bounds) => Platform.isWindows
      ? _channel.invokeMethod<void>('write', <double>[
          bounds.left,
          bounds.top,
          bounds.width,
          bounds.height,
        ])
      : windowManager.setBounds(bounds);

  static Future<Offset> cursor() async {
    final List<double> values = (await _channel.invokeListMethod<double>(
      'cursor',
    ))!;
    return Offset(values[0], values[1]);
  }

  static Future<void> move(Offset point) =>
      _channel.invokeMethod<void>('move', <double>[point.dx, point.dy]);

  static Future<void> show({required bool inactive}) => Platform.isWindows
      ? _channel.invokeMethod<void>('show', inactive)
      : windowManager.show(inactive: inactive);
}
