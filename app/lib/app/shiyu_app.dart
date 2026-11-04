import 'package:flutter/material.dart';

import '../features/retirement/application/retirement_controller.dart';
import '../features/retirement/presentation/retirement_page.dart';
import '../platform/desktop/floating_window_controller.dart';
import '../l10n/generated/app_localizations.dart';

class ShiyuApp extends StatelessWidget {
  const ShiyuApp({required this.controller, this.window, super.key});

  /// 全端共用的设置和核心快照控制器。
  final RetirementController controller;

  /// 非桌面平台为空。
  final FloatingWindowController? window;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF477568)),
        useMaterial3: true,
      ),
      home: RetirementPage(controller: controller, window: window),
    );
  }
}

String _localizedTitle(BuildContext context) {
  return AppLocalizations.of(context).appName;
}
