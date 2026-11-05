import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../l10n/generated/app_localizations.dart';
import '../../desktop_stickers/data/sticker_cat_pose.dart';
import '../../desktop_stickers/data/sticker_palette.dart';
import '../data/mobile_appearance.dart';
import '../domain/retirement_snapshot.dart';

class RetirementCard extends StatelessWidget {
  const RetirementCard({
    required this.snapshot,
    required this.appearance,
    super.key,
  });

  /// 已从 Rust 返回的时间快照。
  final RetirementSnapshot? snapshot;

  /// 当前的移动端配色和标题选项。
  final MobileAppearance appearance;

  /// 猫猫图片和卡片使用同一个布局区域，拖动时一起移动。
  static const double _catSize = 132;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final StickerPalette palette = appearance.palette;
    final StickerCatPose cat = StickerCatPose.sitting;
    final double overlap = _catSize * cat.bottomInset + 2;
    final String value = _countdown(strings);
    return Stack(
      alignment: Alignment.topCenter,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: _catSize - overlap),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: palette.backgroundFor(0),
              borderRadius: BorderRadius.circular(26),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 22,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 26,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (appearance.titleVisible) ...<Widget>[
                      Text(
                        strings.retirementTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: palette.foreground,
                          fontSize: appearance.titleSize,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value,
                        key: const ValueKey<String>('retirementValue'),
                        maxLines: 1,
                        textDirection: TextDirection.ltr,
                        style: Theme.of(context).textTheme.headlineMedium!
                            .copyWith(
                              color: palette.foreground,
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          child: Image.asset(
            cat.asset,
            width: _catSize,
            height: _catSize,
            cacheWidth: 396,
            excludeFromSemantics: true,
          ),
        ),
      ],
    );
  }

  /// 把绝对剩余秒数按完整天与时钟格式显示在同一行。
  String _countdown(AppLocalizations strings) {
    final RetirementSnapshot? current = snapshot;
    if (current == null || current.status == 'unconfigured') return '—';
    if (current.status == 'retired') return strings.retired;
    final Duration time = Duration(seconds: current.seconds);
    final String days = NumberFormat.decimalPattern(strings.localeName)
        .format(time.inDays);
    final String clock =
        '${_two(time.inHours % 24)}:'
        '${_two(time.inMinutes % 60)}:${_two(time.inSeconds % 60)}';
    return strings.mobileCountdown(days, clock);
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}
