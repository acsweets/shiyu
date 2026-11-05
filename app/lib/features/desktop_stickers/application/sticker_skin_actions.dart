import 'dart:io';
import 'dart:typed_data';

import '../data/skins/sticker_appearance.dart';
import '../data/skins/sticker_skin_settings.dart';
import '../data/skins/timer_pack.dart';
import '../data/sticker_cat_pose.dart';
import '../data/sticker_character.dart';
import '../data/sticker_layout.dart';
import '../data/sticker_palette.dart';

typedef SkinOperation<T> = Future<T> Function(StickerAppearance appearance);

/// 系统打开与设置面板共用队列，保护外观文件和当前素材。
class StickerSkinActions {
  StickerSkinActions(this.layout);

  final StickerLayout layout;
  Future<void> _pending = Future<void>.value();

  Future<void> setPalette(StickerPalette palette) =>
      layout.directory == null && layout.ready
      ? layout.setPalette(palette)
      : _enqueue<void>((StickerAppearance _) => layout.setPalette(palette));

  Future<void> change(String key, Object? value) => _enqueue<void>(
    (StickerAppearance appearance) => _change(appearance, key, value),
  );

  Future<void> _change(
    StickerAppearance appearance,
    String key,
    Object? value,
  ) async {
    final StickerSkinSettings next = StickerSkinSettings.read(<String, Object?>{
      ...layout.skin.data,
      if (key == 'skin')
        'theme': value == StickerSkin.darkTech.name ? 'dark' : 'light',
      key: value,
    });
    await appearance.update(next, layout.palette);
    layout.appearanceChanged();
  }

  Future<void> install(Object? source) => _enqueue<void>(
    (StickerAppearance appearance) => _install(appearance, source),
  );

  Future<void> _install(StickerAppearance appearance, Object? source) async {
    final Uint8List raw = switch (source) {
      final Uint8List bytes => bytes,
      final String path when path.toLowerCase().endsWith('.timerpack') =>
        await TimerPack.readFile(File(path)),
      _ => throw const FormatException('timerpack_source'),
    };
    await appearance.install(raw);
    layout.appearanceChanged(assets: true);
  }

  Future<void> reset() => _enqueue<void>(_reset);

  Future<void> _reset(StickerAppearance appearance) async {
    await appearance.reset();
    layout.appearanceChanged(assets: true);
  }

  Future<Uint8List> export() => _enqueue<Uint8List>(_export);

  Future<Uint8List> _export(StickerAppearance appearance) =>
      appearance.export(layout.palette, <StickerCatPose, StickerCharacter>{
        for (final StickerCatPose pose in StickerCatPose.values)
          if (layout.characterOf(pose.index) case final StickerCharacter image)
            pose: image,
      });

  Future<T> _enqueue<T>(SkinOperation<T> operation) {
    final Future<T> result = _pending.then((void _) async {
      if (!layout.ready) await layout.load();
      final StickerAppearance? appearance = layout.appearance;
      if (appearance == null) throw StateError('appearance_unavailable');
      return operation(appearance);
    });
    _pending = result.then<void>((T _) {}, onError: _ignoreFailure);
    return result;
  }

  void _ignoreFailure(Object error, StackTrace stack) {}
}
