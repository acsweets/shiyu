import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/settings_paper.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/retirement_controller.dart';
import '../data/mobile_appearance.dart';
import 'mobile_appearance_panel.dart';
import 'mobile_target_form.dart';

class MobileSettingsPage extends StatefulWidget {
  const MobileSettingsPage({required this.controller, super.key});

  /// 退休目标、小组件和核心错误状态共用的控制器。
  final RetirementController controller;

  @override
  State<MobileSettingsPage> createState() => _MobileSettingsPageState();
}

class _MobileSettingsPageState extends State<MobileSettingsPage> {
  /// 读写原生小组件的外观。
  late final MobileAppearanceStore _store;

  /// 已选择的外观，首次读取前暂不开放修改。
  MobileAppearance? _appearance;

  /// 串行写入，避免快速切换时旧外观覆盖新选择。
  Future<void> _pendingWrite = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _store = MobileAppearanceStore(widget.controller.widgets);
    unawaited(_loadAppearance());
  }

  Future<void> _loadAppearance() async {
    MobileAppearance value = const MobileAppearance();
    try {
      value = await _store.read();
    } catch (_) {
      // 旧文件损坏或共享容器不可用时仍可打开配置页。
    }
    if (mounted) setState(() => _appearance = value);
  }

  void _updateAppearance(MobileAppearance value) {
    setState(() => _appearance = value);
    _pendingWrite = _saveAppearance(_pendingWrite, value);
  }

  Future<void> _saveAppearance(
    Future<void> previous,
    MobileAppearance value,
  ) async {
    await previous;
    if (!identical(_appearance, value)) return;
    try {
      await _store.write(value);
    } catch (_) {
      if (!mounted || !identical(_appearance, value)) return;
      _showMessage(AppLocalizations.of(context).mobileAppearanceError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final MobileAppearance? appearance = _appearance;
    return Scaffold(
      appBar: AppBar(title: Text(strings.mobileSettings), titleSpacing: 24),
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
                  child: MobileTargetForm(controller: widget.controller),
                ),
                const SizedBox(height: 28),
                _SettingsSection(
                  title: strings.mobileWidget,
                  icon: Icons.widgets_outlined,
                  child: _buildWidgetControls(strings),
                ),
                const SizedBox(height: 28),
                _SettingsSection(
                  title: strings.mobileAppearance,
                  icon: Icons.palette_outlined,
                  child: appearance == null
                      ? const Center(child: CircularProgressIndicator())
                      : MobileAppearancePanel(
                          appearance: appearance,
                          onChanged: _updateAppearance,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWidgetControls(AppLocalizations strings) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Text(
        strings.widgetInstructions,
        style: Theme.of(context).textTheme.bodyMedium!
            .copyWith(color: SettingsPaper.muted),
      ),
      if (widget.controller.widgets.offersPin) ...<Widget>[
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: _addWidget,
          icon: const Icon(Icons.add_rounded),
          label: Text(strings.addWidget),
        ),
      ],
    ],
  );

  Future<void> _addWidget() async {
    bool requested = false;
    try {
      requested = await widget.controller.widgets.pin();
    } catch (_) {
      // 启动器不支持应用请求时，引导用户手动添加。
    }
    if (!requested && mounted) {
      _showMessage(AppLocalizations.of(context).widgetInstructions);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
