import 'package:flutter/material.dart';

import '../../../app/theme/settings_paper.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/retirement_controller.dart';
import 'mobile_settings_detail.dart';
import 'mobile_widget_settings_page.dart';
import 'settings/app_language_setting.dart';

class MobileSettingsPage extends StatelessWidget {
  const MobileSettingsPage({required this.controller, super.key});

  /// 设置首页与各分类共享当前生效的设置。
  final RetirementController controller;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.mobileSettings), titleSpacing: 24),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: <Widget>[
                ListenableBuilder(listenable: controller, builder: _language),
                const SizedBox(height: 16),
                _group(<Widget>[
                  _section(context, MobileSettingsSection.countdowns),
                  _section(context, MobileSettingsSection.work),
                  _section(context, MobileSettingsSection.calendar),
                  _section(context, MobileSettingsSection.titles),
                ]),
                const SizedBox(height: 16),
                _group(<Widget>[
                  _row(
                    title: strings.mobileWidget,
                    detail: strings.mobileWidgetSummary,
                    icon: Icons.widgets_outlined,
                    open: () => _openWidgets(context),
                  ),
                  _section(context, MobileSettingsSection.general),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _group(List<Widget> rows) => Material(
    color: SettingsPaper.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: SettingsPaper.line),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: <Widget>[
        for (int index = 0; index < rows.length; index++) ...<Widget>[
          if (index > 0) const Divider(height: 1, indent: 56, endIndent: 14),
          rows[index],
        ],
      ],
    ),
  );

  Widget _section(BuildContext context, MobileSettingsSection section) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return _row(
      title: section.title(strings),
      detail: section.detail(strings),
      icon: section.icon,
      open: () => _openSection(context, section),
    );
  }

  Widget _row({
    required String title,
    required String detail,
    required IconData icon,
    required VoidCallback open,
  }) => ListTile(
    minVerticalPadding: 10,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
    leading: Icon(icon, color: SettingsPaper.accent),
    title: Text(title),
    subtitle: Text(detail, style: const TextStyle(color: SettingsPaper.muted)),
    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
    onTap: open,
  );

  Widget _language(BuildContext context, Widget? child) => AppLanguageSetting(
    locale: controller.preferredLocale,
    save: controller.editingBlocked || controller.saving
        ? null
        : controller.setPreferredLocale,
  );

  Future<void> _openSection(
    BuildContext context,
    MobileSettingsSection section,
  ) async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) =>
            MobileSettingsDetail(controller: controller, section: section),
      ),
    );
    if (saved != true || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).mobileSaved)),
    );
  }

  void _openWidgets(BuildContext context) =>
      Navigator.of(context)
          .push<void>(MaterialPageRoute<void>(builder: _widgetPage));

  Widget _widgetPage(BuildContext context) =>
      MobileWidgetSettingsPage(bridge: controller.widgets);
}
