import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/retirement_controller.dart';
import '../application/settings_access.dart';
import '../application/settings_editor.dart';
import '../domain/metric_preferences.dart';
import 'settings/calendar_settings.dart';
import 'settings/display_settings.dart';
import 'settings/general_settings.dart';
import 'settings/personal_settings.dart';
import 'settings/work_settings.dart';

enum MobileSettingsSection {
  countdowns(Icons.hourglass_bottom_rounded),
  work(Icons.schedule_rounded),
  calendar(Icons.event_available_outlined),
  titles(Icons.title_rounded),
  general(Icons.tune_rounded);

  const MobileSettingsSection(this.icon);

  /// 设置首页中对应任务的图标。
  final IconData icon;

  String title(AppLocalizations strings) => switch (this) {
    countdowns => strings.desktopCountdowns,
    work => strings.workSection,
    calendar => strings.calendarSection,
    titles => strings.metricTitleVisibility,
    general => strings.generalSection,
  };

  String detail(AppLocalizations strings) => switch (this) {
    countdowns => strings.mobileCountdownSummary,
    work => strings.mobileWorkSummary,
    calendar => strings.mobileCalendarSummary,
    titles => strings.mobileTitlesSummary,
    general => strings.mobileGeneralSummary,
  };
}

typedef SettingsSubmit = Future<bool> Function();

/// 手机详情页只显示所选分类，校验失败时在原页保留草稿。
class MobileSettingsDetail extends StatefulWidget {
  const MobileSettingsDetail({
    required this.controller,
    required this.section,
    super.key,
  });

  /// 业务校验与本地存储入口。
  final RetirementController controller;

  /// 从设置首页选择的分类。
  final MobileSettingsSection section;

  @override
  State<MobileSettingsDetail> createState() => _MobileSettingsDetailState();
}

class _MobileSettingsDetailState extends State<MobileSettingsDetail> {
  /// 当前页面的草稿，点击底部按钮后提交。
  late final SettingsEditor _editor = SettingsEditor(
    SettingsAccess.local(widget.controller),
    SettingsView.fromController(widget.controller),
    autosave: false,
  );

  /// 避免连按返回时打开多个确认框。
  bool _confirming = false;

  /// 保存或恢复备份期间保留当前页面。
  bool _submitting = false;

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: _editor, builder: _page);

  Widget _page(BuildContext context, Widget? child) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return PopScope<bool>(
      canPop: !_editor.dirty && !_submitting,
      onPopInvokedWithResult: _onPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.section.title(strings)),
          leading: BackButton(onPressed: _back),
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: <Widget>[
                  if (_editor.blocked) ...<Widget>[
                    Text(strings.settingsError),
                    if (widget.controller.canRestoreBackup)
                      OutlinedButton(
                        onPressed: _submitting ? null : _restore,
                        child: Text(strings.restoreSettingsBackup),
                      ),
                    const SizedBox(height: 16),
                  ],
                  IgnorePointer(
                    ignoring: _submitting,
                    child: KeyedSubtree(
                      key: ValueKey<int>(_editor.generation),
                      child: _form(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: _saveBar(context, strings),
      ),
    );
  }

  Widget _form() => switch (widget.section) {
    MobileSettingsSection.countdowns => _countdownSettings(),
    MobileSettingsSection.work => WorkSettings(
      editor: _editor,
      useTimePickers: true,
    ),
    MobileSettingsSection.calendar => CalendarSettings(editor: _editor),
    MobileSettingsSection.titles => DisplaySettingsForm(
      editor: _editor,
      desktop: false,
    ),
    MobileSettingsSection.general => GeneralSettings(
      editor: _editor,
      mobile: true,
    ),
  };

  Widget _countdownSettings() {
    final AppLocalizations strings = AppLocalizations.of(context);
    final bool showToday = enabledMetricIds(_editor.group('display'))
        .contains(todaySalaryId);
    return Column(
      children: <Widget>[
        SwitchListTile(
          key: const ValueKey<String>('metric-visibility-today_salary'),
          contentPadding: EdgeInsets.zero,
          title: Text(strings.showTodayEarnings),
          value: showToday,
          onChanged: _editor.blocked ? null : _setTodayEarnings,
        ),
        SwitchListTile(
          key: const ValueKey<String>('amount-privacy'),
          contentPadding: EdgeInsets.zero,
          title: Text(strings.hideSalary),
          subtitle: Text(strings.hideEarningsDetail),
          value: _editor.draft['hide_amount'] != false,
          onChanged: _editor.blocked ? null : _setAmountHidden,
        ),
        const Divider(height: 28),
        PersonalSettings(editor: _editor, showTimeZone: false),
      ],
    );
  }

  void _setTodayEarnings(bool visible) {
    final Set<String> enabled = enabledMetricIds(_editor.group('display'))
        .toSet();
    if (visible) {
      enabled.add(todaySalaryId);
    } else {
      enabled.remove(todaySalaryId);
    }
    _editor.changeGroup('display', 'enabled_metrics', enabled.toList());
  }

  void _setAmountHidden(bool hidden) => _editor.change('hide_amount', hidden);

  Widget _saveBar(BuildContext context, AppLocalizations strings) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_editor.hasErrors)
            Semantics(
              liveRegion: true,
              child: Text(
                _editor.view.issues.isEmpty
                    ? strings.settingsError
                    : strings.invalidDraft,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          FilledButton(
            onPressed: _editor.dirty && !_editor.blocked && !_submitting
                ? _save
                : null,
            child: Text(
              _submitting ? strings.mobileSaving : strings.mobileSave,
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _save() => _submit(_editor.flush);
  Future<void> _restore() => _submit(widget.controller.restoreBackup);

  Future<void> _submit(SettingsSubmit action) async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    final bool saved = await action();
    if (!mounted) return;
    setState(() => _submitting = false);
    if (saved) {
      Navigator.of(context).pop(true);
    } else if (!_editor.hasErrors) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).settingsError)),
      );
    }
  }

  void _onPop(bool didPop, bool? result) {
    if (!didPop) unawaited(_back());
  }

  Future<void> _back() async {
    if (_submitting || _confirming) return;
    if (!_editor.dirty) {
      Navigator.of(context).pop();
      return;
    }
    _confirming = true;
    final bool? discard = await showDialog<bool>(
      context: context,
      builder: _discardDialog,
    );
    _confirming = false;
    if (mounted && discard == true) Navigator.of(context).pop();
  }

  Widget _discardDialog(BuildContext context) => AlertDialog(
    title: Text(AppLocalizations.of(context).mobileDiscardChanges),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(true),
        child: Text(AppLocalizations.of(context).mobileDiscard),
      ),
    ],
  );

  @override
  void dispose() {
    _editor.dispose();
    super.dispose();
  }
}
