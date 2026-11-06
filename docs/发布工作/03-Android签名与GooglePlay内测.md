# 03 Android 签名与 Google Play 内测

目标是让测试者通过 Google Play 安装签名版时余并添加主屏幕小组件。当前 Android Release Gradle 配置引用 debug 签名，先补正式上传签名。[当前 Gradle 配置](../../app/android/app/build.gradle.kts)

## 1. 验真机与商店兼容性

- [ ] 从与 iOS 验收一致的候选 commit 开始。用 ARM64 Android 真机安装当前可用构建，验证应用重启后配置保留、小组件可添加、单项和组合布局可用。
- [ ] 测今日和本月已赚的应用内刷新、组件卡内刷新、金额隐藏与重启恢复。补一次断网启动和旧版本升级。
- [ ] 核对实际产物的 targetSdk。Gradle 取 Flutter 默认值，上传前检查实际 AAB 是否满足 Play Console 的当期要求。[Google Play 目标 API 要求](https://support.google.com/googleplay/android-developer/answer/11926878)
- [ ] 核对 Rust 和其余原生库的 16 KB 内存页兼容性，检查最终产物，并在对应系统环境实测启动。[Android 16 KB 适配指南](https://developer.android.com/guide/practices/page-sizes)

## 2. 创建应用和签名构建

- [ ] 登录 Play Console，确认账号类型、创建日期和待完成的身份或设备验证。
- [ ] 创建时余应用，包名用 com.growthrecord.shiyu，默认语言建议简体中文，应用类型选「应用」。联系人、定价和声明按实际发布安排填写。[Google Play 创建应用指南](https://support.google.com/googleplay/android-developer/answer/9859152)
- [ ] 配置 Play App Signing 和受控的上传密钥。把密钥、口令、备份和恢复信息放在私有存储。正式签名配置和构建脚本可审查，签名凭据留在仓库之外。
- [ ] 配好正式签名后，在 app 目录执行 flutter build appbundle --release。检查 AAB 的包名、versionCode、签名、最低系统和架构，保存产物与 commit 对应关系。[Android 应用签名指南](https://developer.android.com/studio/publish/app-signing)
- [ ] 若同时计划提供官网 APK，单独验签名和升级路径。Play 安装版与官网 APK 的签名是否一致会影响跨渠道升级，实测后再说明是否支持覆盖安装。

## 3. 发给测试者

- [ ] 将签名 AAB 上传到「内部测试」，配置测试名单和更新说明。用测试账号打开加入入口，确认 Play 安装的应用能启动、小组件可添加。
- [ ] 在另一台设备验证同一链接。记录所需账号、支持地区、构建号和测试步骤。将加入方式发给获准参与者。[Google Play 测试轨道指南](https://support.google.com/googleplay/android-developer/answer/9845334)
- [ ] 如果是 2023-11-13 之后创建的个人账号，在正式发布前安排封闭测试。至少 12 位测试者连续加入 14 天，满足要求后再申请正式发布权限。内部测试和封闭测试分别记结果。[Google Play 封闭测试要求](https://support.google.com/googleplay/android-developer/answer/14151465)

## 4. 正式商店入口

- [ ] 准备商店中英文文案、截图和隐私政策，按实际行为填数据安全、内容分级及目标受众。
- [ ] 按计划开放地区。等正式商品页可以用目标地区普通账号打开并安装，再把链接交给官网。
- [ ] 测试加入链接与正式商品页分开登记。官网当前仅支持正式 Google Play 商品页，内测链接接入见[官网更新](04-安装链接与官网更新.md)。
