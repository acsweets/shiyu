# 时余应用图标

图标取自浮窗坐姿橘猫。以原贴纸为参考，用内置 imagegen 生成独立猫头，保留橘色条纹、弯眼和腮红。透明前景原稿为 `app_icon_foreground.png`，生成原件保留在 `.codex/generated_images/01a1a5a1-bb27-7170-b70f-93bb20578b88/exec-2ca3645b-d23f-409d-9acf-b244a8fc4935.png`。

从仓库根目录运行 `python scripts/generate_app_icons.py` 可重新导出图标。脚本依赖 Pillow。前景和浅黄色底板分开处理，平台资源使用同一套图案和颜色。

| 平台 | 资源和适配 |
| --- | --- |
| iOS 和 iPadOS | `app/ios/Runner/Assets.xcassets/AppIcon.appiconset`，沿用现有编目槽位。全幅 RGB 图标由系统处理圆角。 |
| Android | `app/android/app/src/main/res/mipmap-*`，包括兼容图标、带安全留白的自适应前景及主题色图标。 |
| macOS | `app/macos/Runner/Assets.xcassets/AppIcon.appiconset`，按原有尺寸导出。菜单栏使用透明猫头 `tray.png`。 |
| Windows | `app/windows/runner/resources/app_icon.ico`，包含 16–256 像素多尺寸图像。原生设置窗复用可执行文件图标，系统托盘使用 Flutter 资源 `tray.ico`。 |

平台规格见 [Apple AppIcon 编目](https://developer.apple.com/documentation/xcode/configuring-your-app-icon)、[Android 自适应图标](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive) 和 [Windows Win32 图标](https://learn.microsoft.com/en-us/windows/win32/menurc/about-icons)。

## 验证

- Windows Release 已构建，核对可执行文件内嵌图标与设置窗标题栏。
- Android x86_64 APK 已构建并安装到 API 36 模拟器，主屏幕上的圆形图标显示完整猫头。五档自适应前景均通过圆形裁切范围检查。
- iOS 和 macOS 的全部编目条目已核对引用、像素尺寸和色彩模式，待在 Mac 构建并查看系统显示。

## 生成提示词

Use case: logo-brand. Asset type: one transparent mascot app icon foreground for Shiyu, a desktop and mobile countdown app. The attached image is the exact character identity reference. Create just the HEAD of the same front-facing hand-drawn chibi orange tabby: round cream cheeks, three apricot forehead stripes, warm cocoa pencil outline, closed smiling eyes, tiny smiling mouth, peach blush, pink ear centers, and two short whiskers per cheek. Preserve the current cat's recognizable proportions and sweet expression. Translate it into a clean high-contrast app-icon glyph, using broad flat shapes and a slightly hand-drawn contour that will remain recognizable at 16 pixels. A narrow cream sticker rim is fine. Whole head, full ears and whiskers, symmetric and optically centered, isolated with even transparent margins on a square canvas. Transparent PNG with true alpha. No background tile, no shadow, no body, no text, no letters, no clock or embellishments, no app mockup.
