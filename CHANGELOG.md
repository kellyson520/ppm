# Changelog

## [0.2.1] - 2026-02-25

### 🔧 修复 (Fixes)
- **全面修复 `flutter analyze` 问题**：解决全部 53 项静态分析错误与警告
  - **API 适配**：批量将废弃的 `.withOpacity()` 替换为 `.withValues(alpha: ...)`，适配 Flutter 3.24+ 最新规范
  - **业务逻辑优化**：重构 `AuthService.getCard()`, 移除对 `StateError` 的捕获，提升代码健壮性并符合 `avoid_catching_errors` 准则
  - **性能优化**：补全缺失的 `const` 构造函数并移除冗余 `const` 声明
  - **代码清理**：移除 `authenticator_screen.dart` 等文件中的未使用 import

## [0.2.0] - 2026-02-25

### ✨ 新功能：Authenticator 扫码导入 (QR Code Scanning)
- **集成 `mobile_scanner` 引擎**：支持高性能相机流二维码实时识别与解析
- **新增 `QrScannerScreen` 扫描界面**：提供沉浸式全屏扫描体验，具备双角对齐、实时扫描线动画及环境光适配功能
- **重构 `AddAuthScreen` 业务流**：支持从 2FA 二维码一键导入并自动填充 otpauth 协议字段，简化用户操作
- **平台兼容性支持**：
  - Android 21+ 相机权限动态配置
  - iOS NSCameraUsageDescription 合规描述

### 🔧 优化
- 优化 `AddAuthScreen` 的 Tab 切换逻辑，从 2 Tab 扩展至 3 Tab

### 📦 依赖
- 新增 `mobile_scanner: ^5.1.1`

---

## [0.1.0] - 2026-02-25

### ✨ 重大重构：密码学模块化 (Crypto Modularization)
- **解耦单体 `CryptoService`** 为六层可插拔架构：接口层 (`crypto_core.dart`) → 实现层 (`providers/`) → 注册层 (`crypto_registry.dart`) → 策略层 (`crypto_policy.dart`) → 门面层 (`crypto_facade.dart`) → 兼容层 (`crypto_service.dart`)
  - 定义 `Kdf` / `AeadCipher` / `KeyWrap` / `Signer` / `Rng` 五大抽象接口
  - 实现 `AesGcmProvider` (AES-256-GCM AEAD)、`Pbkdf2Provider` (PBKDF2-HMAC-SHA256)、`HkdfProvider` (HKDF-SHA256) 三个默认 Provider
- **引入自描述密文格式 `CiphertextEnvelope`**：包含 `schemaVersion`、`suiteId`、`aeadId`、`kdfParams`、`nonce`、`ciphertext`、`authTag`、`aadMeta` 等字段，支持防剪切/重放攻击
- **实现防降级策略引擎 `CryptoPolicy`**：通过 `AllowedSuites` 集合 + `SecurityLevel` 最低安全等级门槛，拒绝解密不受信任的算法套件
- **向后兼容**：`CryptoService` 保留所有旧方法签名，`EncryptedData` ↔ `CiphertextEnvelope` 互转，`KeyManager` / `VaultService` / `EventStore` 无需改动

### 🔧 修复
- 修复 `flutter analyze` 报告的全部错误与警告（跨 18 个文件），包括：
  - 清理未使用 import (`add_password_screen.dart`, `vault_screen.dart` 等)
  - 移除不当 `const` 构造函数调用 (`lock_screen.dart`, `setup_screen.dart`)
  - 修复 `crdt_merger.dart` 中的类型推断与未使用变量
  - 修复 `webdav_sync.dart` 中的方法签名与 null-safety 问题
  - 修复 `settings_screen.dart` 中的枚举引用错误
- 修复 `analysis_options.yaml` 中的无效 lint 规则引用

### 📦 依赖
- 新增 `synchronized: ^3.1.0` 用于并发安全控制

### 📝 文档
- 新增 `docs/crypto_modularization/architecture.md` 架构文档
- 新增 `AGENTS.md` 项目智能体配置

## [0.0.1] - 2026-02-24

### Added
- 初始化项目架构。
- 集成 GitHub Actions CI 自动化流程。

### Fixed
- 修复 `intl` 与 `local_auth` 的依赖冲突 (降级 `intl` 至 `^0.18.1`)。
- 修复 CI 环境中 Flutter SDK 版本过低的问题 (升级至 `3.24.5`)。
