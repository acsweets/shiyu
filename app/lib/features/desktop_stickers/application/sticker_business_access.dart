import '../../retirement/application/settings_access.dart';
import '../../retirement/data/holiday_repository.dart';
import '../../retirement/data/settings_repository.dart';
import 'sticker_settings_state.dart';

SettingsAccess stickerBusinessAccess(StickerSettingsSession session) =>
    SettingsAccess(
      read: () async =>
          (await session.send(StickerSetting.businessRead)).state.business!,
      commit: (SettingsValues value) =>
          _send(session, StickerSetting.businessSave, 'value', value),
      importSettings: (String raw) =>
          _send(session, StickerSetting.businessImport, 'raw', raw),
      changeCountdown: (SettingsValues value) =>
          _send(session, StickerSetting.businessCountdown, 'value', value),
      peekSalary: () async =>
          (await session.send(StickerSetting.businessPeek)).privateSalary,
      checkHolidays: () async => HolidayUpdate.values.byName(
        (await session.send(StickerSetting.holidayCheck)).message!,
      ),
      importHoliday: (String raw) async => HolidayUpdate.values.byName(
        (await session.send(StickerSetting.holidayImport, <String, Object?>{
          'raw': raw,
        })).message!,
      ),
    );

Future<SettingsView> _send(
  StickerSettingsSession session,
  StickerSetting action,
  String key,
  Object value,
) async {
  final StickerSettingsReply reply = await session.send(
    action,
    <String, Object?>{key: value},
  );
  return reply.state.business!;
}
