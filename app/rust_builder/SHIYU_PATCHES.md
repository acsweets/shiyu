# Rust 构建适配器

此目录由 flutter_rust_bridge_codegen 2.12.0 的 Cargokit 模板生成。Cargokit 上游许可保留于 `cargokit/LICENSE`；此构建插件仅供本仓库内部使用。

Rust 源码在 `../../core/crates/flutter_bridge/`。插件负责四平台编译和打包，不能复制 `shiyu_core` 的业务逻辑。

## 为当前项目保留的补丁

- `cargokit/build_tool/lib/src/builder.dart`：默认工具链固定 1.95.0，与 `core/rust-toolchain.toml` 对齐，不修改用户全局 stable。
- `cargokit/build_tool/lib/src/rustup.dart`：识别数字版本的已安装工具链，避免把已安装的 1.95.0 当成缺失并重复下载。
- `cargokit/gradle/plugin.gradle`：以注入的 ExecOperations 替代 Gradle 9 移除的 Project.exec；遵循 Flutter 请求的 ABI，不强制构建 x86。
- `cargokit/run_build_tool.cmd`：显式传递构建退出码，依赖解析/内核预编译失败立即返回，避免批处理结尾掩盖失败。
- `android/build.gradle`：使用宿主 AGP，SDK 36、NDK 28.2.13676358、最低 API 24。
- iOS/macOS podspec：最低版本分别为 15.0/12.0。

升级生成器时须保留或重新验证这些补丁。Cargokit 目录为第三方构建源码，保持上游代码布局与格式；手写应用代码仍遵守仓库规范。`linux/` 是模板附带文件，Linux 不在产品支持范围。
