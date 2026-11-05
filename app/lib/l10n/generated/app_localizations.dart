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

  /// No description provided for @floatingMode.
  ///
  /// In zh, this message translates to:
  /// **'窗口形态'**
  String get floatingMode;

  /// No description provided for @modeMini.
  ///
  /// In zh, this message translates to:
  /// **'迷你'**
  String get modeMini;

  /// No description provided for @modeStandard.
  ///
  /// In zh, this message translates to:
  /// **'标准'**
  String get modeStandard;

  /// No description provided for @modeExpanded.
  ///
  /// In zh, this message translates to:
  /// **'展开'**
  String get modeExpanded;

  /// No description provided for @countdownExpired.
  ///
  /// In zh, this message translates to:
  /// **'已到期'**
  String get countdownExpired;

  /// No description provided for @holidayOngoing.
  ///
  /// In zh, this message translates to:
  /// **'放假中'**
  String get holidayOngoing;

  /// No description provided for @paydayToday.
  ///
  /// In zh, this message translates to:
  /// **'今天发薪'**
  String get paydayToday;

  /// No description provided for @metricUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'暂不可用'**
  String get metricUnavailable;

  /// No description provided for @noVisibleMetrics.
  ///
  /// In zh, this message translates to:
  /// **'所有指标已隐藏'**
  String get noVisibleMetrics;

  /// No description provided for @untilWorkStart.
  ///
  /// In zh, this message translates to:
  /// **'距离上班'**
  String get untilWorkStart;

  /// No description provided for @untilWorkEnd.
  ///
  /// In zh, this message translates to:
  /// **'距离下班'**
  String get untilWorkEnd;

  /// No description provided for @untilLunchEnd.
  ///
  /// In zh, this message translates to:
  /// **'距离午休结束'**
  String get untilLunchEnd;

  /// No description provided for @addCountdown.
  ///
  /// In zh, this message translates to:
  /// **'添加倒计时'**
  String get addCountdown;

  /// No description provided for @addDateOverride.
  ///
  /// In zh, this message translates to:
  /// **'添加日期覆盖'**
  String get addDateOverride;

  /// No description provided for @addHoliday.
  ///
  /// In zh, this message translates to:
  /// **'添加假期'**
  String get addHoliday;

  /// No description provided for @appLanguage.
  ///
  /// In zh, this message translates to:
  /// **'应用语言'**
  String get appLanguage;

  /// No description provided for @backStep.
  ///
  /// In zh, this message translates to:
  /// **'上一步'**
  String get backStep;

  /// No description provided for @birthDate.
  ///
  /// In zh, this message translates to:
  /// **'出生日期（可选）'**
  String get birthDate;

  /// No description provided for @birthTime.
  ///
  /// In zh, this message translates to:
  /// **'出生时刻（可选）'**
  String get birthTime;

  /// No description provided for @businessSettings.
  ///
  /// In zh, this message translates to:
  /// **'完整设置'**
  String get businessSettings;

  /// No description provided for @calendarSection.
  ///
  /// In zh, this message translates to:
  /// **'日期与假期'**
  String get calendarSection;

  /// No description provided for @currencyCode.
  ///
  /// In zh, this message translates to:
  /// **'币种代码'**
  String get currencyCode;

  /// No description provided for @customCountdown.
  ///
  /// In zh, this message translates to:
  /// **'自定义倒计时'**
  String get customCountdown;

  /// No description provided for @customHolidays.
  ///
  /// In zh, this message translates to:
  /// **'自定义假期'**
  String get customHolidays;

  /// No description provided for @dateLabel.
  ///
  /// In zh, this message translates to:
  /// **'日期'**
  String get dateLabel;

  /// No description provided for @dateOverrides.
  ///
  /// In zh, this message translates to:
  /// **'日期覆盖'**
  String get dateOverrides;

  /// No description provided for @dayType.
  ///
  /// In zh, this message translates to:
  /// **'日期类型'**
  String get dayType;

  /// No description provided for @disableAll.
  ///
  /// In zh, this message translates to:
  /// **'全部关闭'**
  String get disableAll;

  /// No description provided for @displaySection.
  ///
  /// In zh, this message translates to:
  /// **'悬浮窗'**
  String get displaySection;

  /// No description provided for @enableAll.
  ///
  /// In zh, this message translates to:
  /// **'全部开启'**
  String get enableAll;

  /// No description provided for @exportPrivacy.
  ///
  /// In zh, this message translates to:
  /// **'导出包含个人信息和薪资，请选择可信的保存位置。'**
  String get exportPrivacy;

  /// No description provided for @finishSetup.
  ///
  /// In zh, this message translates to:
  /// **'完成引导'**
  String get finishSetup;

  /// No description provided for @fixedPayday.
  ///
  /// In zh, this message translates to:
  /// **'每月固定日'**
  String get fixedPayday;

  /// No description provided for @generalSection.
  ///
  /// In zh, this message translates to:
  /// **'通用'**
  String get generalSection;

  /// No description provided for @grossMonthly.
  ///
  /// In zh, this message translates to:
  /// **'税前月薪'**
  String get grossMonthly;

  /// No description provided for @hideSalary.
  ///
  /// In zh, this message translates to:
  /// **'隐藏金额'**
  String get hideSalary;

  /// No description provided for @holidayEnd.
  ///
  /// In zh, this message translates to:
  /// **'结束日期'**
  String get holidayEnd;

  /// No description provided for @holidayKind.
  ///
  /// In zh, this message translates to:
  /// **'假期类型'**
  String get holidayKind;

  /// No description provided for @holidayStart.
  ///
  /// In zh, this message translates to:
  /// **'开始日期'**
  String get holidayStart;

  /// No description provided for @invalidCountdown.
  ///
  /// In zh, this message translates to:
  /// **'检查名称与时间，新倒计时的目标必须在未来。'**
  String get invalidCountdown;

  /// No description provided for @invalidDraft.
  ///
  /// In zh, this message translates to:
  /// **'请检查下方字段，上次有效设置仍然保留。'**
  String get invalidDraft;

  /// No description provided for @invalidHoliday.
  ///
  /// In zh, this message translates to:
  /// **'填写名称和类型，结束日期须等于或晚于开始日期。'**
  String get invalidHoliday;

  /// No description provided for @invalidLifespan.
  ///
  /// In zh, this message translates to:
  /// **'输入 1–150 年，最多一位小数。'**
  String get invalidLifespan;

  /// No description provided for @invalidLunch.
  ///
  /// In zh, this message translates to:
  /// **'午休须在上班与下班时间之间，且开始早于结束。'**
  String get invalidLunch;

  /// No description provided for @invalidPaydays.
  ///
  /// In zh, this message translates to:
  /// **'填入 1–31 之间的日期，两次发薪日不得相同。'**
  String get invalidPaydays;

  /// No description provided for @invalidSalary.
  ///
  /// In zh, this message translates to:
  /// **'输入合法的非负金额。'**
  String get invalidSalary;

  /// No description provided for @invalidValue.
  ///
  /// In zh, this message translates to:
  /// **'请检查输入值。'**
  String get invalidValue;

  /// No description provided for @invalidWorkHours.
  ///
  /// In zh, this message translates to:
  /// **'使用 HH:mm，下班时间须在同一天且晚于上班时间。'**
  String get invalidWorkHours;

  /// No description provided for @itemName.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get itemName;

  /// No description provided for @lastWorkday.
  ///
  /// In zh, this message translates to:
  /// **'每月最后一个工作日'**
  String get lastWorkday;

  /// No description provided for @lifeExpectancy.
  ///
  /// In zh, this message translates to:
  /// **'预期寿命（年）'**
  String get lifeExpectancy;

  /// No description provided for @lunchBreak.
  ///
  /// In zh, this message translates to:
  /// **'午休'**
  String get lunchBreak;

  /// No description provided for @lunchEnd.
  ///
  /// In zh, this message translates to:
  /// **'午休结束'**
  String get lunchEnd;

  /// No description provided for @lunchStart.
  ///
  /// In zh, this message translates to:
  /// **'午休开始'**
  String get lunchStart;

  /// No description provided for @metricHoliday.
  ///
  /// In zh, this message translates to:
  /// **'距离放假'**
  String get metricHoliday;

  /// No description provided for @metricLife.
  ///
  /// In zh, this message translates to:
  /// **'生命倒计时'**
  String get metricLife;

  /// No description provided for @metricMonthSalary.
  ///
  /// In zh, this message translates to:
  /// **'本月已赚'**
  String get metricMonthSalary;

  /// No description provided for @metricPayday.
  ///
  /// In zh, this message translates to:
  /// **'距离发薪'**
  String get metricPayday;

  /// No description provided for @metricTodaySalary.
  ///
  /// In zh, this message translates to:
  /// **'今日已赚'**
  String get metricTodaySalary;

  /// No description provided for @metricWork.
  ///
  /// In zh, this message translates to:
  /// **'上下班倒计时'**
  String get metricWork;

  /// No description provided for @miniMetrics.
  ///
  /// In zh, this message translates to:
  /// **'迷你窗指标'**
  String get miniMetrics;

  /// No description provided for @moveDown.
  ///
  /// In zh, this message translates to:
  /// **'下移'**
  String get moveDown;

  /// No description provided for @moveUp.
  ///
  /// In zh, this message translates to:
  /// **'上移'**
  String get moveUp;

  /// No description provided for @netMonthly.
  ///
  /// In zh, this message translates to:
  /// **'税后月薪（可选）'**
  String get netMonthly;

  /// No description provided for @netRequired.
  ///
  /// In zh, this message translates to:
  /// **'切换到税后口径前请填写税后月薪。'**
  String get netRequired;

  /// No description provided for @nextStep.
  ///
  /// In zh, this message translates to:
  /// **'下一步'**
  String get nextStep;

  /// No description provided for @nextWorkday.
  ///
  /// In zh, this message translates to:
  /// **'顺延至下一工作日'**
  String get nextWorkday;

  /// No description provided for @noAdjustment.
  ///
  /// In zh, this message translates to:
  /// **'保持原日期'**
  String get noAdjustment;

  /// No description provided for @onboardingTitle.
  ///
  /// In zh, this message translates to:
  /// **'设置时余'**
  String get onboardingTitle;

  /// No description provided for @paydayAdjustment.
  ///
  /// In zh, this message translates to:
  /// **'发薪日遇休息日'**
  String get paydayAdjustment;

  /// No description provided for @paydayDate.
  ///
  /// In zh, this message translates to:
  /// **'发薪日期'**
  String get paydayDate;

  /// No description provided for @paydayRule.
  ///
  /// In zh, this message translates to:
  /// **'发薪规则'**
  String get paydayRule;

  /// No description provided for @peekSalary.
  ///
  /// In zh, this message translates to:
  /// **'临时查看金额'**
  String get peekSalary;

  /// No description provided for @personalSection.
  ///
  /// In zh, this message translates to:
  /// **'个人信息'**
  String get personalSection;

  /// No description provided for @previewLive.
  ///
  /// In zh, this message translates to:
  /// **'真实数据预览'**
  String get previewLive;

  /// No description provided for @previousWorkday.
  ///
  /// In zh, this message translates to:
  /// **'提前至上一工作日'**
  String get previousWorkday;

  /// No description provided for @regionCN.
  ///
  /// In zh, this message translates to:
  /// **'中国大陆'**
  String get regionCN;

  /// No description provided for @regionHK.
  ///
  /// In zh, this message translates to:
  /// **'中国香港'**
  String get regionHK;

  /// No description provided for @regionJP.
  ///
  /// In zh, this message translates to:
  /// **'日本'**
  String get regionJP;

  /// No description provided for @regionKR.
  ///
  /// In zh, this message translates to:
  /// **'韩国'**
  String get regionKR;

  /// No description provided for @regionLabel.
  ///
  /// In zh, this message translates to:
  /// **'节假日地区'**
  String get regionLabel;

  /// No description provided for @regionTW.
  ///
  /// In zh, this message translates to:
  /// **'中国台湾'**
  String get regionTW;

  /// No description provided for @regionUS.
  ///
  /// In zh, this message translates to:
  /// **'美国'**
  String get regionUS;

  /// No description provided for @removeItem.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get removeItem;

  /// No description provided for @restDayLabel.
  ///
  /// In zh, this message translates to:
  /// **'休息日'**
  String get restDayLabel;

  /// No description provided for @salaryBasis.
  ///
  /// In zh, this message translates to:
  /// **'薪资口径'**
  String get salaryBasis;

  /// No description provided for @salaryPrecision.
  ///
  /// In zh, this message translates to:
  /// **'金额小数位'**
  String get salaryPrecision;

  /// No description provided for @settingsExport.
  ///
  /// In zh, this message translates to:
  /// **'导出设置'**
  String get settingsExport;

  /// No description provided for @settingsExported.
  ///
  /// In zh, this message translates to:
  /// **'已导出设置。'**
  String get settingsExported;

  /// No description provided for @settingsFileInvalid.
  ///
  /// In zh, this message translates to:
  /// **'无法使用此文件，请检查大小、JSON 格式和版本。'**
  String get settingsFileInvalid;

  /// No description provided for @settingsImport.
  ///
  /// In zh, this message translates to:
  /// **'导入设置'**
  String get settingsImport;

  /// No description provided for @systemLanguage.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get systemLanguage;

  /// No description provided for @targetTime.
  ///
  /// In zh, this message translates to:
  /// **'目标时刻'**
  String get targetTime;

  /// No description provided for @twiceMonthly.
  ///
  /// In zh, this message translates to:
  /// **'每月两次'**
  String get twiceMonthly;

  /// No description provided for @weeklyRestHoliday.
  ///
  /// In zh, this message translates to:
  /// **'将每周休息日计入放假'**
  String get weeklyRestHoliday;

  /// No description provided for @workdayLabel.
  ///
  /// In zh, this message translates to:
  /// **'工作日'**
  String get workdayLabel;

  /// No description provided for @workEnd.
  ///
  /// In zh, this message translates to:
  /// **'下班时间'**
  String get workEnd;

  /// No description provided for @workSection.
  ///
  /// In zh, this message translates to:
  /// **'作息与薪资'**
  String get workSection;

  /// No description provided for @workStart.
  ///
  /// In zh, this message translates to:
  /// **'上班时间'**
  String get workStart;

  /// No description provided for @workWeek.
  ///
  /// In zh, this message translates to:
  /// **'每周工作日'**
  String get workWeek;

  /// No description provided for @holidayData.
  ///
  /// In zh, this message translates to:
  /// **'节假日数据'**
  String get holidayData;

  /// No description provided for @holidayFallback.
  ///
  /// In zh, this message translates to:
  /// **'缺少当前年份数据，按设置中的工作周计算。'**
  String get holidayFallback;

  /// No description provided for @holidayChecking.
  ///
  /// In zh, this message translates to:
  /// **'正在检查节假日数据…'**
  String get holidayChecking;

  /// No description provided for @holidayCheck.
  ///
  /// In zh, this message translates to:
  /// **'检查更新'**
  String get holidayCheck;

  /// No description provided for @holidayImport.
  ///
  /// In zh, this message translates to:
  /// **'导入 JSON'**
  String get holidayImport;

  /// No description provided for @holidayUpdated.
  ///
  /// In zh, this message translates to:
  /// **'节假日数据已更新。'**
  String get holidayUpdated;

  /// No description provided for @holidayLatest.
  ///
  /// In zh, this message translates to:
  /// **'已使用最新数据。'**
  String get holidayLatest;

  /// No description provided for @holidayRejected.
  ///
  /// In zh, this message translates to:
  /// **'节假日文件校验失败，请检查版本、地区、年份和校验值。'**
  String get holidayRejected;

  /// No description provided for @holidayFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法读取节假日更新，继续使用有效本地数据。'**
  String get holidayFailed;

  /// No description provided for @restoreSettingsBackup.
  ///
  /// In zh, this message translates to:
  /// **'恢复设置备份'**
  String get restoreSettingsBackup;

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

  /// No description provided for @durationDays.
  ///
  /// In zh, this message translates to:
  /// **'天'**
  String get durationDays;

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
  /// **'添加倒计时小组件'**
  String get addWidget;

  /// No description provided for @addSalaryWidget.
  ///
  /// In zh, this message translates to:
  /// **'添加薪资小组件'**
  String get addSalaryWidget;

  /// No description provided for @widgetInstructions.
  ///
  /// In zh, this message translates to:
  /// **'长按手机桌面，添加时余的倒计时或薪资小组件。编辑倒计时组件可选择主指标，刷新时间由系统调度。'**
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
  /// **'小组件外观'**
  String get mobileAppearance;

  /// No description provided for @mobileWidget.
  ///
  /// In zh, this message translates to:
  /// **'主屏幕小组件'**
  String get mobileWidget;

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
