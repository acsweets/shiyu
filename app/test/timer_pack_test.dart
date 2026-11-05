import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiyu/features/desktop_stickers/application/sticker_skin_actions.dart';
import 'package:shiyu/features/desktop_stickers/data/skins/sticker_skin_settings.dart';
import 'package:shiyu/features/desktop_stickers/data/skins/timer_pack.dart';
import 'package:shiyu/features/desktop_stickers/data/skins/timer_pack_zip.dart';
import 'package:shiyu/features/desktop_stickers/data/sticker_cat_pose.dart';
import 'package:shiyu/features/desktop_stickers/data/sticker_layout.dart';
import 'package:shiyu/features/desktop_stickers/data/sticker_palette.dart';

const StickerSkinSettings _theme = StickerSkinSettings(
  skin: StickerSkin.darkTech,
  theme: StickerTheme.system,
  opacity: 65,
  scale: StickerScale.large,
  accent: 0xFF91B6E0,
);
const String _manifest = 'manifest.json';
const String _character = 'cats/character-1.png';
const String _deflated =
    'UEsDBBQAAAAIACuuZV2GphA2BwAAAAUAAAANAAAAbWFuaWZlc3QuanNvbstIzcnJBwBQ'
    'SwECFAAUAAAACAArrmVdhqYQNgcAAAAFAAAADQAAAAAAAAAAAAAAgAEAAAAAbWFuaWZl'
    'c3QuanNvblBLBQYAAAAAAQABADsAAAAyAAAAAAA=';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('读取标准 DEFLATE，拒绝实际解压体积超出声明', _deflate);
  test('拒绝不兼容清单、未声明素材、遍历、脚本、假图片和超大文件', _invalid);
  test('真实 PNG 导入、重启、导出往返、恢复和坏包回滚', _roundTrip);
}

void _deflate() {
  final Uint8List fixture = base64Decode(_deflated);
  expect(
    utf8.decode(TimerPackZip.read(fixture, <String>{_manifest})[_manifest]!),
    'hello',
  );
  final ByteData data = ByteData.sublistView(fixture);
  final int directory = data.getUint32(fixture.length - 6, Endian.little);
  data.setUint32(22, 1, Endian.little);
  data.setUint32(directory + 24, 1, Endian.little);
  expect(
    () => TimerPackZip.read(fixture, <String>{_manifest}),
    throwsFormatException,
  );
}

Uint8List _rawManifest({
  int version = 1,
  List<String> assets = const <String>[],
}) => Uint8List.fromList(
  utf8.encode(
    jsonEncode(<String, Object?>{
      'schema_version': version,
      'appearance': _theme.data,
      'palette': StickerPalette.cool.name,
      'assets': assets,
    }),
  ),
);

void _invalid() {
  for (final Map<String, Uint8List> files in <Map<String, Uint8List>>[
    <String, Uint8List>{_manifest: _rawManifest(version: 9)},
    <String, Uint8List>{
      _manifest: _rawManifest(assets: <String>[_character]),
    },
    for (final String path in <String>[
      '../escape.png',
      'cats/start.exe',
      _character,
    ])
      <String, Uint8List>{
        _manifest: _rawManifest(assets: <String>[path]),
        path: Uint8List(128),
      },
  ]) {
    expect(
      () => TimerPack.decode(TimerPackZip.write(files)),
      throwsFormatException,
    );
  }
  expect(
    () => TimerPack.decode(Uint8List(TimerPackZip.maxZipBytes + 1)),
    throwsFormatException,
  );
}

Future<void> _roundTrip() async {
  final Directory directory = await Directory.systemTemp.createTemp(
    'shiyu-skin-',
  );
  final StickerLayout layout = StickerLayout(directory: directory);
  addTearDown(() => directory.delete(recursive: true));
  addTearDown(layout.dispose);
  await layout.load();
  final Uint8List png = await File(StickerCatPose.sitting.asset).readAsBytes();
  final Uint8List raw = TimerPack(
    _theme,
    StickerPalette.cool,
    <StickerCatPose, Uint8List>{StickerCatPose.sitting: png},
  ).encode();
  final StickerSkinActions actions = StickerSkinActions(layout);
  await actions.install(raw);
  expect(layout.skin.data, _theme.data);
  final String? oldPath = layout.characterOf(0)?.file.path;
  expect(oldPath, isNotNull);
  expect(
    TimerPack.decode(await actions.export()).assets[StickerCatPose.sitting],
    png,
  );
  await expectLater(actions.install(Uint8List(30)), throwsFormatException);
  expect(layout.characterOf(0)?.file.path, oldPath);
  final StickerLayout restored = StickerLayout(directory: directory);
  addTearDown(restored.dispose);
  await restored.load();
  expect(restored.skin.data, _theme.data);
  expect(
    await FileSystemEntity.identical(
      restored.characterOf(0)!.file.path,
      oldPath!,
    ),
    isTrue,
  );
  await StickerSkinActions(restored).reset();
  expect(restored.skin.skin, StickerSkin.stationery);
  expect(restored.characterOf(0), isNull);
}
