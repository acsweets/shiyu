import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/settings_paper.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/retirement_controller.dart';
import '../data/mobile_appearance.dart';
import 'mobile_settings_page.dart';
import 'mobile_sticker_canvas.dart';

class RetirementPage extends StatefulWidget {
  const RetirementPage({required this.controller, super.key});

  /// 移动应用的设置与 Rust 快照状态。
  final RetirementController controller;

  @override
  State<RetirementPage> createState() => _RetirementPageState();
}

class _RetirementPageState extends State<RetirementPage>
    with WidgetsBindingObserver {
  /// 首页与设置页同步读取同一份手机外观。
  final ValueNotifier<MobileAppearance> _appearance =
      ValueNotifier<MobileAppearance>(const MobileAppearance());

  /// 外观文件与小组件的共享数据分开存放。
  final MobileAppearanceStore _store = const MobileAppearanceStore();

  /// 同一时刻只写一次临时文件，连续操作以最新外观为准。
  Future<void> _pendingWrite = Future<void>.value();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.setVisible(true);
    unawaited(_restoreAppearance());
  }

  @override
  void dispose() {
    widget.controller.setVisible(false);
    WidgetsBinding.instance.removeObserver(this);
    _appearance.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.controller.setVisible(true);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      widget.controller.setVisible(false);
    }
  }

  Future<void> _restoreAppearance() async {
    final MobileAppearance stored = await _store.read();
    if (mounted && identical(_appearance.value, const MobileAppearance())) {
      _appearance.value = stored;
    }
  }

  void _updateAppearance(MobileAppearance value) {
    _appearance.value = value;
    final Future<void> previous = _pendingWrite;
    _pendingWrite = _saveAppearance(previous, value);
  }

  Future<void> _saveAppearance(
    Future<void> previous,
    MobileAppearance value,
  ) async {
    await previous;
    if (mounted && !identical(_appearance.value, value)) return;
    try {
      await _store.write(value);
    } catch (_) {
      if (!mounted || !identical(_appearance.value, value)) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).mobileAppearanceError),
        ),
      );
    }
  }

  void _moveCard(Alignment position) =>
      _updateAppearance(_appearance.value.copyWith(position: position));

  void _openSettings() {
    unawaited(
      Navigator.of(context)
          .push<void>(MaterialPageRoute<void>(builder: _buildSettings)),
    );
  }

  Widget _buildSettings(BuildContext context) => MobileSettingsPage(
    controller: widget.controller,
    appearance: _appearance,
    onAppearanceChanged: _updateAppearance,
  );

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.appName),
        titleSpacing: 24,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 18),
            child: IconButton(
              tooltip: strings.mobileSettings,
              style: IconButton.styleFrom(
                foregroundColor: SettingsPaper.accent,
                backgroundColor: SettingsPaper.selection,
                minimumSize: const Size.square(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _openSettings,
              icon: const Icon(Icons.settings_outlined),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ValueListenableBuilder<MobileAppearance>(
          valueListenable: _appearance,
          builder: _buildHome,
        ),
      ),
    );
  }

  Widget _buildHome(
    BuildContext context,
    MobileAppearance appearance,
    Widget? child,
  ) {
    if (!appearance.cardVisible) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(AppLocalizations.of(context).mobileCardHidden),
        ),
      );
    }
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, Widget? child) =>
          _buildCountdown(context, appearance),
    );
  }

  Widget _buildCountdown(BuildContext context, MobileAppearance appearance) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Column(
      children: <Widget>[
        Expanded(
          child: MobileStickerCanvas(
            appearance: appearance,
            snapshot: widget.controller.snapshot,
            onPositionChanged: _moveCard,
          ),
        ),
        if (widget.controller.retirementDate == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: OutlinedButton.icon(
              onPressed: _openSettings,
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text(strings.chooseRetirement),
            ),
          ),
      ],
    );
  }
}
