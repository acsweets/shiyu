import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/settings_editor.dart';
import 'custom_countdown_settings.dart';

const List<String> defaultMetricOrder = <String>[
  'work',
  'today_salary',
  'holiday',
  'life',
  'retirement',
  'month_salary',
  'payday',
];

String metricLabel(AppLocalizations strings, String id) => switch (id) {
  'work' => strings.metricWork,
  'today_salary' => strings.metricTodaySalary,
  'month_salary' => strings.metricMonthSalary,
  'holiday' => strings.metricHoliday,
  'life' => strings.metricLife,
  'retirement' => strings.retirementTitle,
  'payday' => strings.metricPayday,
  _ => id,
};

class DisplaySettingsForm extends StatelessWidget {
  const DisplaySettingsForm({required this.editor, super.key});

  final SettingsEditor editor;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final List<String> order = _order;
    final Set<String> enabled = _enabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          strings.miniMetrics,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Wrap(
          spacing: 6,
          children: <Widget>[
            TextButton(
              onPressed: editor.blocked ? null : _enableAll,
              child: Text(strings.enableAll),
            ),
            TextButton(
              onPressed: editor.blocked ? null : _disableAll,
              child: Text(strings.disableAll),
            ),
          ],
        ),
        for (int index = 0; index < order.length; index++)
          _metricRow(
            context,
            order[index],
            index,
            enabled.contains(order[index]),
          ),
        const Divider(height: 28),
        CustomCountdownSettings(editor: editor),
      ],
    );
  }

  Widget _metricRow(BuildContext context, String id, int index, bool selected) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Checkbox(
        value: selected,
        onChanged: editor.blocked
            ? null
            : (bool? value) => _toggle(id, value == true),
        semanticLabel: metricLabel(strings, id),
      ),
      title: Text(metricLabel(strings, id)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
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
            onPressed: editor.blocked || index + 1 == _order.length
                ? null
                : () => _move(index, 1),
            icon: const Icon(Icons.keyboard_arrow_down),
          ),
        ],
      ),
    );
  }

  List<String> get _order =>
      (editor.group('display')['metric_order'] as List<Object?>?)
          ?.cast<String>()
          .toList() ??
      defaultMetricOrder.toList();

  Set<String> get _enabled =>
      (editor.group('display')['enabled_metrics'] as List<Object?>?)
          ?.cast<String>()
          .toSet() ??
      defaultMetricOrder.take(5).toSet();

  void _enableAll() => _change('enabled_metrics', _order);
  void _disableAll() => _change('enabled_metrics', <String>[]);

  void _toggle(String id, bool enabled) {
    final Set<String> items = _enabled;
    if (enabled) {
      items.add(id);
    } else {
      items.remove(id);
    }
    _change('enabled_metrics', _order.where(items.contains).toList());
  }

  void _move(int index, int direction) {
    final List<String> order = _order;
    final String item = order.removeAt(index);
    order.insert(index + direction, item);
    _change('metric_order', order);
  }

  void _change(String field, List<String> values) =>
      editor.change('display', <String, dynamic>{
        ...editor.group('display'),
        field: values,
        'metrics_customized': true,
      });
}
