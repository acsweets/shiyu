# 01 iOS 构建与验收

本阶段结束时，应有一条可复现的模拟器验收记录和一条 iPhone 真机验收记录。Mac 侧命令和工具链以[iOS 运行与小组件验收指南](../../native/ios/README.md)为准。

## 1. 锁定候选

- [ ] 在 Windows 查阅 git 状态，把本轮需要验证的代码整理到验收分支。记录 commit、应用版本和本轮改动。
- [ ] 在 Mac 拉取该版本，用 git rev-parse --short HEAD 核对与 Windows 一致。
- [ ] 用 flutter doctor -v 查看 Xcode、iOS 工具链和依赖。按运行指南配置 Flutter、Rust 和 CocoaPods。
- [ ] 准备虚构的生日、退休日、时区和月薪样例，截图与报错记录使用同一组数据。

## 2. 模拟器先跑通

打开 Xcode 的 iOS 模拟器，在仓库的 app 目录执行。把 SIMULATOR_ID 替换成 flutter devices 列出的模拟器标识。

```sh
cd app
flutter pub get --enforce-lockfile
flutter devices
flutter run -d SIMULATOR_ID
```

- [ ] 应用进入首页，设置能保存。退出并重新打开，确认刚才的配置仍在。
- [ ] 回到 iOS 主屏幕，在组件图库找到「时余」，添加倒计时和薪资组件。回到应用修改退休日期并保存，检查主屏幕组件能读到新数据。
- [ ] 切换简体中文和英文，检查关键标题、时间单位与组件画面。拍一张首页和一张主屏幕截图。
- [ ] 如果组件没出现，先确认构建产物包含 ShiyuWidgets.appex。能添加但读不到数据，再检查 App Group 与保存流程。

## 3. iPhone 真机复核

- [ ] 从 app 目录准备 Xcode 配置并打开工作区。

```sh
flutter build ios --config-only --no-codesign
open ios/Runner.xcworkspace
```

- [ ] 给 Runner 和 ShiyuWidgets 选择同一个 Apple 开发团队。主应用 Bundle ID 为 com.growthrecord.shiyu，组件为 com.growthrecord.shiyu.widgets，共享组为 group.com.growthrecord.shiyu。两个目标均核对 Signing & Capabilities 的 App Groups。
- [ ] 在 iPhone 选择 Runner 运行。首次安装并保存样例，然后重启应用和重新添加组件，确认共享配置。
- [ ] 测「静待百岁，好好生活」与「已存在世界」切换、标题显隐、今日与本月已赚、金额遮蔽。检查主屏幕和应用里的金额都正确遮蔽。
- [ ] 在 iOS 17 或以上实测中尺寸单项、组合计时和薪资卡内刷新。iOS 15/16 可用设备另验固定布局及应用内刷新。以各系统实测行为为准，记录系统调度造成的刷新延迟。
- [ ] 断网冷启动并读已有配置，恢复网络后确认应用和组件继续可用。

## 4. 记录与退出

- [ ] 记录设备型号、系统、Xcode、模拟器或真机、版本、commit、步骤和结果。将截图或日志引用回填到[节点 13 验收记录](../验收记录/13/README.md)。
- [ ] 构建、签名、应用启动或组件读取失败时，记录第一条可定位错误和复现步骤。修复后用新 commit 重跑失败项。
- [ ] 模拟器和真机主流程通过，才能把该候选交给 TestFlight。最低系统没有覆盖时，记录待测范围和实测版本。
