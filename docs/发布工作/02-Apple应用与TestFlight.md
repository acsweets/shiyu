# 02 Apple 应用与 TestFlight

目标是用 TestFlight 真实安装一次时余，并明确这条链接能发给谁。Apple Developer 中的标识和 App Store Connect 中的应用记录分别核对。

## 1. 建应用记录

- [ ] 登录 Apple Developer 和 App Store Connect，确认使用自己的开发团队，账号有创建应用权限，待签协议由账号持有人处理。
- [ ] 核对主应用标识 com.growthrecord.shiyu、组件标识 com.growthrecord.shiyu.widgets 和共享组 group.com.growthrecord.shiyu。主应用与扩展在同一团队且共享组配置一致。
- [ ] 在 App Store Connect 的「App」中新建 iOS 应用。建议显示名称「时余」，主语言简体中文，主 Bundle ID 选 com.growthrecord.shiyu，SKU 可填 SHIYU-IOS。名称与 SKU 提交前核对。
- [ ] 组件随主应用构建上传。应用记录选主 Bundle ID，组件 Bundle ID 用于独立签名。[Apple 创建应用指南](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app)

## 2. 上传第一版内测

- [ ] 从已验收的 commit 锁定版本号和 build number。当前工程基线是 0.1.0+1，重复上传前递增构建号，并检查 Runner 与 ShiyuWidgets 的版本值一致。
- [ ] 按 Apple 当期 SDK 要求选择 Xcode。用 Runner scheme 在 Xcode Archive，验证签名和嵌入扩展后上传。上传构建应适用于预定的测试范围。[Apple 构建要求](https://developer.apple.com/news/upcoming-requirements/) · [上传构建](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)
- [ ] 等待构建处理完成，在 TestFlight 补测试说明和后台要求的合规项。写清本轮要测的首页、小组件、金额遮蔽和反馈入口。
- [ ] 创建内部测试组并加入有该应用权限的测试账号。用 iPhone 从 TestFlight 安装，至少验证启动、添加组件和配置同步。记录实测构建号与日期。[Apple 内部测试指南](https://developer.apple.com/help/app-store-connect/test-a-beta-version/add-internal-testers)

## 3. 需要公开招募时准备外部测试

- [ ] 在后台新建外部测试组，添加对应构建并按要求送 TestFlight Beta App Review。测试说明写明怎么复现和提交反馈。
- [ ] 审核完成并允许公开招募后，再生成公开邀请。用一台非开发者账号的兼容设备打开、加入并安装，检查名额、邀请状态及构建有效期。
- [ ] 把经过验证的公开邀请登记到发布工作台。内部组或邮件邀请按授权名单单独发给测试者。[Apple 外部测试与公开链接](https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers)

## 4. 正式上架另开一轮

- [ ] 准备实际构建的商店截图、应用简介、支持网址、隐私政策、隐私申报、年龄分级和审核说明。根据候选包的真实数据行为填写。
- [ ] 验证真机升级与保留配置，再按发布范围提交正式审核。商店页实际可用后，登记对应地区链接并更新官网。
