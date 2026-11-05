import '../data/holiday_repository.dart';
import 'retirement_controller.dart';

/// 只包含可公开的日历元数据，可通过桌面设置窗口通道传递。
class HolidayStatus {
  const HolidayStatus(this.data);

  factory HolidayStatus.fromController(RetirementController controller) {
    final HolidaySelection? selected = controller.holidayData;
    return HolidayStatus(<Object?, Object?>{
      'region': controller.holidayRegion,
      'available': controller.snapshot?.calendarStatus == 'available',
      'update': controller.holidayUpdate.name,
      'version': selected?.pack.version,
      'years': selected?.pack.years ?? const <int>[],
    });
  }

  final Map<Object?, Object?> data;

  String get region => data['region'] as String;
  bool get available => data['available'] == true;
  HolidayUpdate get update =>
      HolidayUpdate.values.byName(data['update'] as String);
  int? get version => data['version'] as int?;
  List<int> get years => (data['years'] as List<Object?>).cast<int>();
}
