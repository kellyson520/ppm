# Technical Specification - Fixed Export & Encryption

## 1. Encrypted Export Format

### 格式选择
为了保证安全性和兼容性，使用 AES-GCM 算法对导出的 JSON 字符串进行加密。加密密钥使用当前会话的 `_sessionDek` (Data Encryption Key)。

### 序列化结构
加密后的导出文件不再是简单的 JSON 数组，而是一个 base64 编码的 `EncryptedData` 序列化字符串。
`EncryptedData` 结构包含：
- `ciphertext`: 加密的 JSON 字节。
- `iv`: 随机生成的初始化向量。
- `authTag`: 认证标签 (AES-GCM 特性)。

`VaultService` 已有 `EncryptedData.serialize()` 方法，可以使用该方法生成最终输出。

## 2. VaultService 变更

### `exportVaultAsJson`
- 参数: `bool encrypted = true` (默认 true)
- 逻辑:
  1. 解密所有 `PasswordCard` 的 payload，构建 JSON。
  2. 如果 `encrypted` 为 true，则调用 `_cryptoService.encryptString(json, _sessionDek!)` 生成 `EncryptedData`。
  3. 调用 `encryptedData.serialize()` 返回最终 base64 字符串。

### `importVaultFromJson`
- 逻辑:
  1. 尝试将 `jsonString` 解析为 `EncryptedData` (通过反序列化 base64 → json → `EncryptedData`)。
  2. 如果是 `EncryptedData` 格式，则调用 `_cryptoService.decryptString(data, _sessionDek!)` 尝试解密。
  3. 如果解密成功或输入本身是大 JSON 数组，则解析为 `List<dynamic>`。
  4. 遍历列表调用 `createCard()`。

## 3. SettingsScreen 变更

### `_exportBackup` 逻辑优化
```dart
Future<void> _exportBackup() async {
  // 按照原有逻辑生成 jsonStr (现在是加密的 base64 字符串)
  final jsonStr = await widget.vaultService.exportVaultAsJson(encrypted: true);
  final bytes = utf8.encode(jsonStr);
  
  // file_picker.saveFile 会正确处理安卓系统写入
  final String? outputFile = await FilePicker.platform.saveFile(
    // ...
    bytes: Uint8List.fromList(bytes),
  );

  if (outputFile != null) {
      // 检查平台，非移动平台可能需要手动写入其真实路径
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
          final file = File(outputFile);
          if (!file.existsSync() || file.lengthSync() == 0) {
              await file.writeAsBytes(bytes);
          }
      }
      // 安卓平台上，outputFile 可能返回 /document/MuMuShared:... 这种 File API 不通的路径，
      // 但 file_picker 已内置了二进制字节写入底层 SAF 的逻辑，无需额外 Manual Write。
      _showSuccess(l10n.backupExported);
  }
}
```

## 4. 影响评估
- **安全性**: 导出文件内容在静止状态下受到主密码保护（通过 DEK 衍生）。
- **兼容性**: 完美支持老版本的 plain JSON 导入。
- **鲁棒性**: 解决 Android 平台下 `FilePicker` 路径权限冲突问题。
