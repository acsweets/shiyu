import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../../platform/desktop/desktop_window_bounds.dart';

/// Windows 按屏幕指针移动，避免拖动过程中窗口坐标变化产生反向位移。
class StickerWindowDrag extends StatefulWidget {
  const StickerWindowDrag({required this.child, this.onSettled, super.key});

  /// 浮窗内可拖动的区域。
  final Widget child;
  final VoidCallback? onSettled;

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
  bool _finished = false;

  /// 避免窗口移动触发的同位置鼠标事件重复写入。
  Offset? _lastPosition;

  void _start(DragStartDetails details) {
    _finished = false;
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
        final Offset cursor = await DesktopWindowBounds.cursor();
        if (!mounted) return;
        final Offset position =
            cursor - _anchor * View.of(context).devicePixelRatio;
        if (position == _lastPosition) continue;
        _lastPosition = position;
        await DesktopWindowBounds.move(position);
      }
    } finally {
      _moving = false;
      _notifySettled();
    }
  }

  void _end(DragEndDetails details) {
    _finished = true;
    _notifySettled();
  }

  void _notifySettled() {
    if (_moving || !_finished || !mounted) return;
    _finished = false;
    widget.onSettled?.call();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    dragStartBehavior: DragStartBehavior.down,
    onPanStart: _start,
    onPanUpdate: _update,
    onPanEnd: _end,
    child: widget.child,
  );
}
