import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/holiday_repository.dart';
import '../data/settings_repository.dart';
import 'settings_access.dart';

/// 表单草稿独立于已保存配置。输入无效时保留草稿与字段错误。
class SettingsEditor extends ChangeNotifier {
  SettingsEditor(this.access, SettingsView initial, {this.autosave = true})
    : _view = initial,
      draft = initial.values;

  final SettingsAccess access;

  /// 手机详情页在用户明确保存后提交草稿。
  final bool autosave;
  SettingsView _view;
  SettingsValues draft;
  Timer? _delay;
  Future<void> _pending = Future<void>.value();
  int _revision = 0;
  int _submitted = 0;

  /// 最近一次成功保存的草稿版本。
  int _savedRevision = 0;
  bool _disposed = false;
  bool saving = false;
  bool _replacing = false;
  int generation = 0;

  SettingsView get view => _view;
  bool get blocked => _view.blocked;
  bool get hasErrors => !_view.saved;
  bool get dirty => _revision != _savedRevision;

  SettingsValues group(String key) => object(draft[key]);

  static SettingsValues object(Object? raw) =>
      (raw as Map<Object?, Object?>?)?.cast<String, dynamic>() ??
      <String, dynamic>{};

  String? issue(String field) {
    for (final SettingsIssue issue in _view.issues) {
      if (issue.field == field) return issue.code;
    }
    return null;
  }

  void change(String field, Object? value) {
    if (blocked || _replacing) return;
    draft = <String, dynamic>{...draft, field: value};
    if (_view.firstRun && group('display')['onboarding_completed'] == null) {
      draft['display'] = <String, dynamic>{
        ...group('display'),
        'onboarding_completed': false,
      };
    }
    _revision++;
    _delay?.cancel();
    if (autosave) _delay = Timer(const Duration(milliseconds: 450), _submit);
    notifyListeners();
  }

  void changeGroup(String key, String field, Object? value) =>
      change(key, <String, dynamic>{...group(key), field: value});

  Future<bool> flush() async {
    _delay?.cancel();
    if (!autosave && hasErrors && !saving) _submitted = _savedRevision;
    _submit();
    await _pending;
    return _view.saved;
  }

  void _submit() {
    if (_disposed || _revision == _submitted) return;
    final SettingsValues candidate = draft;
    final int revision = _revision;
    _submitted = revision;
    _pending = _pending.then((void _) => _save(candidate, revision));
  }

  Future<void> _save(SettingsValues candidate, int revision) async {
    if (_disposed) return;
    saving = true;
    notifyListeners();
    try {
      _view = await access.commit(candidate);
      if (_view.saved) {
        _savedRevision = revision;
        if (_revision == revision) draft = _view.values;
      }
    } catch (_) {
      _view = SettingsView(<Object?, Object?>{..._view.data, 'saved': false});
    } finally {
      saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> reloadFromFile(String raw) =>
      _replace(() => access.importSettings(raw), acceptInvalidDraft: true);

  Future<bool> editCountdown(SettingsValues change) =>
      _replace(() => access.changeCountdown(change));

  Future<HolidayUpdate> updateCalendar(SettingsHolidayCheck? action) async {
    if (action == null || !await flush() || _disposed) {
      return HolidayUpdate.failed;
    }
    final HolidayUpdate result = await action();
    final SettingsView refreshed = await access.read();
    if (!_disposed) {
      _view = SettingsView(<Object?, Object?>{
        ..._view.data,
        'holiday': refreshed.data['holiday'],
      });
      notifyListeners();
    }
    return result;
  }

  Future<bool> _replace(
    SettingsPreview operation, {
    bool acceptInvalidDraft = false,
  }) async {
    if (_replacing) return false;
    _replacing = true;
    try {
      return await _applyReplacement(operation, acceptInvalidDraft);
    } finally {
      _replacing = false;
    }
  }

  Future<bool> _applyReplacement(
    SettingsPreview operation,
    bool acceptInvalidDraft,
  ) async {
    final bool valid = await flush();
    if (!valid && !acceptInvalidDraft) return false;
    if (_disposed) return false;
    saving = true;
    notifyListeners();
    try {
      final SettingsView result = await operation();
      if (!_disposed && result.saved) {
        _view = result;
        draft = result.values;
        _savedRevision = _revision;
        _submitted = _revision;
        generation++;
      }
      return result.saved;
    } finally {
      saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _delay?.cancel();
    super.dispose();
  }
}
