import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

/// Windows 按屏幕指针移动，避免拖动过程中窗口坐标变化产生反向位移。
class StickerWindowDrag extends StatefulWidget {
  const StickerWindowDrag({required this.child, super.key});

  /// 浮窗内可拖动的区域。
  final Widget child;

  @override
  State<StickerWindowDrag> createState() => _StickerWindowDragState();
}

class _StickerWindowDragState extends State<StickerWindowDrag> {
  /// 指针在按下时距窗口左上角的距离。
  Offset _anchor = Offset.zero;

  /// 新的指针位置等待处理。
  bool _pending = false;

  /// 原生窗口位置更新进行中。
  bool _moving = false;

  /// 避免窗口移动触发的同位置鼠标事件重复写入。
  Offset? _lastPosition;

  void _start(DragStartDetails details) {
    if (!Platform.isWindows) {
      unawaited(windowManager.startDragging());
      return;
    }
    _anchor = details.globalPosition;
    _lastPosition = null;
  }

  void _update(DragUpdateDetails details) {
    if (!Platform.isWindows) return;
    _pending = true;
    if (!_moving) unawaited(_move());
  }

  Future<void> _move() async {
    _moving = true;
    try {
      while (mounted && _pending) {
        _pending = false;
        final Offset cursor = await screenRetriever.getCursorScreenPoint();
        final Offset position = cursor - _anchor;
        if (position == _lastPosition) continue;
        _lastPosition = position;
        await windowManager.setPosition(position);
      }
    } finally {
      _moving = false;
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    dragStartBehavior: DragStartBehavior.down,
    onPanStart: _start,
    onPanUpdate: _update,
    child: widget.child,
  );
}
