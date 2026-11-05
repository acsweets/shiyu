import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// No description provided for @appName.
  ///
  /// In zh, this message translates to:
  /// **'时余'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In zh, this message translates to:
  /// **'感知时间，留住生活。'**
  String get tagline;

  /// No description provided for @initializationNotice.
  ///
  /// In zh, this message translates to:
  /// **'工程已就绪，时间与薪资功能正在构建中。'**
  String get initializationNotice;

  /// No description provided for @retirementTitle.
  ///
  /// In zh, this message translates to:
  /// **'退休倒计时'**
  String get retirementTitle;

  /// No description provided for @retired.
  ///
  /// In zh, this message translates to:
  /// **'已退休'**
  String get retired;

  /// No description provided for @daysRemaining.
  ///
  /// In zh, this message translates to:
  /// **'天后退休'**
  String get daysRemaining;

  /// No description provided for @chooseRetirement.
  ///
  /// In zh, this message translates to:
  /// **'选择退休日期'**
  String get chooseRetirement;

  /// No description provided for @configure.
  ///
  /// In zh, this message translates to:
  /// **'配置'**
  String get configure;

  /// No description provided for @hideWindow.
  ///
  /// In zh, this message translates to:
  /// **'隐藏浮窗'**
  String get hideWindow;

  /// No description provided for @timeZoneLabel.
  ///
  /// In zh, this message translates to:
  /// **'IANA 时区'**
  String get timeZoneLabel;

  /// No description provided for @saveSettings.
  ///
  /// In zh, this message translates to:
  /// **'保存时区'**
  String get saveSettings;

  /// No description provided for @clearTarget.
  ///
  /// In zh, this message translates to:
  /// **'清除日期'**
  String get clearTarget;

  /// No description provided for @addWidget.
  ///
  /// In zh, this message translates to:
  /// **'添加桌面小组件'**
  String get addWidget;

  /// No description provided for @widgetInstructions.
  ///
  /// In zh, this message translates to:
  /// **'长按手机桌面，添加“时余 · 退休倒计时”小组件。'**
  String get widgetInstructions;

  /// No description provided for @settingsError.
  ///
  /// In zh, this message translates to:
  /// **'设置或共享数据操作失败，请检查日期、时区和存储权限后重试。'**
  String get settingsError;

  /// No description provided for @calendarFallback.
  ///
  /// In zh, this message translates to:
  /// **'节假日数据尚未接入，当前按每周工作日设置计算。'**
  String get calendarFallback;

  /// No description provided for @currentSlice.
  ///
  /// In zh, this message translates to:
  /// **'当前已接入退休倒计时，其他内置指标将在后续节点提供。'**
  String get currentSlice;

  /// No description provided for @mobileSettings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get mobileSettings;

  /// No description provided for @mobileAppearance.
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get mobileAppearance;

  /// No description provided for @mobileWidget.
  ///
  /// In zh, this message translates to:
  /// **'主屏幕小组件'**
  String get mobileWidget;

  /// No description provided for @mobileShowCard.
  ///
  /// In zh, this message translates to:
  /// **'显示浮窗'**
  String get mobileShowCard;

  /// No description provided for @mobileShowTitle.
  ///
  /// In zh, this message translates to:
  /// **'显示标题'**
  String get mobileShowTitle;

  /// No description provided for @mobileTitleSize.
  ///
  /// In zh, this message translates to:
  /// **'提示文字大小'**
  String get mobileTitleSize;

  /// No description provided for @mobileMacaron.
  ///
  /// In zh, this message translates to:
  /// **'马卡龙色系'**
  String get mobileMacaron;

  /// No description provided for @mobileCool.
  ///
  /// In zh, this message translates to:
  /// **'冷酷色系'**
  String get mobileCool;

  /// No description provided for @mobileSunset.
  ///
  /// In zh, this message translates to:
  /// **'日落暖调'**
  String get mobileSunset;

  /// No description provided for @mobileSave.
  ///
  /// In zh, this message translates to:
  /// **'保存设置'**
  String get mobileSave;

  /// No description provided for @mobileSaved.
  ///
  /// In zh, this message translates to:
  /// **'设置已保存'**
  String get mobileSaved;

  /// No description provided for @mobileAppearanceError.
  ///
  /// In zh, this message translates to:
  /// **'外观未能保存，请重试。'**
  String get mobileAppearanceError;

  /// No description provided for @mobileCountdown.
  ///
  /// In zh, this message translates to:
  /// **'{days} 天 {clock}'**
  String mobileCountdown(String days, String clock);

  /// No description provided for @mobileCardHidden.
  ///
  /// In zh, this message translates to:
  /// **'浮窗已隐藏'**
  String get mobileCardHidden;

  /// No description provided for @mobileResetPosition.
  ///
  /// In zh, this message translates to:
  /// **'重置浮窗位置'**
  String get mobileResetPosition;

  /// No description provided for @mobileNotSet.
  ///
  /// In zh, this message translates to:
  /// **'未设置'**
  String get mobileNotSet;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'ja',
    'ko',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
