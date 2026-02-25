# Authenticator 二维码扫描集成

## 1. 目标 (Objective)
为验证器模块添加二维码扫描功能，替代单一的手动输入/URI 粘贴，提升用户 UX。

## 2. 技术规格 (Technical Specs)
- **核心组件**: `mobile_scanner` (^5.1.1)
- **扫描逻辑**: 
  - 监听相机流并解析 Base64/文本
  - 自动识别 `otpauth://` 协议头
- **UI 设计**:
  - 全屏沉浸式扫描界面 (`QrScannerScreen`)
  - 自定义扫描线动画与四角遮罩
  - 触感反馈 (Haptic Feedback)
- **安全**:
  - 权限按需申请 (Android CAMERA / iOS NSCameraUsageDescription)
  - 扫描内容仅在内存中解析，不持久化原始 URI

## 3. 架构影响 (Architecture Impact)
- **UI 层**: `AddAuthScreen` 从 2 Tab 扩展为 3 Tab ("扫码导入")。
- **依赖库**: 引入相机与条码识别原生模块，增加了构建负荷。
