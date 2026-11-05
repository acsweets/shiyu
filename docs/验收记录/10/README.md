# 节点 10 桌面皮肤与资源包

日期 2026-11-05。前置版本为 `8273a54`，实现版本以本报告所在提交为准。[节点计划](../../开发计划/10-皮肤与桌面功能冻结.md)

## 用户检查

1. 在「外观」切换简约卡片和深色科技，修改浅色、深色、跟随系统、30%–100% 的背景不透明度、数字字号和强调色，观察主窗和子窗。关闭应用再打开，检查上次选择。
2. 在「猫猫素材」导出 `.timerpack`，改动外观后重新导入。可导出带槽位 PNG 的包，也可只导出配色。手工替换文件的优先级、PNG 和 ZIP 的规格见[资源制作指南](../../界面设计/04-用户资源制作指南.md)。
3. 将有效包与损坏包分别从系统文件管理器打开，观察安装或拒绝提示。Windows 开发构建先用注册脚本，macOS 使用应用声明的文件类型。
4. 重新检查迷你、标准和展开，确认切换皮肤不改变 Rust 指标、金额遮蔽、窗口分组和标题偏好。

## 验证命令

```powershell
./scripts/check.ps1 -BuildWindows
cd app
flutter test test/timer_pack_test.dart --no-pub
flutter test integration_test/retirement_test.dart -d windows --no-pub
```

Windows Release 产物由 `flutter build windows` 生成，位于 `app/build/windows/x64/runner/Release/`。macOS 构建和 Finder 打开、Windows Explorer 文件关联界面、八语言外观逐屏及长时间内存采样留待手工复核。

Windows 11 x64 上 Release 构建、22 项 Flutter 测试、16 项 Rust 测试和原生 Debug 集成均通过。自动化覆盖标准 DEFLATE、超出声明的解压、坏包回滚、路径穿越、未知版本、真实 PNG 往返，以及原生第二进程传入中文文件名。100 次皮肤切换后槽位和图片修订号保持一致。该循环记录状态一致性，长时间内存趋势在节点 13 单独测量。
