/// 每个窗口槽位对应一个稳定的猫猫姿态。
enum StickerCatPose {
  sitting('character.png', 114 / 1254),
  stretching('character-stretch.png', 103 / 1254),
  waving('character-wave.png', 36 / 1254),
  sleeping('character-sleep.png', 212 / 1254);

  const StickerCatPose(this.fileName, this.bottomInset);

  /// 安装包内的独立透明图片文件名。
  final String fileName;

  /// 原稿中角色轮廓下方的透明像素占长边的比例。
  final double bottomInset;

  String get asset => 'assets/stickers/$fileName';

  String get overrideFileName => 'character-${index + 1}.png';
}
