import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/settings_paper.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../platform/widgets/widget_bridge.dart';
import '../data/mobile_appearance.dart';
import 'mobile_appearance_panel.dart';

class MobileWidgetSettingsPage extends StatefulWidget {
  const MobileWidgetSettingsPage({required this.bridge, super.key});

  /// 添加系统小组件并读写共享外观。
  final WidgetBridge bridge;

  @override
  State<MobileWidgetSettingsPage> createState() =>
      _MobileWidgetSettingsPageState();
}

class _MobileWidgetSettingsPageState extends State<MobileWidgetSettingsPage> {
  /// 读写原生小组件的外观。
  late final MobileAppearanceStore _store;

  /// 已选择的外观，首次读取前暂不开放修改。
  MobileAppearance? _appearance;

  /// 串行写入，避免快速切换时旧外观覆盖新选择。
  Future<void> _pendingWrite = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _store = MobileAppearanceStore(widget.bridge);
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
      appBar: AppBar(title: Text(strings.mobileWidget)),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: <Widget>[
                _buildWidgetControls(strings),
                const Divider(height: 36),
                Text(
                  strings.mobileAppearance,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (appearance == null)
                  const Center(child: CircularProgressIndicator())
                else
                  MobileAppearancePanel(
                    appearance: appearance,
                    onChanged: _updateAppearance,
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
      if (widget.bridge.offersPin) ...<Widget>[
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () => _addWidget(salary: false),
          icon: const Icon(Icons.add_rounded),
          label: Text(strings.addWidget),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _addWidget(salary: true),
          icon: const Icon(Icons.add_rounded),
          label: Text(strings.addSalaryWidget),
        ),
      ],
    ],
  );

  Future<void> _addWidget({required bool salary}) async {
    bool requested = false;
    try {
      requested = await widget.bridge.pin(salary: salary);
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
