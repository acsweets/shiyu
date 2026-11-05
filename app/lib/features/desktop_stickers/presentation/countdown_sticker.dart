import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../application/sticker_group_view.dart';
import '../data/sticker_layout.dart';
import 'sticker_window_drag.dart';

/// 每个系统窗口使用相同的贴纸排版和缩放入口。
class StickerGroupSurface extends StatelessWidget {
  const StickerGroupSurface({required this.view, this.onSettings, super.key});

  /// 当前分组的可见状态与完整计时。
  final StickerGroupView view;

  /// 设置图标只在主窗出现。
  final VoidCallback? onSettings;

  Widget _builtInCat() =>
      Image.asset(view.catAsset, fit: BoxFit.contain, cacheWidth: 384);

  Widget _fallback(BuildContext context, Object error, StackTrace? stack) =>
      _builtInCat();

  Widget _cat() {
    final File? character = view.character;
    if (character == null) return _builtInCat();
    return Image.file(
      character,
      key: ValueKey<int>(view.assetRevision),
      fit: BoxFit.contain,
      errorBuilder: _fallback,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    body: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        StickerWindowDrag(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: LayoutBuilder(builder: _surface),
          ),
        ),
        const Positioned(right: 0, bottom: 0, child: _ResizeGrip()),
      ],
    ),
  );

  Widget _surface(BuildContext context, BoxConstraints constraints) {
    final double catHeight = (constraints.maxHeight - 64)
        .clamp(0, 96)
        .toDouble();
    return Column(
      children: <Widget>[
        SizedBox(
          height: catHeight,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox.square(dimension: catHeight, child: _cat()),
              ),
              if (onSettings != null)
                Positioned(
                  right: 2,
                  bottom: 4,
                  child: IconButton.filled(
                    tooltip: '浮窗设置',
                    onPressed: onSettings,
                    style: IconButton.styleFrom(
                      backgroundColor: view.background,
                      foregroundColor: view.foreground,
                      minimumSize: const Size(34, 34),
                      padding: EdgeInsets.zero,
                    ),
                    icon: const Icon(Icons.tune_rounded, size: 18),
                  ),
                ),
            ],
          ),
        ),
        Expanded(child: _paper()),
      ],
    );
  }

  Widget _paper() => DecoratedBox(
    key: const ValueKey<String>('sticker-window-background'),
    decoration: BoxDecoration(
      color: view.background,
      border: Border.all(
        color: Color.alphaBlend(
          view.foreground.withValues(alpha: 0.30),
          view.background,
        ),
      ),
      borderRadius: BorderRadius.circular(18),
    ),
    child: LayoutBuilder(builder: _grid),
  );

  Widget _grid(BuildContext context, BoxConstraints constraints) {
    final List<String> ids = view.values.keys.toList();
    if (ids.isEmpty) return const SizedBox.shrink();
    final int columns = (constraints.maxWidth ~/ 230).clamp(1, ids.length);
    final int rows = (ids.length + columns - 1) ~/ columns;
    final double rowHeight = ((constraints.maxHeight - rows * 8) / rows)
        .clamp(56, double.infinity)
        .toDouble();
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: ids.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisExtent: rowHeight,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (BuildContext context, int index) => _card(ids[index]),
      ),
    );
  }

  Widget _card(String id) => Padding(
    key: ValueKey<String>('sticker-$id'),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (view.showsTitle)
          SizedBox(
            height: 18,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                StickerLayout.titles[id]!,
                style: TextStyle(fontSize: 13, color: view.foreground),
              ),
            ),
          ),
        SizedBox(
          height: 28,
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              view.values[id]!,
              semanticsLabel: view.preview ? '示例倒计时 ${view.values[id]!}' : null,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                color: view.foreground,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ],
    ),
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
      child: const SizedBox(width: 24, height: 20),
    ),
  );
}
