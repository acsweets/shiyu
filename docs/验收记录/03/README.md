# 节点 03 时间指标验收

日期 2026-11-05。设计前置基线为 `ec09f09`，本次实现版本以本报告所属 Git 提交为准。节点计划和用户检查点见[时间计算](../../开发计划/03-六类指标中的时间计算.md)。

## 本次结果

| 环境 | 执行 | 结果 |
| --- | --- | --- |
| Windows 11 x64 | `scripts/check.ps1 -BuildWindows` | 格式、静态分析、Flutter 7 项测试、Rust clippy 和 11 项测试通过。隔离工作目录成功构建 Windows Release |
| Windows 11 x64 | 真实 Flutter FRB 集成测试 | Windows Debug 构建并运行，固定时钟返回新指标，原有退休保存与窗口调用通过 |
| Android 16 x86_64 模拟器 | 同一 Flutter 集成测试 | 固定时钟返回新指标。用相同配置与时刻比对 FRB 和原生 UniFFI，完整快照一致 |
| Android 16 x86_64 模拟器 | 普通调试 APK | 构建、包内 Rust ELF 校验、升级安装和启动通过。测试版已替换为普通应用 |
| macOS / iOS | 同输入对照与实际宿主运行 | 待 Mac 实测，沿用节点 02 的 Apple 验收边界 |

## 固定时间复核

[黄金样例](../../../core/testdata/time_metric_cases.json)包含 19 组设置、42 个固定时钟检查。另在四套设置下抽样 1728 个时刻，验证重复计算一致、秒数非负、未来边界有效。

| 你可以手算的场景 | 预期 |
| --- | --- |
| 上海 2026-11-02 09:00，默认 09:00–18:00、12:00–13:00 午休 | 切换工作中，距离下班 9 小时。下一状态变化为 12:00 |
| 同一天 12:00 / 13:00 / 18:00 | 依次切换午休、工作中、已下班。下班后的目标是下个工作日 09:00 |
| UTC 2000-02-29 00:00，寿命 25.5 年 | 整年落到 2025-02-28，再加 182.5 天，目标为 2025-08-29 12:00 |
| 2026 年 2 月按 31 日发薪，周一至周五工作 | 不调整为 2 月 28 日，提前为 2 月 27 日，顺延为 3 月 2 日。实际日期当天保持「今天发薪」 |
| 合成 2026-11-09、10 两个休息日接周末 | 11 月 7 至 10 日合为一段。11 月 6 日 18:00 进入放假状态，11 月 11 日当地 00:00 结束 |

在仓库根目录运行固定样例。

```powershell
cargo test --manifest-path core/Cargo.toml -p shiyu_core --locked --test time_metrics_tests
./scripts/check.ps1 -BuildWindows
cd app
flutter test integration_test/retirement_test.dart -d windows
flutter test integration_test/retirement_test.dart -d <Android设备ID>
```

在 Mac 上从 `app/` 运行 `flutter test integration_test/retirement_test.dart -d macos`，复核同一 FRB 固定断言。iOS WidgetKit 的安装、签名和运行步骤见 [Apple 指南](../../../native/ios/README.md)。本节点通过接口和固定样例验收，新增指标的正式配置和展示依照后续节点安排。
