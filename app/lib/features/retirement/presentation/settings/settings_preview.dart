import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/settings_editor.dart';
import '../../data/settings_repository.dart';
import 'display_settings.dart';

class SettingsSnapshotPreview extends StatelessWidget {
  const SettingsSnapshotPreview({required this.snapshot, super.key});

  final SettingsValues snapshot;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final SettingsValues salary = SettingsEditor.object(snapshot['salary']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          strings.previewLive,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        for (final String id in <String>[
          'work',
          'holiday',
          'life',
          'retirement',
        ])
          _row(metricLabel(strings, id), _format(strings, id)),
        _row(
          strings.metricTodaySalary,
          _salary(strings, salary, 'today_earned'),
        ),
        _row(
          strings.metricMonthSalary,
          _salary(strings, salary, 'month_earned'),
        ),
      ],
    );
  }

  Widget _row(String label, String value) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text(value),
  );

  String _salary(AppLocalizations strings, SettingsValues salary, String key) {
    final String? amount = salary[key] as String?;
    final String currency = salary['currency'] as String? ?? '';
    return amount == null ? strings.mobileNotSet : '$amount $currency'.trim();
  }

  String _format(AppLocalizations strings, String id) {
    final SettingsValues metric = SettingsEditor.object(snapshot[id]);
    final int? seconds = metric['remaining_seconds'] as int?;
    final String? status = metric['status'] as String?;
    if (status == 'retired') return strings.retired;
    if (seconds == null || status == 'unconfigured') {
      return strings.mobileNotSet;
    }
    final Duration time = Duration(seconds: seconds);
    final String clock = <int>[
      time.inHours % 24,
      time.inMinutes % 60,
      time.inSeconds % 60,
    ].map(_twoDigits).join(':');
    return time.inDays == 0
        ? clock
        : '${time.inDays} ${strings.daysRemaining} · $clock';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
