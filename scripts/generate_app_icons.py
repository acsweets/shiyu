"""将同一张猫猫前景导出到四个平台的原生应用图标目录。"""

import json
from pathlib import Path

from PIL import Image, ImageDraw


APP = Path(__file__).resolve().parents[1] / "app"
BRAND = APP / "assets" / "brand"
ANDROID_RES = APP / "android" / "app" / "src" / "main" / "res"
BACKGROUND = "#FFE3AC"
CANVAS_SIZE = 1024
ICO_SIZES = (16, 20, 24, 32, 40, 48, 64, 128, 256)
DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}


def load_mark() -> Image.Image:
    """从带透明留白的原稿取得完整猫头轮廓。"""
    with Image.open(BRAND / "app_icon_foreground.png") as source:
        mark = source.convert("RGBA")
    alpha = mark.getchannel("A")
    bounds = alpha.point(lambda value: 255 if value >= 16 else 0).getbbox()
    if not bounds or alpha.getextrema()[0] != 0:
        raise ValueError("图标原稿需要包含可见图案和真实透明背景")
    left, top, right, bottom = bounds
    return mark.crop((max(left - 2, 0), max(top - 2, 0),
                      min(right + 2, mark.width), min(bottom + 2, mark.height)))


def resize_square(image: Image.Image, size: int) -> Image.Image:
    """按平台像素尺寸重采样方形图标。"""
    return image.resize((size, size), Image.Resampling.LANCZOS)


def place_mark(canvas: Image.Image, mark: Image.Image, max_edge: int) -> None:
    """保持猫头比例并居中，给不同平台的裁切形状留出空间。"""
    ratio = max_edge / max(mark.size)
    placed = mark.resize(
        (round(mark.width * ratio), round(mark.height * ratio)),
        Image.Resampling.LANCZOS,
    )
    origin = ((canvas.width - placed.width) // 2, (canvas.height - placed.height) // 2)
    canvas.alpha_composite(placed, origin)


def desktop_tile(mark: Image.Image, inset: int, mark_edge: int) -> Image.Image:
    """为桌面图标留透明外边，避免在任务栏上出现直角色块。"""
    icon = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE))
    ImageDraw.Draw(icon).rounded_rectangle(
        (inset, inset, CANVAS_SIZE - inset - 1, CANVAS_SIZE - inset - 1),
        radius=round((CANVAS_SIZE - 2 * inset) * 0.22),
        fill=BACKGROUND,
    )
    place_mark(icon, mark, mark_edge)
    return icon


def write_apple_catalog(platform: str, icon: Image.Image) -> None:
    """根据现有 AppIcon 编目导出每个尺寸，保留 Xcode 引用。"""
    catalog = APP / platform / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    entries = json.loads((catalog / "Contents.json").read_text(encoding="utf-8"))
    for item in entries["images"]:
        size = float(item["size"].split("x")[0])
        scale = int(item["scale"].removesuffix("x"))
        resize_square(icon, round(size * scale)).save(catalog / item["filename"])


def write_android_icons(mark: Image.Image) -> None:
    """导出旧版图标及 Android 8 起使用的自适应前景。"""
    legacy = desktop_tile(mark, inset=24, mark_edge=730)
    for density, scale in DENSITIES.items():
        legacy_path = ANDROID_RES / f"mipmap-{density}" / "ic_launcher.png"
        resize_square(legacy, round(48 * scale)).save(legacy_path)
        size = round(108 * scale)
        foreground = Image.new("RGBA", (size, size))
        place_mark(foreground, mark, round(60 * scale))
        foreground.save(legacy_path.with_name("ic_launcher_foreground.png"))
    values = ANDROID_RES / "values" / "app_icon_colors.xml"
    values.write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        f'<resources>\n    <color name="app_icon_background">{BACKGROUND}</color>\n'
        '</resources>\n',
        encoding="utf-8",
    )


def main() -> None:
    mark = load_mark()
    mobile = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), BACKGROUND)
    place_mark(mobile, mark, 724)
    write_apple_catalog("ios", mobile.convert("RGB"))
    write_apple_catalog("macos", desktop_tile(mark, inset=83, mark_edge=660))
    write_android_icons(mark)

    windows = desktop_tile(mark, inset=25, mark_edge=780)
    windows.save(
        APP / "windows" / "runner" / "resources" / "app_icon.ico",
        sizes=[(size, size) for size in ICO_SIZES],
    )
    (BRAND / "tray.ico").write_bytes(
        (APP / "windows" / "runner" / "resources" / "app_icon.ico").read_bytes(),
    )
    tray = Image.new("RGBA", (64, 64))
    place_mark(tray, mark, 60)
    tray.save(BRAND / "tray.png")


if __name__ == "__main__":
    main()
