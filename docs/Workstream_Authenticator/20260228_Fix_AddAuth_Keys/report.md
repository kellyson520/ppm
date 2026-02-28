# Task Report: Fix AddAuth Encryption Keys & Import/Export Dummy Placeholder
Date: 2026-02-28

## Issue 1: 加密密钥未就绪问题修复
- **原因分析**：在 `vault_screen.dart` 的 BottomNavigationBar 打开 `AddAuthScreen` 时，没有传递当前会话保管库的 `vaultService.sessionDek`, `sessionSearchKey` 和 `deviceId`，导致其值为 `null`。在保存凭证时触发了 `encryptionKeysNotReady` 异常。
- **解决方案**：为 `AddAuthScreen` 按需注入从 `widget.vaultService` 获取到的会话密钥。并在 `AuthenticatorScreen` 初始化处一并补全缺失参数（替换原有的安全占位 `null`）。

## Issue 2: 导入导出功能显示“正在开发”文案问题
- **原因分析**：这是由于用户运行了之前的项目版本或者在之前的版本中点击了带有 `_showComingSoon` 的选项。在近期的 `RefineUI_And_ImportExport` 工作流中，主设置页面的“导出备份”和“导入备份”已完整链接至 `_exportBackup` (提供安全的本地存储和系统 Share 功能) 及 `_importBackup` (从系统中读取无格式加密 JSON 并重新重建模型)，原有的 `comingSoon` 的 SnackBar 已被移除并重构完成。
- **解决方案**：代码已确认就绪，并提醒用户其对应版本编译结果应当获取最新构建 (`flutter build`)。

## 验证
通过 `flutter test test/widget_test.dart` 确认了基础挂接未发生崩溃。代码已经不再抛出该占位符。
