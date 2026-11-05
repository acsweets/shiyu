import 'package:flutter/widgets.dart';

import '../../../../app/settings_locale.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/retirement_snapshot.dart';
import '../settings/display_settings.dart';

typedef MetricFields = Map<Object?, Object?>;

/// 视图从同一核心快照选取字段，所有业务数值均由 Rust 产生。
class SnapshotMetrics {
  const SnapshotMetrics(this.snapshot, this.strings);

  final RetirementSnapshot? snapshot;
  final AppLocalizations strings;

  static AppLocalizations localizations(String? preferred) =>
      lookupAppLocalizations(
        basicLocaleListResolution(<Locale>[
          if (settingsLocale(preferred) case final Locale locale) locale,
          ...WidgetsBinding.instance.platformDispatcher.locales,
        ], AppLocalizations.supportedLocales),
      );

  Iterable<MetricFields> get custom =>
      (snapshot?.data['custom_countdowns'] as List<Object?>? ??
              const <Object?>[])
          .whereType<MetricFields>();

  MetricFields read(String id, {bool coreFailed = false}) {
    final String title = metricLabel(strings, id);
    if (coreFailed || snapshot == null) {
      return _metric(
        title,
        coreFailed ? strings.metricUnavailable : strings.mobileNotSet,
      );
    }
    if (id == 'today_salary' || id == 'month_salary') {
      return _salary(id, title);
    }
    if (id.startsWith('custom/')) {
      for (final MetricFields item in custom) {
        if ('custom/${item['id']}' == id) {
          return _countdown(item['name'] as String, item);
        }
      }
    }
    final MetricFields metric = _object(snapshot?.data[id]);
    final String resolved = switch (id) {
      'work' => _workTitle(metric['target_kind']),
      'holiday' when metric['status'] == 'on_holiday' => strings.holidayOngoing,
      _ => title,
    };
    return _countdown(resolved, metric, detail: _detail(id, metric));
  }

  MetricFields _salary(String id, String title) {
    final MetricFields salary = _object(snapshot?.data['salary']);
    final bool today = id == 'today_salary';
    final String? amount =
        salary[today ? 'today_earned' : 'month_earned'] as String?;
    if (amount == null) return _metric(title, strings.mobileNotSet);
    if (salary['hidden'] == true || amount == '****') {
      return _metric(title, '****');
    }
    final String currency = salary['currency'] as String? ?? '';
    return _metric(
      title,
      '$amount $currency'.trim(),
      progress: salary[today ? 'today_progress' : 'month_progress'] as num?,
    );
  }

  String _workTitle(Object? kind) => switch (kind) {
    'work_start' => strings.untilWorkStart,
    'work_end' => strings.untilWorkEnd,
    'lunch_end' => strings.untilLunchEnd,
    _ => strings.metricWork,
  };

  MetricFields _countdown(String title, MetricFields raw, {String? detail}) {
    final String? state = raw['status'] as String?;
    final int? seconds = raw['remaining_seconds'] as int?;
    final String value = switch (state) {
      'retired' => strings.retired,
      'expired' || 'exceeded' => strings.countdownExpired,
      'today' => strings.paydayToday,
      'unconfigured' => strings.mobileNotSet,
      _ when seconds != null && raw['target_millis'] != null => duration(
        seconds,
      ),
      _ => strings.metricUnavailable,
    };
    return _metric(
      title,
      value,
      detail: detail,
      progress: raw['progress'] as num?,
    );
  }

  String? _detail(String id, MetricFields raw) {
    if (id == 'holiday') {
      final MetricFields interval = _object(
        raw['next_interval'] ?? raw['interval'],
      );
      final String? start = interval['first_rest_date'] as String?;
      final String? end = interval['last_rest_date'] as String?;
      if (start == null || end == null) return null;
      return start == end ? start : '$start – $end';
    }
    if (raw['target_millis'] == null) return null;
    return (raw['target_date'] ?? snapshot?.data['time_zone']) as String?;
  }

  String duration(int seconds) {
    final Duration duration = Duration(seconds: seconds);
    final String clock = <int>[
      duration.inHours % 24,
      duration.inMinutes % 60,
      duration.inSeconds % 60,
    ].map(_twoDigits).join(':');
    if (duration.inDays == 0) return clock;
    return '${duration.inDays} ${strings.daysRemaining} · $clock';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  MetricFields _object(Object? raw) =>
      raw as MetricFields? ?? const <Object?, Object?>{};

  MetricFields _metric(
    String title,
    String value, {
    String? detail,
    num? progress,
  }) => <Object?, Object?>{
    'title': title,
    'value': value,
    'detail': ?detail,
    if (progress != null) 'progress': progress.toDouble().clamp(0.0, 1.0),
  };
}
