import 'package:flutter/material.dart';

import '../../../app/theme/settings_paper.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/retirement_controller.dart';
import '../domain/metric_preferences.dart';
import 'metrics/snapshot_metrics.dart';
import 'mobile_settings_page.dart';

/// 手机全屏首页直接使用 Rust 快照，桌面上的组件仍由系统提供。
class MobileDashboard extends StatelessWidget {
  const MobileDashboard({required this.controller, super.key});

  final RetirementController controller;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.appName),
        titleSpacing: 24,
        actions: <Widget>[
          IconButton(
            tooltip: strings.refreshEarnings,
            onPressed: _refreshEarnings,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: strings.mobileSettings,
            onPressed: () => _openSettings(context),
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListenableBuilder(listenable: controller, builder: _body),
          ),
        ),
      ),
    );
  }

  /// 立即重算首页金额，并请求系统更新已添加的小组件。
  Future<void> _refreshEarnings() async {
    await controller.refresh();
    await controller.synchronizeWidgets();
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context)
        .push<void>(MaterialPageRoute<void>(builder: _settings));
  }

  Widget _settings(BuildContext context) =>
      MobileSettingsPage(controller: controller);

  Widget _body(BuildContext context, Widget? child) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final SnapshotMetrics metrics = SnapshotMetrics(
      controller.snapshot,
      strings,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      children: <Widget>[
        if (controller.editingBlocked || controller.problem == 'widget_refresh')
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              strings.settingsError,
              style: const TextStyle(color: SettingsPaper.accent),
            ),
          ),
        _card(metrics, 'work', Icons.schedule_rounded, emphasized: true),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) =>
              _grid(context, constraints, metrics),
        ),
        if (controller.snapshot?.calendarStatus == 'weekly_fallback')
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              strings.holidayFallback,
              style: const TextStyle(color: SettingsPaper.muted),
            ),
          ),
      ],
    );
  }

  Widget _grid(
    BuildContext context,
    BoxConstraints constraints,
    SnapshotMetrics metrics,
  ) {
    const Map<String, IconData> items = <String, IconData>{
      todaySalaryId: Icons.account_balance_wallet_outlined,
      'month_salary': Icons.stacked_line_chart_rounded,
      'holiday': Icons.event_available_outlined,
      'payday': Icons.payments_outlined,
      'retirement': Icons.hourglass_bottom_rounded,
      'life': Icons.favorite_border_rounded,
    };
    const double gap = 12;
    final double scale = MediaQuery.textScalerOf(context).scale(18) / 18;
    final bool twoColumns = constraints.maxWidth >= 300 * scale;
    final double width = twoColumns
        ? (constraints.maxWidth - gap) / 2
        : constraints.maxWidth;
    final bool showToday = enabledMetricIds(controller.displaySettings)
        .contains(todaySalaryId);
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: <Widget>[
        for (final MapEntry<String, IconData> item in items.entries)
          if (item.key != todaySalaryId || showToday)
            SizedBox(width: width, child: _card(metrics, item.key, item.value)),
      ],
    );
  }

  Widget _card(
    SnapshotMetrics metrics,
    String id,
    IconData icon, {
    bool emphasized = false,
  }) {
    final MetricFields item = metrics.read(
      id,
      coreFailed: controller.problem == 'core',
    );
    return _MobileMetricCard(
      key: ValueKey<String>('mobile-metric-$id'),
      item: item,
      icon: icon,
      emphasized: emphasized,
      showTitle: metrics.showsTitle(id),
    );
  }
}

class _MobileMetricCard extends StatelessWidget {
  const _MobileMetricCard({
    required this.item,
    required this.icon,
    required this.emphasized,
    required this.showTitle,
    super.key,
  });

  final MetricFields item;
  final IconData icon;
  final bool emphasized;

  /// 当前指标独立的标题显隐。
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: emphasized ? SettingsPaper.selection : SettingsPaper.surface,
        border: Border.all(color: SettingsPaper.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: EdgeInsets.all(emphasized ? 20 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (showTitle) ...<Widget>[
              Row(
                children: <Widget>[
                  Icon(icon, size: 18, color: SettingsPaper.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item['title'] as String,
                      style: text.labelLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            Text(
              item['value'] as String,
              style: (emphasized ? text.headlineMedium : text.titleLarge)
                  ?.copyWith(
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (item['detail'] case final String detail) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                detail,
                style: text.bodySmall?.copyWith(color: SettingsPaper.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
