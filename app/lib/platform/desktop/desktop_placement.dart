import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:screen_retriever/screen_retriever.dart';

typedef ScreenAnchor = ({String display, Offset origin, double scale});
typedef PlacedWindow = ({Rect bounds, ScreenAnchor anchor});
typedef WorkArea = ({String id, Rect bounds, double scale});

/// 所有边距按窗口插件的逻辑像素计算，保存显示器 ID 与当时的工作区原点。
class DesktopPlacement {
  const DesktopPlacement(this.primary, this.areas);

  final WorkArea primary;
  final List<WorkArea> areas;
  static const double snapDistance = 12;

  static Future<DesktopPlacement> read() async {
    final List<Display> all = await screenRetriever.getAllDisplays();
    final Display primary = await screenRetriever.getPrimaryDisplay();
    return DesktopPlacement(_workArea(primary), all.map(_workArea).toList());
  }

  static WorkArea _workArea(Display display) {
    final double scale = Platform.isWindows
        ? (display.scaleFactor ?? 1).toDouble()
        : 1;
    return (
      id: display.id.isEmpty ? display.name ?? '' : display.id,
      bounds:
          ((display.visiblePosition ?? Offset.zero) * scale) &
          ((display.visibleSize ?? display.size) * scale),
      scale: scale,
    );
  }

  PlacedWindow restore(Rect bounds, ScreenAnchor? previous) {
    if (previous != null) {
      for (final WorkArea area in areas) {
        if (area.id == previous.display) {
          final double ratio = area.scale / previous.scale;
          final Offset origin =
              area.bounds.topLeft + (bounds.topLeft - previous.origin) * ratio;
          return _within(origin & (bounds.size * ratio), area);
        }
      }
      return _fallback(bounds.size * (primary.scale / previous.scale));
    }
    final WorkArea? overlapping = _bestArea(bounds, legacy: true);
    return overlapping == null
        ? _fallback(bounds.size * primary.scale)
        : _within(
            (bounds.topLeft * overlapping.scale) &
                (bounds.size * overlapping.scale),
            overlapping,
          );
  }

  PlacedWindow capture(Rect bounds, {required bool snap}) {
    final WorkArea? area = _bestArea(bounds);
    return area == null
        ? _fallback(bounds.size)
        : _within(bounds, area, snap: snap);
  }

  WorkArea? _bestArea(Rect bounds, {bool legacy = false}) {
    WorkArea? winner;
    double score = 0;
    for (final WorkArea area in areas) {
      final Rect areaBounds = legacy
          ? (area.bounds.topLeft / area.scale) & (area.bounds.size / area.scale)
          : area.bounds;
      final Rect intersection = bounds.intersect(areaBounds);
      if (intersection.isEmpty) continue;
      final double candidate = intersection.width * intersection.height;
      if (candidate > score) {
        score = candidate;
        winner = area;
      }
    }
    return winner;
  }

  PlacedWindow _fallback(Size size) {
    final Rect area = primary.bounds;
    return _within(
      Rect.fromLTWH(
        area.right - size.width - 16 * primary.scale,
        area.top + 16 * primary.scale,
        size.width,
        size.height,
      ),
      primary,
    );
  }

  PlacedWindow _within(Rect rect, WorkArea area, {bool snap = false}) {
    final Rect screen = area.bounds;
    final double width = math.min(rect.width, screen.width);
    final double height = math.min(rect.height, screen.height);
    final double gap = snap ? snapDistance * area.scale : 0;
    final double x = _axis(rect.left, screen.left, screen.right - width, gap);
    final double y = _axis(rect.top, screen.top, screen.bottom - height, gap);
    return (
      bounds: Rect.fromLTWH(x, y, width, height),
      anchor: (display: area.id, origin: screen.topLeft, scale: area.scale),
    );
  }

  double _axis(double value, double minimum, double maximum, double gap) {
    final double inside = value.clamp(minimum, maximum);
    if (inside - minimum <= gap) return minimum;
    if (maximum - inside <= gap) return maximum;
    return inside;
  }
}
