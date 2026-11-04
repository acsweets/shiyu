// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '时余';

  @override
  String get tagline => '感知时间，留住生活。';

  @override
  String get initializationNotice => '工程已就绪，时间与薪资功能正在构建中。';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appName => '時餘';

  @override
  String get tagline => '感知時間，留住生活。';

  @override
  String get initializationNotice => '工程已就緒，時間與薪資功能正在建置中。';
}
