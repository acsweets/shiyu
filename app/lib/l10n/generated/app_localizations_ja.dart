// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get holidayData => '祝日データ';

  @override
  String get holidayFallback => '今年のデータがないため、設定した勤務曜日を使用します。';

  @override
  String get holidayChecking => '祝日データを確認中…';

  @override
  String get holidayCheck => '更新を確認';

  @override
  String get holidayImport => 'JSONを読み込む';

  @override
  String get holidayUpdated => '祝日データを更新しました。';

  @override
  String get holidayLatest => '祝日データは最新です。';

  @override
  String get holidayRejected => 'ファイルを検証できませんでした。バージョン、地域、対象年、チェックサムを確認してください。';

  @override
  String get holidayFailed => '更新を確認できませんでした。有効なローカルデータを使います。';

  @override
  String get restoreSettingsBackup => '設定のバックアップを復元';

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

  @override
  String get mobileSettings => '設定';

  @override
  String get mobileAppearance => 'ウィジェットの外観';

  @override
  String get mobileWidget => 'ホーム画面のウィジェット';

  @override
  String get mobileShowTitle => 'タイトルを表示';

  @override
  String get mobileTitleSize => 'タイトルの文字サイズ';

  @override
  String get mobileMacaron => 'マカロン';

  @override
  String get mobileCool => 'クール';

  @override
  String get mobileSunset => 'サンセット';

  @override
  String get mobileSave => '設定を保存';

  @override
  String get mobileSaved => '設定を保存しました';

  @override
  String get mobileAppearanceError => '外観を保存できませんでした。もう一度お試しください。';

  @override
  String get mobileNotSet => '未設定';
}
