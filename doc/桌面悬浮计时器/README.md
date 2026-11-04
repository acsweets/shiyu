# 时余（工作名）

跨平台时间与收入感知工具：桌面悬浮窗为核心，配套移动端应用和手机小组件。

项目仍处于开发准备阶段。产品范围以 [`需求/MVP-冻结需求-1.0.md`](需求/MVP-冻结需求-1.0.md) 为准；如历史文档与冻结需求冲突，以冻结需求为准。

## 技术栈

- Flutter：桌面与移动端界面
- Rust：跨端共享计算核心
- flutter_rust_bridge：Flutter 与 Rust 桌面/应用层绑定
- UniFFI：原生 iOS/Android Widget 调用 Rust 核心

## 项目文档

- [项目基础信息](项目基础信息.md)
- [MVP 冻结需求 1.0](需求/MVP-冻结需求-1.0.md)
- [开发步骤、排期、测试与验证](需求/最终开发步骤-排期-测试验证.md)
- [技术方案](技术方案文档.md)
- [原型](原型/)

## 仓库与包标识

- 建议仓库名：`shiyu`
- GitHub 远程仓库：[acsweets/shiyu](https://github.com/acsweets/shiyu)（已创建；本地目录尚未初始化为独立仓库或配置远程）
- Apple Bundle ID：`com.growthrecord.shiyu`
- Android applicationId：`com.growthrecord.shiyu`
- Rust crate：`shiyu_core`
- Flutter package：`shiyu`

应用标识当前是初始化建议。确认发布主体及其域名后，应先核实 Bundle ID / applicationId 唯一性，再创建应用商店记录和签名配置。
