import 'package:flutter/material.dart';

import '../data/sticker_layout.dart';

typedef StickerMoved = void Function(Offset delta);

/// 单张贴纸只呈现标题和完整时间；角色保持独立图片，便于替换。
class CountdownSticker extends StatelessWidget {
  const CountdownSticker({
    required this.id,
    required this.title,
    required this.value,
    required this.main,
    required this.preview,
    required this.layout,
    required this.onMove,
    required this.onEnd,
    super.key,
  });

  /// 稳定指标标识。
  final String id;

  /// 上方标题。
  final String title;

  /// 一行连贯的时间或状态。
  final String value;

  /// 当前是否为主贴纸。
  final bool main;

  /// 示例必须明确标记。
  final bool preview;

  /// 独立外观与资源状态。
  final StickerLayout layout;

  /// 画布坐标移动回调。
  final StickerMoved onMove;

  /// 拖动结束后保存。
  final VoidCallback onEnd;

  /// 所有贴纸统一使用的深棕文字。
  static const Color ink = Color(0xFF59483E);

  /// 内置透明角色文件。
  static const String catAsset = 'assets/stickers/character.png';

  void _update(DragUpdateDetails details) => onMove(details.delta);
  void _end(DragEndDetails details) => onEnd();
  Widget _catFallback(BuildContext context, Object error, StackTrace? stack) =>
      Image.asset(catAsset, fit: BoxFit.contain);

  Widget _cat() {
    if (layout.character == null) {
      return Image.asset(catAsset, fit: BoxFit.contain);
    }
    return Image.file(
      layout.character!,
      key: ValueKey<int>(layout.assetRevision),
      fit: BoxFit.contain,
      errorBuilder: _catFallback,
      cacheWidth: 420,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color paper = switch (id) {
      'holiday' => const Color(0xFFF5EEF9),
      'payday' => const Color(0xFFEFF3FC),
      'retirement' => const Color(0xFFFFF0E3),
      _ => const Color(0xFFFFF8E9),
    };
    return GestureDetector(
      key: ValueKey<String>('sticker-$id'),
      behavior: HitTestBehavior.opaque,
      onPanUpdate: _update,
      onPanEnd: _end,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            left: 0,
            right: 0,
            top: main ? 102 : 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: paper,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(main ? 28 : 22),
                  topRight: const Radius.circular(18),
                  bottomLeft: const Radius.circular(18),
                  bottomRight: const Radius.circular(30),
                ),
                border: Border.all(
                  color: const Color(0xFF806856),
                  width: main ? 2 : 1.5,
                ),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x205B4231),
                    offset: Offset(0, 5),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      if (main)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Color(0xFFC2854F),
                          ),
                        ),
                      Text(
                        title,
                        style: TextStyle(
                          color: ink,
                          fontSize: main ? 16 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (preview)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Text(
                            '示例',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF947E70),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: main ? 36 : 28,
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value,
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          color: ink,
                          fontSize: main ? 23 : 18,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (main)
            Positioned(
              top: 0,
              left: 82,
              right: 82,
              height: 132,
              child: IgnorePointer(child: _cat()),
            ),
        ],
      ),
    );
  }
}
