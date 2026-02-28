# Context
修复添加验证器界面由于缺少密钥导致的 `加密密钥未就绪` 错误。

# Strategy
- 在 `vault_screen.dart` 的 `_navigateToAddAuth` 方法中补充传递 `widget.vaultService.sessionDek`, `sessionSearchKey` 和 `deviceId`。
- 在 `vault_screen.dart` 的 `AuthenticatorScreen` 构建中，补充传递 `dek`, `searchKey`, `deviceId`，替代占位用的 `null`。
- 确认导入导出功能已在上一任务中完成上线，不再显示“正在开发”文案（`comingSoon` 提示已被替换为真实的 `_exportBackup` 等）。

# Phased Checklist
- [x] Phase 1 (Plan): 创建任务清单与确认问题。
- [x] Phase 2 (Build): 编辑 `vault_screen.dart`，传入正确的加密密钥。
- [x] Phase 3 (Verify): 执行 `flutter test test/widget_test.dart` 确保核心能够通过测试，并确认没有静态语法报错。
- [x] Phase 4 (Report): 更新任务进度与编写报告。
