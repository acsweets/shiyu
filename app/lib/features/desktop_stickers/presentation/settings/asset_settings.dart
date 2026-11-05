import 'dart:io';

import 'package:flutter/material.dart';

import '../../application/sticker_group_view.dart';
import '../../application/sticker_settings_state.dart';
import '../../data/sticker_cat_pose.dart';
import 'settings_controls.dart';

class AssetSettings extends StatelessWidget {
  const AssetSettings({required this.session, super.key});

  /// 编号素材和当前替换结果。
  final StickerSettingsSession session;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: StickerCatPose.values.map(_sample).toList(),
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
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
      decoration: BoxDecoration(
        color: SettingsPaper.sidebar,
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
          Text(
            '窗口 ${pose.index + 1}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
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
    if (!context.mounted || reply.message == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(reply.message!),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
