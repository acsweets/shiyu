import '../data/holiday_repository.dart';
import '../data/settings_repository.dart';
import 'holiday_status.dart';
import 'retirement_controller.dart';

typedef SettingsCommit = Future<SettingsView> Function(SettingsValues settings);
typedef SettingsImport = Future<SettingsView> Function(String raw);
typedef SettingsPreview = Future<SettingsView> Function();
typedef SalaryPeek = Future<SettingsValues?> Function();
typedef SettingsHolidayCheck = Future<HolidayUpdate> Function();
typedef SettingsHolidayImport = Future<HolidayUpdate> Function(String raw);

/// 设置编辑器与主引擎之间的共享界面契约。
class SettingsView {
  const SettingsView(this.data);

  factory SettingsView.fromController(
    RetirementController controller, {
    bool saved = true,
  }) => SettingsView(<Object?, Object?>{
    'values': controller.settings,
    'snapshot': controller.snapshot?.data,
    'firstRun': controller.needsOnboarding,
    'blocked': controller.editingBlocked,
    'saved': saved,
    if (controller.holidays != null)
      'holiday': HolidayStatus.fromController(controller).data,
    'issues': <Map<String, String>>[
      for (final SettingsIssue issue in controller.settingsIssues)
        <String, String>{'field': issue.field, 'code': issue.code},
    ],
  });

  final Map<Object?, Object?> data;

  SettingsValues get values =>
      (data['values'] as Map<Object?, Object?>).cast<String, dynamic>();
  SettingsValues get snapshot =>
      (data['snapshot'] as Map<Object?, Object?>?)?.cast<String, dynamic>() ??
      <String, dynamic>{};
  bool get firstRun => data['firstRun'] == true;
  bool get blocked => data['blocked'] == true;
  bool get saved => data['saved'] == true;
  HolidayStatus? get holiday {
    final Object? raw = data['holiday'];
    return raw is Map<Object?, Object?> ? HolidayStatus(raw) : null;
  }

  List<SettingsIssue> get issues => <SettingsIssue>[
    for (final Object? issue in data['issues'] as List<Object?>)
      (
        field: (issue as Map<Object?, Object?>)['field'] as String,
        code: issue['code'] as String,
      ),
  ];
}

class SettingsAccess {
  const SettingsAccess({
    required this.read,
    required this.commit,
    required this.importSettings,
    required this.changeCountdown,
    required this.peekSalary,
    this.checkHolidays,
    this.importHoliday,
  });

  factory SettingsAccess.local(RetirementController controller) =>
      SettingsAccess(
        read: () async {
          await controller.refresh();
          return SettingsView.fromController(controller);
        },
        commit: (SettingsValues values) async {
          final bool saved = await controller.saveSettings(values);
          return SettingsView.fromController(controller, saved: saved);
        },
        importSettings: (String raw) async {
          final bool saved = await controller.importSettings(raw);
          return SettingsView.fromController(controller, saved: saved);
        },
        changeCountdown: (SettingsValues change) async {
          final bool saved = await controller.changeCountdown(change);
          return SettingsView.fromController(controller, saved: saved);
        },
        peekSalary: controller.peekSalary,
        checkHolidays: controller.checkHolidayUpdates,
        importHoliday: controller.importHolidayPack,
      );

  final SettingsPreview read;
  final SettingsCommit commit;
  final SettingsImport importSettings;
  final SettingsCommit changeCountdown;
  final SalaryPeek peekSalary;
  final SettingsHolidayCheck? checkHolidays;
  final SettingsHolidayImport? importHoliday;
}
