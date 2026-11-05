import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiyu/features/desktop_stickers/application/sticker_skin_actions.dart';
import 'package:shiyu/features/desktop_stickers/data/skins/sticker_skin_settings.dart';
import 'package:shiyu/features/desktop_stickers/data/skins/timer_pack.dart';
import 'package:shiyu/features/desktop_stickers/data/sticker_cat_pose.dart';
import 'package:shiyu/features/desktop_stickers/data/sticker_layout.dart';
import 'package:shiyu/features/desktop_stickers/data/sticker_palette.dart';

Future<void> verifyDesktopSkin(
  WidgetTester tester,
  StickerLayout layout,
  Directory directory,
) async {
  final StickerSkinActions actions = StickerSkinActions(layout);
  final int revision = layout.assetRevision;
  final Set<int> groups = layout.activeGroups;
  for (int index = 0; index < 100; index++) {
    await actions.change('skin', index.isEven ? 'darkTech' : 'stationery');
    await tester.pump();
  }
  expect(layout.assetRevision, revision);
  expect(layout.activeGroups, groups);
  if (!Platform.isWindows) return;

  // 经 Windows 的第二进程和 WM_COPYDATA 传入 Unicode 路径。
  final File file = File('${directory.path}/暖色.timerpack');
  final Uint8List bundle = TimerPack(
    const StickerSkinSettings(skin: StickerSkin.darkTech, opacity: 55),
    StickerPalette.sunset,
    <StickerCatPose, Uint8List>{},
  ).encode();
  await file.writeAsBytes(bundle);
  final ProcessResult opened = await Process.run(
    Platform.resolvedExecutable,
    <String>[file.path],
  );
  expect(opened.exitCode, 0);
  for (int attempt = 0; attempt < 50 && layout.skin.opacity != 55; attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 40));
    await tester.pump();
  }
  expect(layout.skin.skin, StickerSkin.darkTech);
  expect(layout.skin.opacity, 55);
  expect(layout.palette, StickerPalette.sunset);
  await actions.reset();
}
