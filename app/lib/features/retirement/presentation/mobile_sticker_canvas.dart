import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/mobile_appearance.dart';
import '../domain/retirement_snapshot.dart';
import 'retirement_card.dart';

typedef StickerPositionChanged = void Function(Alignment position);

/// 可滚动的安全区域内，使用相对坐标移动整张贴纸。
class MobileStickerCanvas extends StatelessWidget {
  const MobileStickerCanvas({
    required this.appearance,
    required this.snapshot,
    required this.onPositionChanged,
    super.key,
  });

  /// 外观包含持久化的浮窗位置。
  final MobileAppearance appearance;

  /// 可见期间持续更新的 Rust 快照。
  final RetirementSnapshot? snapshot;

  /// 拖动结束后才落盘。
  final StickerPositionChanged onPositionChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _buildCanvas);

  Widget _buildCanvas(BuildContext context, BoxConstraints constraints) {
    final double height = math.max(290, constraints.maxHeight);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height),
        child: SizedBox(
          width: double.infinity,
          child: _DraggableSticker(
            appearance: appearance,
            snapshot: snapshot,
            onPositionChanged: onPositionChanged,
          ),
        ),
      ),
    );
  }
}

class _DraggableSticker extends StatefulWidget {
  const _DraggableSticker({
    required this.appearance,
    required this.snapshot,
    required this.onPositionChanged,
  });

  final MobileAppearance appearance;
  final RetirementSnapshot? snapshot;
  final StickerPositionChanged onPositionChanged;

  @override
  State<_DraggableSticker> createState() => _DraggableStickerState();
}

class _DraggableStickerState extends State<_DraggableSticker> {
  /// 读取真实卡片尺寸，让长标题、大字号和小屏仍能正确限制拖动范围。
  final GlobalKey _cardKey = GlobalKey();

  /// 拖动中的位置暂存到本地界面，避免逐帧写文件。
  Alignment? _dragPosition;

  @override
  Widget build(BuildContext context) => Align(
    alignment: _dragPosition ?? widget.appearance.position,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 326),
      child: GestureDetector(
        key: _cardKey,
        onPanUpdate: _move,
        onPanEnd: _finish,
        onPanCancel: _commitPosition,
        child: RetirementCard(
          snapshot: widget.snapshot,
          appearance: widget.appearance,
        ),
      ),
    ),
  );

  void _move(DragUpdateDetails details) {
    final Size? card = _cardKey.currentContext?.size;
    final Size? canvas = context.size;
    if (card == null || canvas == null) return;
    final Alignment current = _dragPosition ?? widget.appearance.position;
    final Alignment next = Alignment(
      _shift(current.x, details.delta.dx, canvas.width - card.width),
      _shift(current.y, details.delta.dy, canvas.height - card.height),
    );
    setState(() => _dragPosition = next);
  }

  double _shift(double value, double delta, double extent) {
    if (extent <= 0) return value;
    return (value + 2 * delta / extent).clamp(-1, 1).toDouble();
  }

  void _finish(DragEndDetails details) => _commitPosition();

  void _commitPosition() {
    final Alignment? position = _dragPosition;
    if (position == null) return;
    widget.onPositionChanged(position);
    setState(() => _dragPosition = null);
  }
}
