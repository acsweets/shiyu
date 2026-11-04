import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/retirement_controller.dart';
import '../domain/retirement_snapshot.dart';

class RetirementCard extends StatelessWidget {
  const RetirementCard({required this.controller, super.key});

  /// 只呈现核心返回的数据，不计算目标日期或天数。
  final RetirementController controller;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final RetirementSnapshot? snapshot = controller.snapshot;
    final String status = snapshot?.status ?? 'unconfigured';
    final String value = status == 'unconfigured'
        ? '—'
        : status == 'retired'
        ? strings.retired
        : NumberFormat.decimalPattern(strings.localeName)
              .format(snapshot!.days);
    final Duration duration = Duration(seconds: snapshot?.seconds ?? 0);
    final String clock =
        '${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    return Card(
      color: const Color(0xFFF0F6F2),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              strings.retirementTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              key: const ValueKey<String>('retirementValue'),
              style: Theme.of(context).textTheme.displayMedium,
            ),
            if (status == 'active') Text(strings.daysRemaining),
            const SizedBox(height: 12),
            if (status == 'active')
              Text(
                clock,
                style: const TextStyle(
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
            Text(controller.retirementDate ?? strings.chooseRetirement),
            const SizedBox(height: 8),
            Text(
              controller.timeZone,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
