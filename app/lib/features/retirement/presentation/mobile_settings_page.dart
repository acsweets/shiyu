import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../../app/theme/settings_paper.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/retirement_controller.dart';
import '../data/mobile_appearance.dart';
import 'mobile_appearance_panel.dart';
import 'mobile_target_form.dart';

class MobileSettingsPage extends StatelessWidget {
  const MobileSettingsPage({
    required this.controller,
    required this.appearance,
    required this.onAppearanceChanged,
    super.key,
  });

  /// 退休目标与小组件操作沿用同一控制器。
  final RetirementController controller;

  /// 首页和设置页共用的手机外观。
  final ValueListenable<MobileAppearance> appearance;

  /// 手机外观变更后更新首页并落盘。
  final MobileAppearanceChanged onAppearanceChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(strings.mobileSettings),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: <Widget>[
                _SettingsSection(
                  title: strings.retirementTitle,
                  icon: Icons.hourglass_bottom_rounded,
                  child: MobileTargetForm(controller: controller),
                ),
                const SizedBox(height: 28),
                _SettingsSection(
                  title: strings.mobileAppearance,
                  icon: Icons.palette_outlined,
                  child: ValueListenableBuilder<MobileAppearance>(
                    valueListenable: appearance,
                    builder: _buildAppearance,
                  ),
                ),
                const SizedBox(height: 28),
                _SettingsSection(
                  title: strings.mobileWidget,
                  icon: Icons.widgets_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        strings.widgetInstructions,
                        style: Theme.of(context).textTheme.bodyMedium!
                            .copyWith(color: SettingsPaper.muted),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: () => _addWidget(context),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(strings.addWidget),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppearance(
    BuildContext context,
    MobileAppearance value,
    Widget? child,
  ) => MobileAppearancePanel(appearance: value, onChanged: onAppearanceChanged);

  Future<void> _addWidget(BuildContext context) async {
    bool requested = false;
    try {
      requested = await controller.widgets.pin();
    } catch (_) {
      // 不支持直接添加时保留本页的手动添加说明。
    }
    if (!requested && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).widgetInstructions),
        ),
      );
    }
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  /// 单列设置页中的分组标题。
  final String title;

  /// 分组左侧的识别图标。
  final IconData icon;

  /// 分组内的表单或外观选项。
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Row(
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              color: SettingsPaper.selection,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(icon, size: 18, color: SettingsPaper.accent),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: SettingsPaper.line),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ],
  );
}
