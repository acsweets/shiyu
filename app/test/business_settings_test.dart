import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiyu/features/retirement/application/settings_access.dart';
import 'package:shiyu/features/retirement/application/settings_editor.dart';
import 'package:shiyu/features/retirement/data/settings_repository.dart';
import 'package:shiyu/features/retirement/presentation/settings/business_settings_page.dart';
import 'package:shiyu/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('首次引导三步完成并保存完成状态', _verifyOnboarding);
  testWidgets('八语言和大字号可在窄窗构建完整设置', _verifyLocales);
  testWidgets('输入合并自动保存，非法值保留在草稿中', _verifyAutoSave);
}

Future<void> _verifyOnboarding(WidgetTester tester) async {
  final _FakeSettings source = _FakeSettings();
  bool finished = false;
  await tester.pumpWidget(
    _host(
      const Locale('en'),
      BusinessSettingsPage(
        access: source.access,
        initial: source.view(),
        desktop: false,
        onFinished: () => finished = true,
      ),
    ),
  );
  await _tapStep(tester, 'Continue');
  expect(find.text('2 / 3 · Schedule and pay'), findsOneWidget);
  await _tapStep(tester, 'Continue');
  expect(find.text('3 / 3 · Live preview'), findsOneWidget);
  await _tapStep(tester, 'Finish setup');
  expect(finished, isTrue);
  expect(source.values['display'], containsPair('onboarding_completed', true));
}

Future<void> _tapStep(WidgetTester tester, String label) async {
  final Finder button = find.widgetWithText(FilledButton, label);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _verifyLocales(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(360, 720);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final _FakeSettings source = _FakeSettings();
  for (final Locale locale in AppLocalizations.supportedLocales) {
    await tester.pumpWidget(
      _host(
        locale,
        BusinessSettingsPage(
          access: source.access,
          initial: source.view(),
          desktop: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final BuildContext context = tester.element(
      find.byType(BusinessSettingsPage),
    );
    final AppLocalizations strings = AppLocalizations.of(context);
    expect(find.text(strings.businessSettings), findsOneWidget);
    expect(tester.takeException(), isNull);
  }
}

Future<void> _verifyAutoSave(WidgetTester tester) async {
  final _FakeSettings source = _FakeSettings();
  final SettingsEditor editor = SettingsEditor(source.access, source.view());
  addTearDown(editor.dispose);
  editor.change('time_zone', 'Invalid/Zone');
  await tester.pump(const Duration(milliseconds: 450));
  expect(editor.issue('time_zone'), 'invalid_time_zone');
  expect(source.values['time_zone'], 'Asia/Shanghai');
  expect(editor.draft['time_zone'], 'Invalid/Zone');
  editor.change('time_zone', 'Asia/Tokyo');
  editor.change('region', 'JP');
  await tester.pump(const Duration(milliseconds: 450));
  expect(source.values['time_zone'], 'Asia/Tokyo');
  expect(source.values['region'], 'JP');
  expect(source.saves, 2);
  expect(editor.hasErrors, isFalse);
}

Widget _host(Locale locale, Widget home) => MaterialApp(
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  builder: (BuildContext context, Widget? child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.35)),
    child: child!,
  ),
  home: home,
);

class _FakeSettings {
  SettingsValues values = <String, dynamic>{'time_zone': 'Asia/Shanghai'};
  int saves = 0;

  SettingsAccess get access => SettingsAccess(
    read: () async => view(),
    commit: _commit,
    importSettings: (String raw) async => view(saved: false),
    changeCountdown: (SettingsValues value) async => view(),
    peekSalary: () async => null,
  );

  SettingsView view({bool saved = true}) => SettingsView(<Object?, Object?>{
    'values': values,
    'firstRun': true,
    'saved': saved,
    'issues': <Map<String, String>>[
      if (!saved)
        <String, String>{'field': 'time_zone', 'code': 'invalid_time_zone'},
    ],
  });

  Future<SettingsView> _commit(SettingsValues candidate) async {
    saves++;
    if (candidate['time_zone'] == 'Invalid/Zone') return view(saved: false);
    values = candidate;
    return view();
  }
}
