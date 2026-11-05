import 'package:flutter/material.dart';

import '../../application/sticker_settings_state.dart';
import '../../data/skins/sticker_skin_settings.dart';
import 'settings_controls.dart';

class SkinSettings extends StatelessWidget {
  const SkinSettings({required this.session, super.key});

  final StickerSettingsSession session;

  @override
  Widget build(BuildContext context) {
    final StickerSkinSettings skin = session.state.skin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('浮窗皮肤', style: TextStyle(fontSize: 17)),
        const SizedBox(height: 8),
        _menu(context, '皮肤', 'skin', skin.skin.name, const <String, String>{
          'stationery': '简约卡片',
          'darkTech': '深色科技',
        }),
        _menu(context, '明暗模式', 'theme', skin.theme.name, const <String, String>{
          'light': '浅色',
          'dark': '深色',
          'system': '跟随系统',
        }),
        _menu(context, '数字字号', 'scale', skin.scale.name, const <String, String>{
          'small': '小',
          'medium': '中',
          'large': '大',
        }),
        _menu(context, '强调色', 'accent', skin.accent, const <Object?, String>{
          null: '默认',
          0xFFE7A976: '暖橙',
          0xFF91B6E0: '浅蓝',
          0xFFB39AE2: '淡紫',
          0xFF83C4B0: '薄荷',
        }),
        PaperSettingRow(
          title: '背景不透明度',
          detail: '猫猫和时间文字保持清晰',
          control: Text('${skin.opacity}%'),
        ),
        Semantics(
          label: '背景不透明度',
          child: Slider(
            min: 30,
            max: 100,
            divisions: 14,
            value: skin.opacity.toDouble(),
            label: '${skin.opacity}%',
            onChanged: (double value) =>
                _change(context, 'opacity', value.round()),
          ),
        ),
      ],
    );
  }

  Widget _menu(
    BuildContext context,
    String title,
    String key,
    Object? value,
    Map<Object?, String> labels,
  ) => PaperSettingRow(
    title: title,
    control: PaperMenu(
      tooltip: title,
      label: labels[value]!,
      items: <Widget>[
        for (final MapEntry<Object?, String> item in labels.entries)
          PaperOption(
            label: item.value,
            selected: item.key == value,
            onSelect: () => _change(context, key, item.key),
          ),
      ],
    ),
  );

  Future<void> _change(BuildContext context, String key, Object? value) async {
    final StickerSettingsReply reply = await session.send(
      StickerSetting.skinOptions,
      <String, Object?>{'key': key, 'value': value},
    );
    if (!context.mounted || reply.message == null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(reply.message!)));
  }
}
