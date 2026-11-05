import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../sticker_cat_pose.dart';
import '../sticker_palette.dart';
import 'sticker_skin_settings.dart';
import 'timer_pack_zip.dart';

/// 资源包只携带外观与槽位图片。
class TimerPack {
  const TimerPack(this.skin, this.palette, this.assets);

  final StickerSkinSettings skin;
  final StickerPalette palette;
  final Map<StickerCatPose, Uint8List> assets;
  static const String _manifest = 'manifest.json';
  static const int _manifestLimit = 16384;

  static String _path(StickerCatPose pose) => 'cats/${pose.overrideFileName}';

  static Future<Uint8List> readFile(File file, {int? limit}) async {
    final int maximum = limit ?? TimerPackZip.maxZipBytes;
    final RandomAccessFile input = await file.open();
    try {
      if (await input.length() > maximum) _bad();
      final Uint8List data = await input.read(maximum + 1);
      if (data.length > maximum) _bad();
      return data;
    } finally {
      await input.close();
    }
  }

  factory TimerPack.decode(Uint8List bytes) {
    final Map<String, Uint8List> files = TimerPackZip.read(bytes, <String>{
      _manifest,
      'cats/',
      ...StickerCatPose.values.map(_path),
    });
    final Uint8List? manifest = files.remove(_manifest);
    if (manifest == null ||
        manifest.length > _manifestLimit ||
        files.remove('cats/')?.isNotEmpty == true) {
      _bad();
    }
    final Object? data = jsonDecode(utf8.decode(manifest));
    if (data is! Map<String, Object?> ||
        data.length != 4 ||
        data['schema_version'] is! int ||
        data['schema_version'] != 1) {
      _bad();
    }
    final Object? appearance = data['appearance'];
    final StickerSkinSettings skin = StickerSkinSettings.read(appearance);
    final StickerPalette palette = StickerPalette.fromId(data['palette']);
    final Object? declared = data['assets'];
    if (appearance is! Map<String, Object?> ||
        !mapEquals(appearance, skin.data) ||
        appearance['opacity'] is! int ||
        (appearance['accent'] != null && appearance['accent'] is! int) ||
        palette.name != data['palette'] ||
        declared is! List<Object?> ||
        declared.length != files.length ||
        declared.toSet().length != files.length ||
        !files.keys.every(declared.contains)) {
      _bad();
    }
    final Map<StickerCatPose, Uint8List> assets = <StickerCatPose, Uint8List>{
      for (final StickerCatPose pose in StickerCatPose.values)
        if (files[_path(pose)] case final Uint8List image) pose: image,
    };
    for (final Uint8List image in assets.values) {
      _checkPng(image);
    }
    return TimerPack(skin, palette, assets);
  }

  Uint8List encode() {
    int total = 0;
    for (final Uint8List image in assets.values) {
      total += image.length;
      _checkPng(image);
    }
    final Uint8List manifest = Uint8List.fromList(
      utf8.encode(
        jsonEncode(<String, Object?>{
          'schema_version': 1,
          'appearance': skin.data,
          'palette': palette.name,
          'assets': assets.keys.map(_path).toList(),
        }),
      ),
    );
    if (total + manifest.length > TimerPackZip.maxDecodedBytes) _bad();
    return TimerPackZip.write(<String, Uint8List>{
      _manifest: manifest,
      for (final MapEntry<StickerCatPose, Uint8List> asset in assets.entries)
        _path(asset.key): asset.value,
    });
  }

  /// 校验单帧 PNG 的文件头、尺寸和块边界，再交给平台解码器。
  static void _checkPng(Uint8List image) {
    if (image.length < 45 || image.length > TimerPackZip.maxFileBytes) _bad();
    final ByteData data = ByteData.sublistView(image);
    if (data.getUint32(0) != 0x89504e47 ||
        data.getUint32(4) != 0x0d0a1a0a ||
        data.getUint32(8) != 13 ||
        data.getUint32(12) != 0x49484452 ||
        !_dimension(data.getUint32(16)) ||
        !_dimension(data.getUint32(20))) {
      _bad();
    }
    for (int offset = 8; offset + 12 <= image.length;) {
      final int length = data.getUint32(offset);
      final int kind = data.getUint32(offset + 4);
      offset += 12 + length;
      if (offset > image.length || kind == 0x6163544c) _bad();
      if (kind == 0x49454e44 && length == 0 && offset == image.length) return;
    }
    _bad();
  }

  static bool _dimension(int value) => value >= 1 && value <= 2048;
  static Never _bad() => throw const FormatException('timerpack');
}
