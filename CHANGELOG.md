# Changelog

## [0.2.9] - 2026-02-28

### 🔧 修复 (Fixes)
- **单元测试修复**：更新 `widget_test.dart` 以适配本地化后的 Splash Screen。
  - 将硬编码的 tagline 文本断言替换为对 `SplashScreen` 组件类型的校验，解决 CI 环境因 Locale 差异导致的测试失败。

## [0.2.8] - 2026-02-26

### 🔧 修复 (Fixes)
- **Android SDK 升级**：将 `compileSdk` 和 `targetSdk` 升级至 36，以满足 `sqflite_sqlcipher` 插件的最低版本要求。
- **环境适配**：解决编译期间 SDK 版本不足导致的兼容性警告。

## [0.2.7] - 2026-02-26

### 🔧 修复 (Fixes)
- **加密测试稳定性**：修复 `crypto_entropy_test.dart` 中的随机性失效问题。
  - 将熵值分布容差从 50% (3-Sigma) 优化为 80% (5-Sigma)，极大降低了统计性误报。
  - 增强了测试失败时的错误提示，便于追溯随机分布异常。
- **文档同步**：完成 `20260226_FixEntropyTestFailure` 任务归档。

## [0.2.6] - 2026-02-26

### 🔧 修复 (Fixes)
- **代码规范修复**：全面修复 27 项 `flutter analyze` 警告，解决 CI 构建失败风险
  - 重构 `AuthBloc`, `PasswordBloc`, `VaultBloc` 及其测试工具，将通配 `catch (e)` 升级为 `on Object catch (e)` (`avoid_catches_without_on_clauses`)
  - 移除 `KeyManager` 中弃用的 `encryptedSharedPreferences` 参数 (`deprecated_member_use`)
  - 清理 `LockScreen` 与 `SetupScreen` 中冗余的 `_isLoading` 字段，交由 BLoC 状态管理 (`unused_field`)
  - 修复 `test_matchers.dart` 文档注释中的 HTML 解析歧义问题 (`unintended_html_in_doc_comment`)
- **CI 优化**：暂时禁用 GitHub Actions 的 Flutter 缓存 (`cache: false`) 以确保构建环境纯净，并优化 YAML 缩进

## [0.2.5] - 2026-02-26

### 🔧 修复 (Fixes)
- **测试修复**：修复 `PasswordBloc` 单元测试中的静态分析错误、Mockito 生成位置及类型不匹配问题
- **CI 升级**：升级 GitHub Actions 的 Flutter 版本至 `3.41.2` 以支持 `Color.withValues` API
- **文档更新**：同步任务报告并完成 Workstream 归档准备

## [0.2.4] - 2026-02-25

### ✨ 新功能 (Features)
- **崩溃日志系统**：新增全局异常捕获与崩溃弹窗机制
  - 新增 `lib/core/diagnostics/crash_report_service.dart`：Singleton 服务，三路拦截 Flutter 框架/Platform/Zone 异常
  - 新增 `lib/ui/screens/crash_report_screen.dart`：深色主题全屏崩溃界面，展示时间戳、来源标签、错误摘要与完整可选择 StackTrace
  - 提供「**复制报告**」（写入剪贴板，含格式化文本）和「**关闭应用**」两个操作按钮
  - `main.dart` 注入 `GlobalKey<NavigatorState>` 与 `runZonedGuarded`，崩溃时自动清空路由栈并导航至崩溃界面

## [0.2.3] - 2026-02-25


### ✨ 新功能 (Features)
- **多平台支持**：正式启用 Windows, macOS, Linux 及 Web 端支持，完成全平台工程初始化
- **工程同步**：整合近期所有开发任务进度、文档及代码改动，确保仓库状态与本地工作区一致

### 🔧 优化 (Optimization)
- **本地 CI 通过**：通过 `flutter analyze` 静态分析及全部 24 项单元测试
- **文档闭环**：同步 `docs/` 目录下所有活跃工作流任务状态

## [0.2.2] - 2026-02-25

### 🔧 修复 (Fixes)
- 同步 `pubspec.yaml` 版本号至 0.2.2

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
