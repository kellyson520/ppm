# Fix Export Encryption & PathNotFoundException

## Context
1. 用户反馈导出的 JSON 文件未加密，存在安全隐患。
2. 在 MuMu 模拟器/Android 上导出成功后依然报错 `PathNotFoundException`，是因为代码尝试手动写入 File API 无法直接访问的路径 (Content URI)。

## Strategy
1. **Encryption Fix**: 
   - 升级 `VaultService.exportVaultAsJson()`，增加加密逻辑。
   - 默认使用 Session DEK 加密 JSON 字符串。
   - 升级 `importVaultFromJson()`，使其能够识别并解密加密的备份文件。
2. **Path Fix**:
   - 修改 `SettingsScreen._exportBackup()` 逻辑。
   - 在安卓/iOS平台上，既然 `file_picker` 已经接收了 `bytes` 并自动处理了写入，不再尝试手动通过 `File(path).writeAsBytes()` 再次写入。
   - 区分平台处理路径问题，确保桌面端功能不受影响。

## Phased Checklist
### Phase 1: Storage Layer (VaultService)
- [ ] 升级 `VaultService.exportVaultAsJson`，支持加密导出。
- [ ] 升级 `VaultService.importVaultFromJson`，支持解密导入。
- [ ] 编写/运行针对导出的单元测试。

### Phase 2: UI Layer (SettingsScreen)
- [ ] 修改 `_exportBackup` 逻辑，修复 Android 下的路径报错。
- [ ] 确保导出文件名及其扩展名逻辑正确。

### Phase 3: Verification & Report
- [ ] 验证加密后的备份文件内容。
- [ ] 验证导入功能（加密与非加密）。
- [ ] 生成任务报告。
