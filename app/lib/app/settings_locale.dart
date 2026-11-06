import 'dart:ui';

/// 按各语言自己的写法显示名称，方便在陌生界面中切回。
const Map<String, String> appLanguageNames = <String, String>{
  'zh': '简体中文',
  'zh-Hant': '繁體中文',
  'en': 'English',
  'ja': '日本語',
  'ko': '한국어',
  'es': 'Español',
  'de': 'Deutsch',
  'fr': 'Français',
};

Locale? settingsLocale(String? value) {
  if (value == null || value.isEmpty) return null;
  if (value == 'zh-Hant') {
    return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');
  }
  return Locale(value);
}
