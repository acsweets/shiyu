import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../application/sticker_group_view.dart';
import '../../application/sticker_settings_state.dart';
import '../../data/skins/timer_pack.dart';
import '../../data/sticker_cat_pose.dart';
import 'settings_controls.dart';

class AssetSettings extends StatelessWidget {
  const AssetSettings({required this.session, super.key});

  /// 编号素材和当前替换结果。
  final StickerSettingsSession session;
  static const XTypeGroup _packType = XTypeGroup(
    label: '时余皮肤包',
    extensions: <String>['timerpack'],
    uniformTypeIdentifiers: <String>['com.growthrecord.shiyu.timerpack'],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: StickerCatPose.values.map(_sample).toList(),
      ),
      const SizedBox(height: 24),
      const Divider(height: 1),
      const SizedBox(height: 18),
      const Text('皮肤包', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      const Text('导出配色、皮肤选项和替换素材。仅分享你有权再分发的图片。'),
      const SizedBox(height: 14),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          OutlinedButton(
            onPressed: () => _import(context),
            child: const Text('导入皮肤包'),
          ),
          OutlinedButton(
            onPressed: () => _export(context),
            child: const Text('导出皮肤包'),
          ),
          OutlinedButton(
            onPressed: () => _run(context, StickerSetting.skinReset),
            child: const Text('恢复默认皮肤'),
          ),
        ],
      ),
      const SizedBox(height: 20),
      const Divider(height: 1),
      const SizedBox(height: 18),
      const Text('替换图片', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      const Text('将透明 PNG 放入素材目录，文件名和窗口编号对应。每张最多 8 MiB，放好后点「重新载入猫猫」。'),
      const SizedBox(height: 15),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          OutlinedButton.icon(
            onPressed: () => _run(context, StickerSetting.openAssets),
            icon: const Icon(Icons.folder_open_outlined, size: 18),
            label: const Text('打开素材目录'),
          ),
          OutlinedButton.icon(
            onPressed: () => _reload(context),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('重新载入猫猫'),
          ),
        ],
      ),
    ],
  );

  Widget _sample(StickerCatPose pose) {
    final StickerGroupView window = session.state.window(pose.index);
    final File? character = window.character;
    return Container(
      width: 140,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        border: Border.all(color: SettingsPaper.line),
        borderRadius: SettingsPaper.corners,
      ),
      child: Column(
        children: <Widget>[
          SizedBox.square(
            dimension: 72,
            child: character == null
                ? Image.asset(pose.asset, cacheWidth: 288)
                : Image.file(
                    character,
                    key: ValueKey<int>(window.assetRevision),
                    errorBuilder: (
                      BuildContext context,
                      Object error,
                      StackTrace? stack,
                    ) => Image.asset(pose.asset, cacheWidth: 288),
                  ),
          ),
          const SizedBox(height: 6),
          Text('窗口 ${pose.index + 1}'),
          Text(
            pose.overrideFileName,
            style: const TextStyle(fontSize: 11, color: SettingsPaper.muted),
          ),
        ],
      ),
    );
  }

  Future<void> _reload(BuildContext context) async {
    for (final StickerCatPose pose in StickerCatPose.values) {
      final File? file = session.state.window(pose.index).character;
      if (file != null) await FileImage(file).evict();
    }
    if (context.mounted) await _run(context, StickerSetting.reloadAssets);
  }

  Future<void> _run(BuildContext context, StickerSetting action) async {
    final StickerSettingsReply reply = await session.send(action);
    if (!context.mounted) return;
    _feedback(context, reply.message);
  }

  Future<void> _import(BuildContext context) async {
    try {
      final XFile? file = await openFile(
        acceptedTypeGroups: <XTypeGroup>[_packType],
      );
      if (file == null || !context.mounted) return;
      final Uint8List bundle = await TimerPack.readFile(File(file.path));
      if (!context.mounted) return;
      final StickerSettingsReply reply = await session.send(
        StickerSetting.skinImport,
        <String, Object?>{'bundle': bundle},
      );
      if (!context.mounted) return;
      _feedback(context, reply.message);
    } catch (_) {
      if (!context.mounted) return;
      _feedback(context, '无法读取皮肤包，请检查文件大小和权限');
    }
  }

  Future<void> _export(BuildContext context) async {
    try {
      final StickerSettingsReply reply = await session.send(
        StickerSetting.skinExport,
      );
      final Uint8List? bundle = reply.assetBundle;
      if (!context.mounted) return;
      if (bundle == null) {
        _feedback(context, reply.message);
        return;
      }
      final FileSaveLocation? target = await getSaveLocation(
        suggestedName: 'shiyu.timerpack',
        acceptedTypeGroups: <XTypeGroup>[_packType],
      );
      if (target == null) return;
      final String path = target.path.toLowerCase().endsWith('.timerpack')
          ? target.path
          : '${target.path}.timerpack';
      await XFile.fromData(bundle).saveTo(path);
      if (!context.mounted) return;
      _feedback(context, '已导出皮肤包');
    } catch (_) {
      if (!context.mounted) return;
      _feedback(context, '无法保存皮肤包');
    }
  }

  void _feedback(BuildContext context, String? message) {
    if (!context.mounted || message == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
