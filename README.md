# 有效期打印 iOS 重建版

这是根据 Android APK `com.fjxm.print` 重建的原生 iOS 工程，目标打印机为佳博 GP-M322。

## 已实现

- 恢复 APK 内置的 161 条产品和有效期模板
- 按岗位、类别浏览以及全局搜索
- 新增、编辑、删除模板，本地 JSON 持久化
- 冷藏、冷冻、常温及“当天废弃”规则
- 50 × 40 mm 标签预览
- 自动搜索并连接名称以 `_BLE` 结尾的 GP-M322
- 按原 APK 的 376 × 304 版式生成快速稀疏位图 TSPL 打印命令
- 打印、连接和主要菜单的按压与震动反馈

## 运行

1. 在安装了完整 Xcode 的 Mac 上打开 `YouXiaoQiPrint.xcodeproj`。
2. 在 Target → Signing & Capabilities 中选择自己的 Apple Developer Team。
3. 使用真机运行；iOS 模拟器不能测试蓝牙打印。
4. 打开 GP-M322；App 会自动搜索并连接名称以 `_BLE` 结尾的设备。
5. 确认打印机屏幕的指令集显示为 `T`（TSPL）。
6. 使用 50 × 40 mm 标签纸，间隙设置为 1 mm。

## 首次实机测试

打印前建议先用一条测试模板确认方向、黑度和纸张偏移。若不同批次 GP-M322 固件的标签原点不同，可在 `TSPLRenderer.swift` 中调整 `BITMAP 12,8` 的两个坐标。

该工程未包含 Apple 签名证书或描述文件，无法预先制作可安装到任意 iPhone 的 IPA。

## 编译验证

- Xcode 27 beta 4
- iPhone arm64 真机：编译、签名和安装成功
- GP-M322 BLE：自动连接和实际出纸验证完成
