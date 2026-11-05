import 'package:flutter/material.dart';

import 'theme/mobile_paper.dart';

import '../features/retirement/application/retirement_controller.dart';
import '../features/retirement/application/settings_access.dart';
import '../features/retirement/presentation/mobile_dashboard.dart';
import '../features/retirement/presentation/settings/business_settings_page.dart';
import '../features/desktop_stickers/presentation/desktop_sticker_page.dart';
import '../features/desktop_stickers/data/sticker_layout.dart';
import '../platform/desktop/floating_window_controller.dart';
import '../l10n/generated/app_localizations.dart';

class ShiyuApp extends StatelessWidget {
  const ShiyuApp({
    required this.controller,
    this.window,
    this.desktopLayout,
    this.onboarding = false,
    this.startupPack,
    this.locale,
    super.key,
  });

  /// 全端共用的设置和核心快照控制器。
  final RetirementController controller;

  /// 非桌面平台为空。
  final FloatingWindowController? window;

  /// 集成测试的独立桌面布局存储。
  final StickerLayout? desktopLayout;
  final bool onboarding;
  final String? startupPack;
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      onGenerateTitle: _localizedTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const <Locale>[
        Locale('zh'),
        Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        Locale('en'),
        Locale('ja'),
        Locale('ko'),
        Locale('es'),
        Locale('de'),
        Locale('fr'),
      ],
      theme: window == null
          ? mobilePaperTheme
          : ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFC68A59),
              ),
              useMaterial3: true,
            ),
      home: window == null
          ? _MobileStartup(controller: controller, onboarding: onboarding)
          : DesktopStickerPage(
              controller: controller,
              window: window!,
              layout: desktopLayout,
              onboarding: onboarding,
              startupPack: startupPack,
            ),
    );
  }
}

class _MobileStartup extends StatefulWidget {
  const _MobileStartup({required this.controller, required this.onboarding});

  final RetirementController controller;
  final bool onboarding;

  @override
  State<_MobileStartup> createState() => _MobileStartupState();
}

class _MobileStartupState extends State<_MobileStartup> {
  late bool _showWizard =
      widget.onboarding && widget.controller.needsOnboarding;

  @override
  Widget build(BuildContext context) => _showWizard
      ? BusinessSettingsPage(
          access: SettingsAccess.local(widget.controller),
          initial: SettingsView.fromController(widget.controller),
          desktop: false,
          onFinished: _finish,
        )
      : MobileDashboard(controller: widget.controller);

  void _finish() => setState(() => _showWizard = false);
}

String _localizedTitle(BuildContext context) {
  return AppLocalizations.of(context).appName;
}
