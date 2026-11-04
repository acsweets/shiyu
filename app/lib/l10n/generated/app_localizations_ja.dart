// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => '時余';

  @override
  String get tagline => '時間を感じ、暮らしを大切に。';

  @override
  String get initializationNotice => 'アプリの基盤が整いました。時間と給与の機能は開発中です。';

  @override
  String get retirementTitle => '退職までのカウントダウン';

  @override
  String get retired => '退職済み';

  @override
  String get daysRemaining => '日後に退職';

  @override
  String get chooseRetirement => '退職日を選択';

  @override
  String get configure => '設定';

  @override
  String get hideWindow => 'ウィンドウを隠す';

  @override
  String get timeZoneLabel => 'IANA タイムゾーン';

  @override
  String get saveSettings => 'タイムゾーンを保存';

  @override
  String get clearTarget => '日付をクリア';

  @override
  String get addWidget => 'ホーム画面にウィジェットを追加';

  @override
  String get widgetInstructions => 'ホーム画面を長押しして、Shiyu の退職ウィジェットを追加してください。';

  @override
  String get settingsError => '日付、タイムゾーン、共有ストレージを確認して再試行してください。';

  @override
  String get calendarFallback => '祝日データは未接続のため、設定された毎週の勤務日を使用します。';

  @override
  String get currentSlice => '現在は退職カウントダウンに対応しています。他の指標は今後追加予定です。';
}
