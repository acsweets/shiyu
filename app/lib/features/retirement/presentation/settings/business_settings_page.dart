import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/settings_access.dart';
import '../../application/settings_editor.dart';
import 'calendar_settings.dart';
import 'display_settings.dart';
import 'general_settings.dart';
import 'personal_settings.dart';
import 'settings_preview.dart';
import 'work_settings.dart';

enum _Section { personal, work, calendar, display, general, preview }

class BusinessSettingsPage extends StatefulWidget {
  const BusinessSettingsPage({
    required this.access,
    required this.initial,
    required this.desktop,
    this.onFinished,
    super.key,
  });

  final SettingsAccess access;
  final SettingsView initial;
  final bool desktop;
  final VoidCallback? onFinished;

  @override
  State<BusinessSettingsPage> createState() => _BusinessSettingsPageState();
}

class _BusinessSettingsPageState extends State<BusinessSettingsPage> {
  late final SettingsEditor _editor = SettingsEditor(
    widget.access,
    widget.initial,
  );
  _Section _section = _Section.personal;
  SettingsView? _preview;
  bool _closing = false;
  bool _advancing = false;
  final ScrollController _scroll = ScrollController();

  bool get _wizard => widget.onFinished != null;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: _onPop,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: _wizard ? null : BackButton(onPressed: _close),
          title: Text(
            _wizard ? strings.onboardingTitle : strings.businessSettings,
          ),
        ),
        body: SafeArea(
          top: false,
          child: ListenableBuilder(listenable: _editor, builder: _body),
        ),
        bottomNavigationBar: _wizard
            ? SafeArea(
                top: false,
                child: ListenableBuilder(
                  listenable: _editor,
                  builder: _wizardActions,
                ),
              )
            : null,
      ),
    );
  }

  Widget _body(BuildContext context, Widget? child) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 32),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: <Widget>[
            if (_wizard) _steps(strings) else _navigation(strings),
            const SizedBox(height: 20),
            if (_editor.blocked)
              Text(strings.settingsError)
            else if (_editor.hasErrors)
              Text(
                strings.invalidDraft,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (_editor.saving) const LinearProgressIndicator(),
            KeyedSubtree(
              key: ValueKey<String>('${_section.name}-${_editor.generation}'),
              child: _sectionBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _steps(AppLocalizations strings) {
    final int step = switch (_section) {
      _Section.personal => 1,
      _Section.work => 2,
      _ => 3,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        LinearProgressIndicator(value: step / 3),
        const SizedBox(height: 12),
        Text('$step / 3 · ${_label(strings, _section)}'),
      ],
    );
  }

  Widget _navigation(AppLocalizations strings) => Wrap(
    spacing: 8,
    runSpacing: 6,
    children: <Widget>[
      for (final _Section section in _Section.values)
        if (section != _Section.preview)
          ChoiceChip(
            label: Text(_label(strings, section)),
            selected: _section == section,
            onSelected: (bool _) => _select(section),
          ),
    ],
  );

  String _label(AppLocalizations strings, _Section section) =>
      switch (section) {
        _Section.personal => strings.personalSection,
        _Section.work => strings.workSection,
        _Section.calendar => strings.calendarSection,
        _Section.display =>
          widget.desktop
              ? strings.displaySection
              : strings.metricTitleVisibility,
        _Section.general => strings.generalSection,
        _Section.preview => strings.previewLive,
      };

  Widget _sectionBody() => switch (_section) {
    _Section.personal => PersonalSettings(editor: _editor),
    _Section.work => WorkSettings(editor: _editor),
    _Section.calendar => CalendarSettings(editor: _editor),
    _Section.display => DisplaySettingsForm(
      editor: _editor,
      desktop: widget.desktop,
    ),
    _Section.general => GeneralSettings(editor: _editor),
    _Section.preview => SettingsSnapshotPreview(
      snapshot: (_preview ?? _editor.view).snapshot,
    ),
  };

  Widget _wizardActions(BuildContext context, Widget? child) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
    child: Wrap(
      spacing: 10,
      children: <Widget>[
        if (_section != _Section.personal)
          OutlinedButton(
            onPressed: _editor.saving ? null : _back,
            child: Text(AppLocalizations.of(context).backStep),
          ),
        FilledButton(
          onPressed: _editor.saving || _advancing ? null : _advance,
          child: Text(
            _section == _Section.preview
                ? AppLocalizations.of(context).finishSetup
                : AppLocalizations.of(context).nextStep,
          ),
        ),
      ],
    ),
  );

  void _select(_Section value) {
    unawaited(_editor.flush());
    if (_scroll.hasClients) _scroll.jumpTo(0);
    setState(() => _section = value);
  }

  void _back() =>
      _select(_section == _Section.preview ? _Section.work : _Section.personal);

  Future<void> _advance() async {
    if (_advancing) return;
    setState(() => _advancing = true);
    try {
      if (!await _editor.flush() || !mounted) return;
      switch (_section) {
        case _Section.personal:
          _select(_Section.work);
        case _Section.work:
          _preview = await widget.access.read();
          if (mounted) _select(_Section.preview);
        case _Section.preview:
          _editor.changeGroup('display', 'onboarding_completed', true);
          if (await _editor.flush() && mounted) widget.onFinished?.call();
        default:
          return;
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).settingsError)),
        );
      }
    } finally {
      if (mounted) setState(() => _advancing = false);
    }
  }

  void _onPop(bool didPop, Object? result) {
    if (!didPop && !_wizard) unawaited(_close());
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    await _editor.flush();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _editor.dispose();
    super.dispose();
  }
}
