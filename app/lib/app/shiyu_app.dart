import 'package:flutter/material.dart';

import '../features/home/presentation/home_page.dart';
import '../l10n/generated/app_localizations.dart';

class ShiyuApp extends StatelessWidget {
  const ShiyuApp({super.key});

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
      home: const HomePage(),
    );
  }
}

String _localizedTitle(BuildContext context) {
  return AppLocalizations.of(context).appName;
}
