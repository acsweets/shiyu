import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiyu/features/retirement/presentation/mobile_widget_settings_page.dart';
import 'package:shiyu/l10n/generated/app_localizations.dart';
import 'package:shiyu/platform/widgets/widget_bridge.dart';

void main() {
  testWidgets('桌面接收请求后仍提示确认和手动添加', _verifyAcceptedRequest);
  testWidgets('桌面拒绝请求后可前往桌面手动添加', _verifyManualFallback);
}

Future<void> _verifyAcceptedRequest(WidgetTester tester) async {
  final _LauncherBridge bridge = _LauncherBridge(accepted: true);
  final AppLocalizations strings = await _openPage(tester, bridge);

  await tester.tap(find.text(strings.addWidget));
  await tester.pumpAndSettle();

  expect(bridge.requestedSalary, isFalse);
  expect(find.text(strings.widgetPinRequested), findsOneWidget);
  expect(find.text(strings.widgetOpenHome), findsOneWidget);
}

Future<void> _verifyManualFallback(WidgetTester tester) async {
  final _LauncherBridge bridge = _LauncherBridge(accepted: false);
  final AppLocalizations strings = await _openPage(tester, bridge);

  await tester.tap(find.text(strings.addSalaryWidget));
  await tester.pumpAndSettle();
  expect(bridge.requestedSalary, isTrue);
  expect(find.text(strings.widgetPinManual), findsOneWidget);

  await tester.tap(find.text(strings.widgetOpenHome));
  await tester.pumpAndSettle();
  expect(bridge.homeOpened, isTrue);
}

Future<AppLocalizations> _openPage(
  WidgetTester tester,
  WidgetBridge bridge,
) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MobileWidgetSettingsPage(bridge: bridge),
    ),
  );
  await tester.pumpAndSettle();
  return AppLocalizations.of(
    tester.element(find.byType(MobileWidgetSettingsPage)),
  );
}

class _LauncherBridge extends WidgetBridge {
  _LauncherBridge({required this.accepted});

  final bool accepted;
  bool? requestedSalary;
  bool homeOpened = false;

  @override
  bool get offersPin => true;

  @override
  Future<bool> pin({bool salary = false}) async {
    requestedSalary = salary;
    return accepted;
  }

  @override
  Future<void> openHomeScreen() async {
    homeOpened = true;
  }
}
