// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get mobileMacaronGlass => 'マカロンガラス';

  @override
  String get mobileCountdownSummary => '退職日、誕生日、人生の表示方法';

  @override
  String get mobileWorkSummary => '勤務日、勤務時間、昼休み、給与';

  @override
  String get mobileCalendarSummary => '給料日、祝日の地域、例外日';

  @override
  String get mobileTitlesSummary => '項目ごとにタイトルの表示を切り替え';

  @override
  String get mobileWidgetSummary => 'ウィジェットの追加、配色、文字サイズ';

  @override
  String get mobileGeneralSummary => 'タイムゾーン、金額の表示、バックアップ';

  @override
  String get mobileSaving => '保存中…';

  @override
  String get mobileDiscardChanges => '未保存の変更を破棄しますか？';

  @override
  String get mobileDiscard => '変更を破棄';

  @override
  String get metricTitleVisibility => '項目ごとのタイトル表示';

  @override
  String get metricTitleVisibilityDetail =>
      'タイトルを非表示にしても数値は表示されます。フローティングウィンドウとウィジェットにもタイトルの一括設定があります。';

  @override
  String get lifeDisplayMode => '人生の表示モード';

  @override
  String get lifeElapsedTitle => '生まれてからの日数';

  @override
  String lifeElapsedValue(num days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return '$daysString 日';
  }

  @override
  String get desktopAppearance => '外観';

  @override
  String get desktopWindows => 'ウィンドウ管理';

  @override
  String get desktopCountdowns => 'カウントダウン';

  @override
  String get desktopCatAssets => '猫のステッカー';

  @override
  String get desktopAppearanceDescription =>
      '言語、配色、文字サイズを変更し、フローティングウィンドウを確認します。';

  @override
  String get desktopWindowsDescription => '各ウィンドウの内容を確認し、結合、分割、表示調整ができます。';

  @override
  String get desktopCountdownsDescription => 'デスクトップのカウントダウンを選び、退職日を設定します。';

  @override
  String get desktopCatAssetsDescription => 'ウィンドウごとに猫のステッカーを変更できます。';

  @override
  String get floatingMode => 'ウィンドウモード';

  @override
  String get modeMini => 'ミニ';

  @override
  String get modeStandard => '標準';

  @override
  String get modeExpanded => '拡張';

  @override
  String get countdownExpired => '終了';

  @override
  String get holidayOngoing => '休暇中';

  @override
  String get paydayToday => '今日は給料日';

  @override
  String get metricUnavailable => '利用できません';

  @override
  String get noVisibleMetrics => '項目はすべて非表示です';

  @override
  String get untilWorkStart => '始業まで';

  @override
  String get untilWorkEnd => '終業まで';

  @override
  String get untilLunchEnd => '休憩終了まで';

  @override
  String get addCountdown => 'カウントダウンを追加';

  @override
  String get addDateOverride => '日付の扱いを変更';

  @override
  String get addHoliday => '休暇を追加';

  @override
  String get appLanguage => '表示言語';

  @override
  String get backStep => '戻る';

  @override
  String get birthDate => '生年月日（任意）';

  @override
  String get birthTime => '出生時刻（任意）';

  @override
  String get businessSettings => '詳細設定';

  @override
  String get calendarSection => '日付と休暇';

  @override
  String get currencyCode => '通貨コード';

  @override
  String get customCountdown => 'カスタムカウントダウン';

  @override
  String get customHolidays => 'カスタム休暇';

  @override
  String get dateLabel => '日付';

  @override
  String get dateOverrides => '日付の上書き';

  @override
  String get dayType => '日付の種類';

  @override
  String get disableAll => 'すべて非表示';

  @override
  String get displaySection => 'フローティングウィンドウ';

  @override
  String get enableAll => 'すべて表示';

  @override
  String get exportPrivacy => 'エクスポートには個人情報と給与が含まれます。安全な保存先を選んでください。';

  @override
  String get finishSetup => '設定を完了';

  @override
  String get fixedPayday => '毎月の指定日';

  @override
  String get generalSection => '一般';

  @override
  String get grossMonthly => '月給（税引前）';

  @override
  String get hideSalary => '金額を隠す';

  @override
  String get holidayEnd => '終了日';

  @override
  String get holidayKind => '休暇の種類';

  @override
  String get holidayStart => '開始日';

  @override
  String get invalidCountdown => '名前と時刻を確認してください。新しい目標は未来の日時を指定します。';

  @override
  String get invalidDraft => '入力欄を確認してください。前回の有効な設定は保持されています。';

  @override
  String get invalidHoliday => '名前、種類、正しい日付範囲を指定してください。';

  @override
  String get invalidLifespan => '1～150 年を小数第1位まで入力してください。';

  @override
  String get invalidLunch => '休憩時間は勤務時間内に設定してください。';

  @override
  String get invalidPaydays => '1～31 の異なる日を指定してください。';

  @override
  String get invalidSalary => '0 以上の有効な金額を入力してください。';

  @override
  String get invalidValue => '入力値を確認してください。';

  @override
  String get invalidWorkHours => 'HH:mm 形式で、同日の開始より後の終了時刻を指定してください。';

  @override
  String get itemName => '名前';

  @override
  String get lastWorkday => '月の最終勤務日';

  @override
  String get lifeExpectancy => '想定寿命（年）';

  @override
  String get lunchBreak => '昼休み';

  @override
  String get lunchEnd => '休憩終了';

  @override
  String get lunchStart => '休憩開始';

  @override
  String get metricHoliday => '次の休暇まで';

  @override
  String get metricLife => '人生カウントダウン';

  @override
  String get metricMonthSalary => '今月の収入';

  @override
  String get metricPayday => '給料日まで';

  @override
  String get metricTodaySalary => '今日の収入';

  @override
  String get metricWork => '勤務カウントダウン';

  @override
  String get miniMetrics => 'ミニウィンドウの項目';

  @override
  String get moveDown => '下へ移動';

  @override
  String get moveUp => '上へ移動';

  @override
  String get netMonthly => '手取り月給（任意）';

  @override
  String get netRequired => '手取りを選ぶ前に手取り月給を入力してください。';

  @override
  String get nextStep => '次へ';

  @override
  String get nextWorkday => '翌勤務日';

  @override
  String get noAdjustment => '日付を維持';

  @override
  String get onboardingTitle => 'Shiyu を設定';

  @override
  String get paydayAdjustment => '給料日が休日の場合';

  @override
  String get paydayDate => '給料日';

  @override
  String get paydayRule => '給料日の設定';

  @override
  String get peekSalary => '金額を一時表示';

  @override
  String get personalSection => '個人情報';

  @override
  String get previewLive => '実データのプレビュー';

  @override
  String get previousWorkday => '前の勤務日';

  @override
  String get regionCN => '中国本土';

  @override
  String get regionHK => '香港';

  @override
  String get regionJP => '日本';

  @override
  String get regionKR => '韓国';

  @override
  String get regionLabel => '祝日の地域';

  @override
  String get regionTW => '台湾';

  @override
  String get regionUS => '米国';

  @override
  String get removeItem => '削除';

  @override
  String get restDayLabel => '休日';

  @override
  String get salaryBasis => '給与の表示基準';

  @override
  String get salaryPrecision => '小数点以下の桁数';

  @override
  String get settingsExport => '設定を書き出す';

  @override
  String get settingsExported => '設定を書き出しました。';

  @override
  String get settingsFileInvalid => 'ファイルを使用できません。サイズ、JSON 形式、バージョンを確認してください。';

  @override
  String get settingsImport => '設定を読み込む';

  @override
  String get systemLanguage => 'システム言語';

  @override
  String get targetTime => '目標時刻';

  @override
  String get twiceMonthly => '月に2回';

  @override
  String get weeklyRestHoliday => '毎週の休日も休暇に含める';

  @override
  String get workdayLabel => '勤務日';

  @override
  String get workEnd => '終業時刻';

  @override
  String get workSection => '勤務と給与';

  @override
  String get workStart => '始業時刻';

  @override
  String get workWeek => '勤務曜日';

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
  String get durationDays => '日';

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
  String get timeZoneSearch => 'タイムゾーンを検索';

  @override
  String get timeZoneNoMatches => '一致するタイムゾーンがありません';

  @override
  String get showTodayEarnings => '今日の給与を表示';

  @override
  String get hideEarningsDetail => '今日と今月の金額を **** で隠します。';

  @override
  String get saveSettings => 'タイムゾーンを保存';

  @override
  String get clearTarget => '日付をクリア';

  @override
  String get addWidget => 'カウントダウンを追加';

  @override
  String get addSalaryWidget => '給与ウィジェットを追加';

  @override
  String get widgetInstructions =>
      'ホーム画面を長押しして時余のウィジェットを追加します。編集できる場合は、カウントダウンや給与から最大4項目を選べます。個別に表示するには、ウィジェットを項目ごとに追加します。';

  @override
  String get widgetPinRequested =>
      '追加をリクエストしました。ホーム画面で確認してください。確認画面が出ない場合は、ホーム画面の空いている場所を長押しし、「ウィジェット」から「时余（Shiyu）」を選んでください。';

  @override
  String get widgetPinManual =>
      'ホーム画面でリクエストを受け付けられませんでした。空いている場所を長押しし、「ウィジェット」から「时余（Shiyu）」を選んでください。';

  @override
  String get widgetOpenHome => 'ホーム画面へ';

  @override
  String get refreshEarnings => '給与を更新';

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
