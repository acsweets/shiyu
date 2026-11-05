import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/settings_editor.dart';
import '../../data/settings_repository.dart';
import 'dated_item_dialog.dart';

class CustomCountdownSettings extends StatelessWidget {
  const CustomCountdownSettings({required this.editor, super.key});

  final SettingsEditor editor;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final List<SettingsValues> items = _items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          strings.customCountdown,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (items.isEmpty) Text(strings.mobileNotSet),
        for (int index = 0; index < items.length; index++)
          _item(context, items[index], index, items.length),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: editor.blocked ? null : () => _edit(context),
          icon: const Icon(Icons.add),
          label: Text(strings.addCountdown),
        ),
      ],
    );
  }

  Widget _item(
    BuildContext context,
    SettingsValues value,
    int index,
    int length,
  ) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Checkbox(
            value: value['enabled'] != false,
            onChanged: editor.blocked
                ? null
                : (bool? enabled) => _setEnabled(index, enabled == true),
            semanticLabel: value['name'] as String,
          ),
          title: Text(value['name'] as String),
          subtitle: Text((value['target'] as String).replaceFirst('T', ' ')),
          onTap: editor.blocked ? null : () => _edit(context, value),
        ),
        Wrap(
          children: <Widget>[
            IconButton(
              tooltip: strings.moveUp,
              onPressed: editor.blocked || index == 0
                  ? null
                  : () => _move(index, -1),
              icon: const Icon(Icons.keyboard_arrow_up),
            ),
            IconButton(
              tooltip: strings.moveDown,
              onPressed: editor.blocked || index + 1 == length
                  ? null
                  : () => _move(index, 1),
              icon: const Icon(Icons.keyboard_arrow_down),
            ),
            IconButton(
              tooltip: strings.removeItem,
              onPressed: editor.blocked ? null : () => _remove(context, value),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        const Divider(),
      ],
    );
  }

  List<SettingsValues> get _items {
    final List<Object?> raw =
        editor.draft['custom_countdowns'] as List<Object?>? ??
        const <Object?>[];
    final List<({int index, SettingsValues value})> indexed =
        <({int index, SettingsValues value})>[
          for (int index = 0; index < raw.length; index++)
            (index: index, value: SettingsEditor.object(raw[index])),
        ]..sort(_compare);
    return <SettingsValues>[
      for (final ({int index, SettingsValues value}) item in indexed)
        item.value,
    ];
  }

  int _compare(
    ({int index, SettingsValues value}) a,
    ({int index, SettingsValues value}) b,
  ) {
    final int order = (a.value['order'] as int? ?? a.index).compareTo(
      b.value['order'] as int? ?? b.index,
    );
    return order == 0 ? a.index.compareTo(b.index) : order;
  }

  Future<void> _edit(BuildContext context, [SettingsValues? existing]) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => DatedItemDialog(
        value: existing ?? <String, dynamic>{},
        countdown: true,
        submit: _upsert,
      ),
    );
  }

  Future<bool> _upsert(SettingsValues item) =>
      editor.editCountdown(<String, dynamic>{'action': 'upsert', 'item': item});

  Future<void> _remove(BuildContext context, SettingsValues item) async {
    final bool saved = await editor.editCountdown(<String, dynamic>{
      'action': 'remove',
      'id': item['id'],
    });
    if (!saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).invalidValue)),
      );
    }
  }

  void _setEnabled(int index, bool enabled) {
    final List<SettingsValues> items = _items;
    items[index] = <String, dynamic>{...items[index], 'enabled': enabled};
    editor.change('custom_countdowns', items);
  }

  void _move(int index, int direction) {
    final List<SettingsValues> items = _items;
    final SettingsValues item = items.removeAt(index);
    items.insert(index + direction, item);
    editor.change('custom_countdowns', <SettingsValues>[
      for (int i = 0; i < items.length; i++)
        <String, dynamic>{...items[i], 'order': i},
    ]);
  }
}
