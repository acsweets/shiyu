// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get restoreSettingsBackup => '恢复设置备份';

  @override
  String get appName => '时余';

  @override
  String get tagline => '感知时间，留住生活。';

  @override
  String get initializationNotice => '工程已就绪，时间与薪资功能正在构建中。';

  @override
  String get retirementTitle => '退休倒计时';

  @override
  String get retired => '已退休';

  @override
  String get daysRemaining => '天后退休';

  @override
  String get chooseRetirement => '选择退休日期';

  @override
  String get configure => '配置';

  @override
  String get hideWindow => '隐藏浮窗';

  @override
  String get timeZoneLabel => 'IANA 时区';

  @override
  String get saveSettings => '保存时区';

  @override
  String get clearTarget => '清除日期';

  @override
  String get addWidget => '添加桌面小组件';

  @override
  String get widgetInstructions => '长按手机桌面，添加“时余 · 退休倒计时”小组件。';

  @override
  String get settingsError => '设置或共享数据操作失败，请检查日期、时区和存储权限后重试。';

  @override
  String get calendarFallback => '节假日数据尚未接入，当前按每周工作日设置计算。';

  @override
  String get currentSlice => '当前已接入退休倒计时，其他内置指标将在后续节点提供。';

  @override
  String get mobileSettings => '设置';

  @override
  String get mobileAppearance => '小组件外观';

  @override
  String get mobileWidget => '主屏幕小组件';

  @override
  String get mobileShowTitle => '显示标题';

  @override
  String get mobileTitleSize => '提示文字大小';

  @override
  String get mobileMacaron => '马卡龙色系';

  @override
  String get mobileCool => '冷酷色系';

  @override
  String get mobileSunset => '日落暖调';

  @override
  String get mobileSave => '保存设置';

  @override
  String get mobileSaved => '设置已保存';

  @override
  String get mobileAppearanceError => '外观未能保存，请重试。';

  @override
  String get mobileNotSet => '未设置';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get restoreSettingsBackup => '還原設定備份';

  @override
  String get appName => '時餘';

  @override
  String get tagline => '感知時間，留住生活。';

  @override
  String get initializationNotice => '工程已就緒，時間與薪資功能正在建置中。';

  @override
  String get retirementTitle => '退休倒數';

  @override
  String get retired => '已退休';

  @override
  String get daysRemaining => '天後退休';

  @override
  String get chooseRetirement => '選擇退休日期';

  @override
  String get configure => '設定';

  @override
  String get hideWindow => '隱藏浮窗';

  @override
  String get timeZoneLabel => 'IANA 時區';

  @override
  String get saveSettings => '儲存時區';

  @override
  String get clearTarget => '清除日期';

  @override
  String get addWidget => '加入桌面小工具';

  @override
  String get widgetInstructions => '長按手機主畫面，加入「時餘 · 退休倒數」小工具。';

  @override
  String get settingsError => '操作失敗，請檢查日期、時區及共用儲存空間後重試。';

  @override
  String get calendarFallback => '尚未接入假日資料，目前依每週工作日設定計算。';

  @override
  String get currentSlice => '目前支援退休倒數，其他內建指標將於後續節點提供。';

  @override
  String get mobileSettings => '設定';

  @override
  String get mobileAppearance => '小工具外觀';

  @override
  String get mobileWidget => '主畫面小工具';

  @override
  String get mobileShowTitle => '顯示標題';

  @override
  String get mobileTitleSize => '提示文字大小';

  @override
  String get mobileMacaron => '馬卡龍色系';

  @override
  String get mobileCool => '冷色系';

  @override
  String get mobileSunset => '日落暖調';

  @override
  String get mobileSave => '儲存設定';

  @override
  String get mobileSaved => '設定已儲存';

  @override
  String get mobileAppearanceError => '無法儲存外觀，請再試一次。';

  @override
  String get mobileNotSet => '尚未設定';
}
