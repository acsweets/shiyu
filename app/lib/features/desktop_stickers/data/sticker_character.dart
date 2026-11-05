import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart' show FileImage;

/// 自定义贴纸及用于定位的底部透明留白。
class StickerCharacter {
  const StickerCharacter(this.file, this.bottomInset);

  /// 用户目录中的源图片。
  final File file;

  /// 底部透明留白占源图长边的比例。
  final double bottomInset;

  /// 重新载入时测量缩略图，窗口刷新时直接复用结果。
  static Future<StickerCharacter?> read(File file) async {
    try {
      if (!await file.exists() || await file.length() > 8 * 1024 * 1024) {
        return null;
      }
      final double? inset = await _measureBottomInset(file);
      if (inset == null) return null;
      await FileImage(file).evict();
      return StickerCharacter(file, inset);
    } catch (_) {
      return null;
    }
  }

  static Future<double?> _measureBottomInset(File file) async {
    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromFilePath(
      file.path,
    );
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      const int sampleSize = 256;
      final int edge = math.max(descriptor.width, descriptor.height);
      codec = await descriptor.instantiateCodec(
        targetWidth: math.max(1, descriptor.width * sampleSize ~/ edge),
        targetHeight: math.max(1, descriptor.height * sampleSize ~/ edge),
      );
      image = (await codec.getNextFrame()).image;
      return await _bottomInsetOf(image);
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
  }

  static Future<double?> _bottomInsetOf(ui.Image image) async {
    final ByteData? pixels = await image.toByteData();
    if (pixels == null) return null;
    final int rowBytes = image.width * 4;
    final int edge = math.max(image.width, image.height);
    int strongestAlpha = 0;
    int strongestRow = 0;
    for (int row = image.height - 1; row >= 0; row--) {
      final int end = (row + 1) * rowBytes;
      for (int alpha = row * rowBytes + 3; alpha < end; alpha += 4) {
        final int opacity = pixels.getUint8(alpha);
        if (opacity >= 128) return (image.height - row - 1) / edge;
        if (opacity > strongestAlpha) {
          strongestAlpha = opacity;
          strongestRow = row;
        }
      }
    }
    return strongestAlpha == 0
        ? null
        : (image.height - strongestRow - 1) / edge;
  }
}
