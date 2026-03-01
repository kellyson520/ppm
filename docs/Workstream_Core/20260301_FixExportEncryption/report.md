# Task Report: Fix Export Encryption & PathNotFoundException

## Summary
解决了导出功能不加密的安全性隐患，并修复了在安卓（模拟器）平台上由于路径 API 限制导致的导出失败错误。

## Achievements

### 1. 加密导出功能 (Encrypted Export)
- **VaultService**: 
  - 默认情况下启用 AES-GCM 加密导出。
  - 导出的数据被包裹在 `EncryptedData` 结构中并序列化。
  - 使用当前会话的 DEK 进行加密，确保数据安全性。
- **Import Logic**:
  - 兼容旧版本的普通 JSON 数组导入。
  - 自动识别加密标记，并使用当前主密码派生的密钥进行解密。

### 2. 修复 PathNotFoundException
- **SettingsScreen**:
  - 移除了在 Android/iOS 平台上重复写入文件的逻辑。
  - 现代 `file_picker` (10.x+) 在 `saveFile` 中传入 `bytes` 时会自动处理写入，无需手动调用 `File(path).writeAsBytes()`。
  - 解决了由于 Android Content URI 导致的路径无法找到异常。

## Verification Results
- **Unit Tests**:
  - `test/unit/services/vault_export_import_test.dart` 已通过，覆盖了加密导出、明文导入和加密导入场景。
- **Architecture Compliance**:
  - 执行 `flutter analyze` 无警告，符合 DDD 分层和代码规范。

## File Changes
- `lib/services/vault_service.dart`: 核心导出/导入逻辑重构。
- `lib/ui/screens/settings_screen.dart`: 平台适配逻辑优化。
- `test/unit/services/vault_export_import_test.dart`: 新增集成测试。

## Quality Matrix
| Metric | Status |
| :--- | :--- |
| Encryption | AES-GCM (EncryptedData) |
| Compatibility | Forward & Backward compatible |
| Platform Stability | Android Fix Verified |
| Static Analysis | PASS (0 issues) |
