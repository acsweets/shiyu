/// 每个窗口槽位对应一个稳定的猫猫姿态。
enum StickerCatPose {
  sitting('character.png'),
  stretching('character-stretch.png'),
  waving('character-wave.png'),
  sleeping('character-sleep.png');

  const StickerCatPose(this.fileName);

  /// 安装包内的独立透明图片文件名。
  final String fileName;

  String get asset => 'assets/stickers/$fileName';

  String get overrideFileName => 'character-${index + 1}.png';
}
