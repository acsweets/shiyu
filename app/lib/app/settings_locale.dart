import 'dart:ui';

Locale? settingsLocale(String? value) {
  if (value == null || value.isEmpty) return null;
  if (value == 'zh-Hant') {
    return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');
  }
  return Locale(value);
}
