import 'dart:async';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../application/sticker_group_view.dart';
import '../data/sticker_layout.dart';
import 'sticker_window_drag.dart';

/// 每个系统窗口使用相同的贴纸排版和缩放入口。
class StickerGroupSurface extends StatelessWidget {
  const StickerGroupSurface({
    required this.view,
    required this.onSettings,
    required this.onHide,
    super.key,
  });

  /// 当前分组的可见状态与完整计时。
  final StickerGroupView view;

  /// 打开全局设置。
  final VoidCallback onSettings;

  /// 隐藏本窗或全组。
  final VoidCallback onHide;

  /// 暖棕色正文。
  static const Color ink = Color(0xFF59483E);

  /// 内置独立猫猫图。
  static const String catAsset = 'assets/stickers/character.png';

  Widget _fallback(BuildContext context, Object error, StackTrace? stack) =>
      Image.asset(catAsset, fit: BoxFit.contain);

  Widget _cat() {
    if (view.character == null) {
      return Image.asset(catAsset, fit: BoxFit.contain);
    }
    return Image.file(
      view.character!,
      key: ValueKey<int>(view.assetRevision),
      fit: BoxFit.contain,
      errorBuilder: _fallback,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    body: Padding(
      padding: const EdgeInsets.all(4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF4),
          border: Border.all(color: const Color(0xFF806856)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 38,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: StickerWindowDrag(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.drag_indicator,
                              size: 17,
                              color: ink,
                            ),
                            if (view.showsTitle)
                              const Text('时余', style: TextStyle(color: ink)),
                            if (view.preview)
                              const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Text(
                                  '示例',
                                  style: TextStyle(fontSize: 11, color: ink),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _tool(Icons.tune_rounded, '浮窗设置', onSettings),
                  _tool(Icons.close, '隐藏浮窗', onHide),
                ],
              ),
            ),
            Expanded(child: LayoutBuilder(builder: _grid)),
            const Align(alignment: Alignment.bottomRight, child: _ResizeGrip()),
          ],
        ),
      ),
    ),
  );

  Widget _grid(BuildContext context, BoxConstraints constraints) {
    final List<String> ids = view.values.keys.toList();
    if (ids.isEmpty) return const SizedBox.shrink();
    final int columns = (constraints.maxWidth ~/ 230).clamp(1, ids.length);
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: ids.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisExtent: 76,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (BuildContext context, int index) => _card(ids[index]),
    );
  }

  Widget _card(String id) {
    final Color paper = switch (id) {
      'holiday' => const Color(0xFFF5EEF9),
      'payday' => const Color(0xFFEFF3FC),
      'retirement' => const Color(0xFFFFF0E3),
      _ => const Color(0xFFFFF2D8),
    };
    return Container(
      key: ValueKey<String>('sticker-$id'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: <Widget>[
          if (id == view.main) SizedBox(width: 50, height: 54, child: _cat()),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (view.showsTitle)
                  Text(
                    StickerLayout.titles[id]!,
                    style: const TextStyle(fontSize: 13, color: ink),
                  ),
                SizedBox(
                  height: 29,
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      view.values[id]!,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        color: ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFeatures: <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tool(IconData icon, String tooltip, VoidCallback action) =>
      IconButton(
        tooltip: tooltip,
        onPressed: action,
        icon: Icon(icon, size: 17, color: ink),
      );
}

/// 从右下角缩放，合并连续鼠标事件以免原生消息堆积。
class _ResizeGrip extends StatefulWidget {
  const _ResizeGrip();

  @override
  State<_ResizeGrip> createState() => _ResizeGripState();
}

class _ResizeGripState extends State<_ResizeGrip> {
  /// 开始拖动时的窗口尺寸与指针位置。
  late Size _startSize;

  /// 与窗口左上角的相对位置，缩放过程中左上角保持固定。
  late Offset _startPointer;

  /// 待发送的最新尺寸。
  Size? _target;

  /// 同一时刻只发送一次原生尺寸更新。
  bool _applying = false;

  void _begin(DragStartDetails details) {
    _startSize = MediaQuery.sizeOf(context);
    _startPointer = details.globalPosition;
  }

  void _update(DragUpdateDetails details) {
    final Offset delta = details.globalPosition - _startPointer;
    _target = Size(
      (_startSize.width + delta.dx)
          .clamp(StickerLayout.minimum.width, 4096)
          .toDouble(),
      (_startSize.height + delta.dy)
          .clamp(StickerLayout.minimum.height, 4096)
          .toDouble(),
    );
    if (!_applying) unawaited(_apply());
  }

  Future<void> _apply() async {
    _applying = true;
    try {
      while (mounted && _target != null) {
        final Size size = _target!;
        _target = null;
        await windowManager.setSize(size);
      }
    } finally {
      _applying = false;
    }
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.resizeDownRight,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: _begin,
      onPanUpdate: _update,
      child: const Tooltip(
        message: '拖动缩放浮窗',
        child: SizedBox(
          width: 26,
          height: 20,
          child: Icon(
            Icons.drag_handle,
            size: 15,
            color: StickerGroupSurface.ink,
          ),
        ),
      ),
    ),
  );
}
