import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../retirement/presentation/metrics/snapshot_metrics.dart';
import '../application/sticker_group_view.dart';
import '../data/sticker_layout.dart';
import '../data/sticker_mode.dart';
import 'sticker_window_drag.dart';
import 'sticker_surface_style.dart';

/// 每个系统窗口使用相同的贴纸排版和缩放入口。
class StickerGroupSurface extends StatelessWidget {
  const StickerGroupSurface({
    required this.view,
    this.onSettings,
    this.onToggleMode,
    this.onDragSettled,
    this.interactive = true,
    super.key,
  });

  /// 当前分组的可见状态与完整计时。
  final StickerGroupView view;

  /// 设置图标只在主窗出现。
  final VoidCallback? onSettings;
  final VoidCallback? onToggleMode;
  final VoidCallback? onDragSettled;

  /// 设置页预览只绘制内容，禁用系统窗口拖动和缩放。
  final bool interactive;

  /// 时间行保持独立高度，标题变大时只增加所需空间。
  static const double _timeHeight = 28;

  /// 卡片网格和每项内容的纵向留白。
  static const double _gridSpacing = 8;
  static const double _cellPadding = 4;

  double get _titleHeight =>
      view.showsTitle ? math.max(18, view.titleSize * 1.25) : 0;

  double get _minimumRowHeight =>
      math.max(56, _titleHeight + _timeHeight + 2 * _cellPadding) +
      (view.mode.showsDetails ? 36 : 0);

  /// 让角色轮廓压住卡片上沿两个逻辑像素。
  Widget _anchorCat(double size, double bottomInset, Widget image) =>
      Transform.translate(
        offset: Offset(0, size * bottomInset + 2),
        child: image,
      );

  Widget _builtInCat(double size) => _anchorCat(
    size,
    view.catBottomInset,
    Image.asset(view.catAsset, fit: BoxFit.contain, cacheWidth: 384),
  );

  Widget _cat(double size) {
    final File? character = view.character;
    if (character == null) return _builtInCat(size);
    return Image.file(
      character,
      key: ValueKey<int>(view.assetRevision),
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      frameBuilder: (
        BuildContext context,
        Widget child,
        int? frame,
        bool synchronous,
      ) => _anchorCat(size, view.characterBottomInset!, child),
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
          _builtInCat(size),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget surface = Padding(
      padding: const EdgeInsets.all(4),
      child: LayoutBuilder(builder: _surface),
    );
    if (!interactive) return surface;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          StickerWindowDrag(onSettled: onDragSettled, child: surface),
          const Positioned(right: 0, bottom: 0, child: _ResizeGrip()),
        ],
      ),
    );
  }

  Widget _surface(BuildContext context, BoxConstraints constraints) {
    final StickerSurfaceStyle style = StickerSurfaceStyle(
      view,
      MediaQuery.platformBrightnessOf(context),
    );
    final double catHeight =
        (constraints.maxHeight - _minimumRowHeight - _gridSpacing)
            .clamp(0, 96)
            .toDouble();
    return Stack(
      children: <Widget>[
        Positioned.fill(
          top: catHeight,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTap: interactive ? onToggleMode : null,
            child: _paper(style),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: catHeight,
          child: Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: <Widget>[
              Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox.square(
                  dimension: catHeight,
                  child: _cat(catHeight),
                ),
              ),
              if (onSettings != null)
                Positioned(
                  right: 2,
                  bottom: 4,
                  child: IconButton.filled(
                    tooltip: '浮窗设置',
                    onPressed: onSettings,
                    style: IconButton.styleFrom(
                      backgroundColor: style.fill,
                      foregroundColor: style.foreground,
                      minimumSize: const Size(34, 34),
                      padding: EdgeInsets.zero,
                    ),
                    icon: const Icon(Icons.tune_rounded, size: 18),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _paper(StickerSurfaceStyle style) => DecoratedBox(
    key: const ValueKey<String>('sticker-window-background'),
    decoration: BoxDecoration(
      color: style.background,
      border: Border.all(color: style.border),
      borderRadius: BorderRadius.circular(style.radius),
    ),
    child: Column(
      children: <Widget>[
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints limits) =>
                _grid(context, limits, style),
          ),
        ),
        if (view.mode.showsDetails && view.fallback != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
            child: Text(
              view.fallback!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: style.foreground, fontSize: 11),
            ),
          ),
      ],
    ),
  );

  Widget _grid(
    BuildContext context,
    BoxConstraints constraints,
    StickerSurfaceStyle style,
  ) {
    final Map<String, MetricFields> metrics = view.metrics;
    final List<String> ids = metrics.keys.toList();
    if (ids.isEmpty) {
      return Center(
        child: Text(view.emptyLabel, style: TextStyle(color: style.foreground)),
      );
    }
    final int columns = !view.preview && view.mode == StickerMode.mini
        ? 1
        : (constraints.maxWidth ~/ 230).clamp(1, ids.length);
    final int rows = (ids.length + columns - 1) ~/ columns;
    final double rowHeight = math.max(
      _minimumRowHeight,
      (constraints.maxHeight - rows * _gridSpacing) / rows,
    );
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: GridView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: style.inset,
          vertical: _gridSpacing / 2,
        ),
        itemCount: ids.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisExtent: rowHeight,
          crossAxisSpacing: 8,
          mainAxisSpacing: _gridSpacing,
        ),
        itemBuilder: (BuildContext context, int index) =>
            _card(ids[index], metrics[ids[index]]!, style),
      ),
    );
  }

  Widget _card(
    String id,
    MetricFields metric,
    StickerSurfaceStyle style,
  ) => Padding(
    key: ValueKey<String>('sticker-$id'),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: _cellPadding),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (view.showsTitle)
          SizedBox(
            height: _titleHeight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                metric['title'] as String,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: view.titleSize,
                  height: 1.25,
                  color: style.foreground,
                ),
              ),
            ),
          ),
        SizedBox(
          height: _timeHeight,
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              metric['value'] as String,
              semanticsLabel: view.preview ? '示例倒计时 ${metric['value']}' : null,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                color: style.foreground,
                fontSize: style.valueSize,
                fontWeight: FontWeight.w700,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        if (view.mode.showsDetails) ...<Widget>[
          if (metric['progress'] case final double progress)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: LinearProgressIndicator(
                value: progress,
                color: style.accent,
                minHeight: 3,
              ),
            ),
          if (metric['detail'] case final String detail)
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: style.foreground, fontSize: 11),
            ),
        ],
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
