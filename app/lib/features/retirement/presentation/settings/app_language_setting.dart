import 'package:flutter/material.dart';

import '../../../../app/settings_locale.dart';
import '../../../../l10n/generated/app_localizations.dart';

typedef AppLanguageSave = Future<bool> Function(String? locale);

/// 以已保存的设置作为选中值，保存失败时保留原选择。
class AppLanguageSetting extends StatefulWidget {
  const AppLanguageSetting({
    required this.locale,
    required this.save,
    super.key,
  });

  /// 空值表示跟随系统。
  final String? locale;

  /// 当前设置可编辑时提供持久化入口。
  final AppLanguageSave? save;

  @override
  State<AppLanguageSetting> createState() => _AppLanguageSettingState();
}

class _AppLanguageSettingState extends State<AppLanguageSetting> {
  /// 单次保存结束前禁用下拉框。
  bool _saving = false;

  @override
  Widget build(BuildContext context) => AppLanguageChoice(
    locale: widget.locale,
    changed: _saving || widget.save == null ? null : _change,
  );

  Future<void> _change(String? locale) async {
    final AppLanguageSave? save = widget.save;
    if (save == null || locale == widget.locale || _saving) return;
    setState(() => _saving = true);
    bool saved = false;
    try {
      saved = await save(locale);
    } catch (_) {
      // 写入或跨窗口通讯失败统一提示。
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).settingsError)),
      );
    }
  }
}

/// 顶层设置和完整设置使用相同的语言列表和当前值。
class AppLanguageChoice extends StatelessWidget {
  const AppLanguageChoice({
    required this.locale,
    required this.changed,
    super.key,
  });

  /// 空值表示跟随系统。
  final String? locale;

  /// 空回调表示当前不可修改。
  final ValueChanged<String?>? changed;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: strings.appLanguage,
        enabled: changed != null,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          key: const ValueKey<String>('app-language-picker'),
          value: appLanguageNames.containsKey(locale) ? locale : '',
          isExpanded: true,
          isDense: true,
          items: <DropdownMenuItem<String>>[
            DropdownMenuItem<String>(
              value: '',
              child: Text(strings.systemLanguage),
            ),
            for (final MapEntry<String, String> language
                in appLanguageNames.entries)
              DropdownMenuItem<String>(
                value: language.key,
                child: Text(language.value),
              ),
          ],
          onChanged: changed == null ? null : _choose,
        ),
      ),
    );
  }

  void _choose(String? code) {
    if (code != null) changed?.call(code.isEmpty ? null : code);
  }
}
