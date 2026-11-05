import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiyu/platform/desktop/desktop_placement.dart';

void main() {
  test('混合 DPI 按目标屏幕转换位置与尺寸，吸边使用 12 逻辑像素', _verifyDpi);
  test('显示器断开后回到主屏右上角', _verifyFallback);
}

const WorkArea _primary = (
  id: 'main',
  bounds: Rect.fromLTWH(0, 0, 2560, 1540),
  scale: 1.25,
);
const WorkArea _external = (
  id: 'external',
  bounds: Rect.fromLTWH(-1920, 0, 1920, 1040),
  scale: 1.5,
);

void _verifyDpi() {
  const DesktopPlacement workspace = DesktopPlacement(_primary, <WorkArea>[
    _primary,
    _external,
  ]);
  const Rect bounds = Rect.fromLTWH(-1903, 110, 420, 258);
  final PlacedWindow moved = workspace.capture(bounds, snap: true);
  expect(moved.anchor.display, 'external');
  expect(moved.bounds.left, -1920);
  expect(workspace.capture(bounds, snap: false).bounds, bounds);
  final PlacedWindow legacy = workspace.restore(
    const Rect.fromLTWH(80, 20, 280, 172),
    null,
  );
  expect(legacy.bounds, const Rect.fromLTWH(100, 25, 350, 215));

  const WorkArea changed = (
    id: 'external',
    bounds: Rect.fromLTWH(-2560, 0, 2560, 1400),
    scale: 2,
  );
  const DesktopPlacement resized = DesktopPlacement(_primary, <WorkArea>[
    _primary,
    changed,
  ]);
  final PlacedWindow restored = resized.restore(moved.bounds, moved.anchor);
  expect(restored.bounds.left, -2560);
  expect(restored.bounds.width, 560);
  expect(restored.bounds.top, closeTo(146.667, 0.01));
}

void _verifyFallback() {
  const DesktopPlacement workspace = DesktopPlacement(_primary, <WorkArea>[
    _primary,
  ]);
  final PlacedWindow moved = workspace.restore(
    const Rect.fromLTWH(-1903, 110, 420, 258),
    (display: 'external', origin: _external.bounds.topLeft, scale: 1.5),
  );
  expect(moved.anchor.display, 'main');
  expect(moved.bounds.width, 350);
  expect(moved.bounds.right, 2540);
  expect(moved.bounds.top, 20);
}
