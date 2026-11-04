import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

/// 工程初始化页面，后续由首次引导与真实指标替换。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.hourglass_bottom_rounded, size: 48),
                  const SizedBox(height: 24),
                  Text(strings.appName, style: textTheme.headlineLarge),
                  const SizedBox(height: 16),
                  Text(
                    strings.tagline,
                    style: textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    strings.initializationNotice,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
