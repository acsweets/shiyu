import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../sticker_cat_pose.dart';
import '../sticker_character.dart';
import '../sticker_palette.dart';
import 'sticker_skin_settings.dart';
import 'timer_pack.dart';
import 'timer_pack_zip.dart';

/// 皮肤和素材使用同一个原子指针，导入失败保留正在使用的版本。
class StickerAppearance {
  StickerAppearance(this.folder);

  final Directory folder;
  StickerSkinSettings skin = const StickerSkinSettings();
  StickerPalette? palette;
  String? _pack;
  Map<StickerCatPose, StickerCharacter> _characters =
      <StickerCatPose, StickerCharacter>{};

  File get _file => File('${folder.path}/skin.json');
  StickerCharacter? character(StickerCatPose pose) => _characters[pose];

  Future<void> load() async {
    if (!await _file.exists()) return;
    final Uint8List raw = await TimerPack.readFile(_file, limit: 4096);
    final Object? data = jsonDecode(utf8.decode(raw));
    if (data is! Map<String, Object?>) return;
    skin = StickerSkinSettings.read(data['skin']);
    if (data['palette'] != null) {
      palette = StickerPalette.fromId(data['palette']);
    }
    final Object? pack = data['pack'];
    if (pack is String && RegExp(r'^pack-[A-Za-z0-9_-]+$').hasMatch(pack)) {
      _pack = pack;
      _characters = await _read(Directory('${folder.path}/$pack'));
    }
  }

  Future<void> update(StickerSkinSettings next, StickerPalette colors) =>
      _save(next, colors, _pack, _characters);

  Future<void> reset() => _save(
    const StickerSkinSettings(),
    StickerPalette.macaron,
    null,
    <StickerCatPose, StickerCharacter>{},
  );

  Future<void> install(Uint8List raw) async {
    final TimerPack bundle = TimerPack.decode(raw);
    if (bundle.assets.isEmpty) {
      await _save(
        bundle.skin,
        bundle.palette,
        null,
        <StickerCatPose, StickerCharacter>{},
      );
      return;
    }
    await folder.create(recursive: true);
    final Directory stage = await folder.createTemp('pack-');
    try {
      for (final MapEntry<StickerCatPose, Uint8List> item
          in bundle.assets.entries) {
        await File('${stage.path}/${item.key.overrideFileName}')
            .writeAsBytes(item.value, flush: true);
      }
      final Map<StickerCatPose, StickerCharacter> characters = await _read(
        stage,
      );
      if (characters.length != bundle.assets.length) {
        throw const FormatException('timerpack_image');
      }
      final String name = stage.uri.pathSegments.reversed.firstWhere(
        (String segment) => segment.isNotEmpty,
      );
      await _save(bundle.skin, bundle.palette, name, characters);
    } catch (_) {
      await _remove(stage);
      rethrow;
    }
  }

  Future<Uint8List> export(
    StickerPalette colors,
    Map<StickerCatPose, StickerCharacter> characters,
  ) async {
    final Map<StickerCatPose, Uint8List> assets = <StickerCatPose, Uint8List>{
      for (final MapEntry<StickerCatPose, StickerCharacter> entry
          in characters.entries)
        entry.key: await TimerPack.readFile(
          entry.value.file,
          limit: TimerPackZip.maxFileBytes,
        ),
    };
    return TimerPack(skin, colors, assets).encode();
  }

  static Future<Map<StickerCatPose, StickerCharacter>> _read(
    Directory directory,
  ) async => <StickerCatPose, StickerCharacter>{
    for (final StickerCatPose pose in StickerCatPose.values)
      if (await StickerCharacter.read(
            File('${directory.path}/${pose.overrideFileName}'),
          )
          case final StickerCharacter image)
        pose: image,
  };

  Future<void> _save(
    StickerSkinSettings next,
    StickerPalette colors,
    String? pack,
    Map<StickerCatPose, StickerCharacter> characters,
  ) async {
    await folder.create(recursive: true);
    final File pending = File('${_file.path}.tmp');
    await pending.writeAsString(
      jsonEncode(<String, Object?>{
        'skin': next.data,
        'palette': colors.name,
        'pack': pack,
      }),
      flush: true,
    );
    await pending.rename(_file.path);
    final String? previous = _pack;
    skin = next;
    palette = colors;
    _pack = pack;
    _characters = characters;
    if (previous != null && previous != pack) {
      await _remove(Directory('${folder.path}/$previous'));
    }
  }

  static Future<void> _remove(Directory directory) async {
    try {
      if (await FileSystemEntity.type(directory.path, followLinks: false) !=
          FileSystemEntityType.directory) {
        return;
      }
      // 只删除已知槽位的文件，目录中若有其他文件则保留。
      for (final StickerCatPose pose in StickerCatPose.values) {
        final File file = File('${directory.path}/${pose.overrideFileName}');
        if (await file.exists()) await file.delete();
      }
      await directory.delete();
    } on FileSystemException {
      // 清理失败不影响已经保存的新皮肤。
    }
  }
}
